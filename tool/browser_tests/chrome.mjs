// Minimal headless Chrome driver over the DevTools protocol, with no npm
// dependencies (Node's built-in WebSocket client is enough).
//
// The browser regression tests use it to boot the REAL bundled Monaco and
// the REAL bridge in a Chromium engine - the engine behind WebView2 - and
// observe what only a browser can show: whether Monaco's web workers start,
// whether the diff is computed, whether language diagnostics arrive.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const CONTENT_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.ttf': 'font/ttf',
  '.svg': 'image/svg+xml',
};

/** Default Chrome locations, overridable with FLUTTER_MONACO_CHROME. */
const DEFAULT_BINARIES = {
  darwin: ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'],
  linux: [
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
  ],
  win32: [
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  ],
};

/** Resolves the Chrome binary, or throws naming what was tried. */
export function findChrome() {
  const fromEnv = process.env.FLUTTER_MONACO_CHROME || process.env.CHROME_BIN;
  if (fromEnv) {
    if (!fs.existsSync(fromEnv)) {
      throw new Error(`Chrome binary from the environment does not exist: ${fromEnv}`);
    }
    return fromEnv;
  }
  const candidates = DEFAULT_BINARIES[process.platform] || [];
  const found = candidates.find((candidate) => fs.existsSync(candidate));
  if (!found) {
    throw new Error(
      'Google Chrome was not found. Set FLUTTER_MONACO_CHROME to the browser ' +
        `binary (tried: ${candidates.join(', ') || 'no defaults for ' + process.platform}).`,
    );
  }
  return found;
}

/**
 * Launches headless Chrome on a throwaway profile and connects to its
 * browser-level DevTools endpoint.
 *
 * @param {{ extraArgs?: string[], launchTimeoutMs?: number }} [options]
 */
export async function launchChrome(options = {}) {
  const binary = findChrome();
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'fm-chrome-profile-'));
  const args = [
    '--headless=new',
    '--remote-debugging-port=0',
    `--user-data-dir=${profile}`,
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-background-networking',
    '--disable-component-update',
    '--disable-default-apps',
    '--disable-extensions',
    '--disable-sync',
    '--metrics-recording-only',
    '--password-store=basic',
    '--use-mock-keychain',
    // Hosted CI runners (Ubuntu 23.10+) restrict the unprivileged user
    // namespaces Chrome's sandbox needs.
    ...(process.platform === 'linux' ? ['--no-sandbox'] : []),
    ...(options.extraArgs || []),
    'about:blank',
  ];
  const child = spawn(binary, args, { stdio: ['ignore', 'ignore', 'pipe'] });

  let stderr = '';
  const wsUrl = await new Promise((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new Error(`Chrome did not expose DevTools in time.\n${stderr}`)),
      options.launchTimeoutMs || 30000,
    );
    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
      const match = stderr.match(/DevTools listening on (ws:\/\/\S+)/);
      if (match) {
        clearTimeout(timer);
        resolve(match[1]);
      }
    });
    child.on('exit', (code) => {
      clearTimeout(timer);
      reject(new Error(`Chrome exited early (code ${code}).\n${stderr}`));
    });
  });

  const connection = await CdpConnection.open(wsUrl);
  return new Chrome(child, profile, connection);
}

class CdpConnection {
  static async open(url) {
    const socket = new WebSocket(url);
    await new Promise((resolve, reject) => {
      socket.addEventListener('open', resolve, { once: true });
      socket.addEventListener('error', () => reject(new Error(`Cannot connect to ${url}`)), {
        once: true,
      });
    });
    return new CdpConnection(socket);
  }

  constructor(socket) {
    this.socket = socket;
    this.nextId = 0;
    this.pending = new Map();
    this.listeners = new Set();
    socket.addEventListener('message', (event) => {
      const message = JSON.parse(event.data);
      if (message.id !== undefined) {
        const waiter = this.pending.get(message.id);
        if (!waiter) return;
        this.pending.delete(message.id);
        if (message.error) {
          waiter.reject(new Error(`${waiter.method}: ${message.error.message}`));
        } else {
          waiter.resolve(message.result);
        }
        return;
      }
      for (const listener of this.listeners) listener(message);
    });
    socket.addEventListener('close', () => {
      for (const waiter of this.pending.values()) {
        waiter.reject(new Error(`DevTools connection closed during ${waiter.method}`));
      }
      this.pending.clear();
    });
  }

  send(method, params = {}, sessionId) {
    const id = ++this.nextId;
    const message = { id, method, params };
    if (sessionId) message.sessionId = sessionId;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject, method });
      this.socket.send(JSON.stringify(message));
    });
  }

  close() {
    this.socket.close();
  }
}

class Chrome {
  constructor(child, profile, connection) {
    this.child = child;
    this.profile = profile;
    this.connection = connection;
  }

  /**
   * Opens a fresh tab with [initScript] evaluated before any page script,
   * and returns a [Page] attached to it.
   */
  async newPage({ initScript } = {}) {
    const { targetId } = await this.connection.send('Target.createTarget', { url: 'about:blank' });
    const { sessionId } = await this.connection.send('Target.attachToTarget', {
      targetId,
      flatten: true,
    });
    const page = new Page(this.connection, sessionId, targetId);
    await page.send('Runtime.enable');
    await page.send('Page.enable');
    if (initScript) {
      await page.send('Page.addScriptToEvaluateOnNewDocument', { source: initScript });
    }
    return page;
  }

  /**
   * Serves `https://<hostName>/<path>` from `<folder>/<path>` for every tab
   * and worker of this browser, the way WebView2's
   * SetVirtualHostNameToFolderMapping does: the query string is ignored and
   * a missing file is a 404. Returns the list of request URLs it served,
   * which grows as the page loads.
   */
  async mapVirtualHost(hostName, folder) {
    const root = path.resolve(folder);
    const served = [];
    this.connection.listeners.add(async (message) => {
      if (message.method !== 'Fetch.requestPaused') return;
      const { requestId, request } = message.params;
      const url = new URL(request.url);
      if (url.hostname !== hostName) return;
      served.push(request.url);
      const file = path.resolve(root, '.' + decodeURIComponent(url.pathname));
      let body = null;
      if (file.startsWith(root + path.sep)) {
        try {
          body = fs.readFileSync(file);
        } catch (_) {
          // 404 below.
        }
      }
      await this.connection.send(
        'Fetch.fulfillRequest',
        {
          requestId,
          responseCode: body ? 200 : 404,
          responseHeaders: [
            { name: 'Content-Type', value: CONTENT_TYPES[path.extname(file)] || 'application/octet-stream' },
          ],
          body: (body || Buffer.alloc(0)).toString('base64'),
        },
        message.sessionId,
      );
    });
    // Enabled on the browser target, interception covers every tab and every
    // dedicated worker, so a worker's importScripts is served here too.
    await this.connection.send('Fetch.enable', {
      patterns: [{ urlPattern: `https://${hostName}/*` }],
    });
    return served;
  }

  async close() {
    try {
      await this.connection.send('Browser.close');
    } catch (_) {
      // Already gone.
    }
    this.connection.close();
    await new Promise((resolve) => {
      if (this.child.exitCode !== null) return resolve();
      const timer = setTimeout(() => {
        this.child.kill('SIGKILL');
        resolve();
      }, 5000);
      this.child.once('exit', () => {
        clearTimeout(timer);
        resolve();
      });
    });
    fs.rmSync(this.profile, { recursive: true, force: true });
  }
}

class Page {
  constructor(connection, sessionId, targetId) {
    this.connection = connection;
    this.sessionId = sessionId;
    this.targetId = targetId;
    /** Uncaught page exceptions, as DevTools reports them. */
    this.exceptions = [];
    /** Console output, `level: text`. */
    this.console = [];
    this.handlers = new Map();
    connection.listeners.add((message) => {
      if (message.sessionId !== sessionId) return;
      if (message.method === 'Runtime.exceptionThrown') {
        const details = message.params.exceptionDetails;
        this.exceptions.push(
          (details.exception && details.exception.description) || details.text,
        );
      } else if (message.method === 'Runtime.consoleAPICalled') {
        const text = message.params.args
          .map((arg) => (arg.value !== undefined ? String(arg.value) : arg.description || ''))
          .join(' ');
        this.console.push(`${message.params.type}: ${text}`);
      }
      const handler = this.handlers.get(message.method);
      if (handler) handler(message.params);
    });
  }

  send(method, params = {}) {
    return this.connection.send(method, params, this.sessionId);
  }

  /** Registers [handler] for one DevTools event of this tab. */
  on(method, handler) {
    this.handlers.set(method, handler);
  }

  async navigate(url) {
    const result = await this.send('Page.navigate', { url });
    if (result.errorText) {
      throw new Error(`Navigation to ${url} failed: ${result.errorText}`);
    }
  }

  /** Evaluates [expression] in the page, awaiting a returned promise. */
  async evaluate(expression) {
    const { result, exceptionDetails } = await this.send('Runtime.evaluate', {
      expression,
      awaitPromise: true,
      returnByValue: true,
    });
    if (exceptionDetails) {
      throw new Error(
        `Page evaluation failed: ${
          (exceptionDetails.exception && exceptionDetails.exception.description) ||
          exceptionDetails.text
        }`,
      );
    }
    return result.value;
  }

  /**
   * Polls [expression] until it returns a truthy value, returning that value,
   * or throws after [timeoutMs] naming [what].
   */
  async waitFor(expression, { timeoutMs = 20000, intervalMs = 100, what = expression } = {}) {
    const deadline = Date.now() + timeoutMs;
    for (;;) {
      const value = await this.evaluate(expression);
      if (value) return value;
      if (Date.now() > deadline) {
        throw new Error(
          `Timed out after ${timeoutMs}ms waiting for ${what}.\n` +
            `Console:\n  ${this.console.join('\n  ')}\n` +
            `Exceptions:\n  ${this.exceptions.join('\n  ')}`,
        );
      }
      await new Promise((resolve) => setTimeout(resolve, intervalMs));
    }
  }

  async close() {
    await this.connection.send('Target.closeTarget', { targetId: this.targetId });
  }
}
