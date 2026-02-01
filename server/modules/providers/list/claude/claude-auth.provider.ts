import { readFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';

import spawn from 'cross-spawn';

import type { IProviderAuth } from '@/shared/interfaces.js';
import type { ProviderAuthStatus } from '@/shared/types.js';
import { readObjectRecord, readOptionalString } from '@/shared/utils.js';

type ClaudeCredentialsStatus = {
  authenticated: boolean;
  email: string | null;
  method: string | null;
  error?: string;
};

export class ClaudeProviderAuth implements IProviderAuth {
  /**
   * Checks whether the Claude Code CLI is available on this host.
   */
  private checkInstalled(): boolean {
      const cliPath = process.env.CLAUDE_CLI_PATH || 'claude';
      try {
        spawn.sync(cliPath, ['--version'], { stdio: 'ignore', timeout: 5000 });
        return true;
      } catch {
        return false;
      }
  }

  /**
   * Returns Claude installation and credential status using Claude Code's auth priority.
   */
  async getStatus(): Promise<ProviderAuthStatus> {
    const installed = this.checkInstalled();

    if (!installed) {
      return {
        installed,
        provider: 'claude',
        authenticated: false,
        email: null,
        method: null,
        error: 'Claude Code CLI is not installed',
      };
    }

    const credentials = await this.checkCredentials();

    return {
      installed,
      provider: 'claude',
      authenticated: credentials.authenticated,
      email: credentials.authenticated ? credentials.email || 'Authenticated' : credentials.email,
      method: credentials.method,
      error: credentials.authenticated ? undefined : credentials.error || 'Not authenticated',
    };
  }

  /**
   * Reads Claude settings env values that the CLI can use even when the server process env is empty.
   */
  private async loadSettingsEnv(): Promise<Record<string, unknown>> {
    try {
      const settingsPath = path.join(os.homedir(), '.claude', 'settings.json');
      const content = await readFile(settingsPath, 'utf8');
      const settings = readObjectRecord(JSON.parse(content));
      return readObjectRecord(settings?.env) ?? {};
    } catch {
      return {};
    }
  }

  /**
   * Asks the Claude CLI directly via `claude auth status --json`. This is the
   * source of truth — it correctly handles the macOS Keychain (where the CLI
   * stores OAuth tokens on Mac instead of ~/.claude/.credentials.json),
   * Bedrock/Vertex providers, and any future auth scheme the CLI adds.
   * Returns null if the CLI is too old to support the command or the call fails.
   */
  private askCliAuthStatus(): ClaudeCredentialsStatus | null {
    const cliPath = process.env.CLAUDE_CLI_PATH || 'claude';
    try {
      const result = spawn.sync(cliPath, ['auth', 'status', '--json'], {
        timeout: 5000,
        encoding: 'utf8',
        shell: true,
      });
      if (result.status !== 0 || typeof result.stdout !== 'string' || !result.stdout.trim()) {
        return null;
      }

      const parsed = readObjectRecord(JSON.parse(result.stdout));
      if (!parsed) {
        return null;
      }

      const loggedIn = parsed.loggedIn === true;
      const email = readOptionalString(parsed.email) ?? null;
      const apiProvider = readOptionalString(parsed.apiProvider);
      const authMethod = readOptionalString(parsed.authMethod);

      let method: string | null = null;
      if (apiProvider && apiProvider !== 'firstParty') {
        method = apiProvider;
      } else if (authMethod === 'api_key') {
        method = 'api_key';
      } else if (authMethod) {
        method = 'credentials_file';
      }

      if (loggedIn) {
        return { authenticated: true, email: email ?? 'Authenticated', method };
      }

      return { authenticated: false, email, method, error: 'Not authenticated' };
    } catch {
      return null;
    }
  }

  /**
   * Checks Claude credentials in the same priority order used by Claude Code.
   */
  private async checkCredentials(): Promise<ClaudeCredentialsStatus> {
    // Priority 0: AWS Bedrock — no OAuth/credentials file required.
    // The Claude Code CLI delegates auth to AWS when CLAUDE_CODE_USE_BEDROCK is set.
    if (process.env.CLAUDE_CODE_USE_BEDROCK === '1' || process.env.CLAUDE_CODE_USE_BEDROCK === 'true') {
      return { authenticated: true, email: 'AWS Bedrock', method: 'bedrock' };
    }

    // Priority 1: ask the CLI itself. This handles macOS Keychain storage
    // and stays correct as Anthropic evolves their auth flow.
    const cliStatus = this.askCliAuthStatus();
    if (cliStatus) {
      return cliStatus;
    }

    if (process.env.ANTHROPIC_API_KEY?.trim()) {
      return { authenticated: true, email: 'API Key Auth', method: 'api_key' };
    }

    const settingsEnv = await this.loadSettingsEnv();
    if (readOptionalString(settingsEnv.ANTHROPIC_API_KEY)) {
      return { authenticated: true, email: 'API Key Auth', method: 'api_key' };
    }

    if (readOptionalString(settingsEnv.ANTHROPIC_AUTH_TOKEN)) {
      return { authenticated: true, email: 'Configured via settings.json', method: 'api_key' };
    }

    try {
      const credPath = path.join(os.homedir(), '.claude', '.credentials.json');
      const content = await readFile(credPath, 'utf8');
      const creds = readObjectRecord(JSON.parse(content)) ?? {};
      const oauth = readObjectRecord(creds.claudeAiOauth);
      const accessToken = readOptionalString(oauth?.accessToken);

      if (accessToken) {
        const expiresAt = typeof oauth?.expiresAt === 'number' ? oauth.expiresAt : undefined;
        const email = readOptionalString(creds.email) ?? readOptionalString(creds.user) ?? null;
        if (!expiresAt || Date.now() < expiresAt) {
          return {
            authenticated: true,
            email,
            method: 'credentials_file',
          };
        }

        return {
          authenticated: false,
          email,
          method: 'credentials_file',
          error: 'OAuth token has expired. Please re-authenticate with claude login',
        };
      }

      return { authenticated: false, email: null, method: null };
    } catch {
      return { authenticated: false, email: null, method: null };
    }
  }
}
