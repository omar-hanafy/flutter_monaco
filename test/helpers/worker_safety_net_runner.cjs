// Executes the generated page's worker safety net in a Node `vm` context
// that stands in for a browser page, and reports what Monaco would observe.
//
// Usage: node worker_safety_net_runner.cjs <script.js> <scenario.json>
//
// Scenario fields:
//   protocol    'file:' | 'https:'     page location protocol
//   href        page URL (document.baseURI)
//   vsPath      window.__FM_PAGE.vsPath
//   worker      'loads' | 'fails' | 'silent' | 'throws'
//               what a blob: worker does when it runs importScripts
//   requestEarly  call getWorker before the probe can answer
//
// Prints JSON: { early, mode, detail, results, imported, warnings, workers,
//                descriptor, sameObject }.
'use strict';
const fs = require('fs');
const vm = require('vm');

const script = fs.readFileSync(process.argv[2], 'utf8');
const scenario = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));

const warnings = [];
const imported = [];
const blobs = new Map();
let blobSeq = 0;
let workers = 0;

class FakeBlob {
  constructor(parts) {
    this.text = parts.join('');
  }
}

class FakeWorker {
  constructor(url) {
    workers++;
    if (scenario.worker === 'throws') throw new Error('SecurityError: worker refused');
    this.onmessage = null;
    this.onerror = null;
    const source = blobs.get(url);
    if (scenario.worker === 'silent') return;
    // Runs the blob's source the way a dedicated worker would.
    setTimeout(() => {
      const scope = {
        importScripts: (u) => {
          imported.push(u);
          if (scenario.worker === 'fails') {
            const error = new Error(`Failed to execute 'importScripts': ${u} failed to load.`);
            error.name = 'NetworkError';
            throw error;
          }
        },
        postMessage: (data) => setTimeout(() => this.onmessage && this.onmessage({ data })),
      };
      vm.runInNewContext(source, scope);
    });
  }
  terminate() {}
}

const sandbox = {
  console: {
    log() {},
    error() {},
    warn: (...args) => warnings.push(args.join(' ')),
  },
  setTimeout,
  clearTimeout,
  location: { protocol: scenario.protocol, href: scenario.href },
  document: { baseURI: scenario.href },
  Blob: FakeBlob,
  Worker: FakeWorker,
  JSON,
  Error,
  Object,
  String,
};
sandbox.URL = class extends URL {
  static createObjectURL(blob) {
    const id = `blob:fake/${++blobSeq}`;
    blobs.set(id, blob.text);
    return id;
  }
  static revokeObjectURL(id) {
    blobs.delete(id);
  }
};
sandbox.window = sandbox;
sandbox.self = sandbox;
sandbox.__FM_PAGE = { vsPath: scenario.vsPath };
vm.createContext(sandbox);
vm.runInContext(script, sandbox);

// What editor.main.js does: assign a fresh environment with a getWorker.
const environment = {
  getWorker: (workerId, label) => `real worker for ${label}`,
};
sandbox.self.MonacoEnvironment = environment;

const request = (label) => {
  try {
    return { value: sandbox.self.MonacoEnvironment.getWorker('workerMain.js', label) };
  } catch (error) {
    return { threw: { name: error.name, message: error.message } };
  }
};

const early = scenario.requestEarly ? request('editorWorkerService') : null;

setTimeout(() => {
  const descriptor = Object.getOwnPropertyDescriptor(sandbox, 'MonacoEnvironment');
  const status = sandbox.__FM_WORKERS || null;
  const results = {};
  for (const label of ['editorWorkerService', 'json', 'css', 'html', 'typescript', 'javascript']) {
    results[label] = request(label);
  }
  // A second request for a refused label must not warn again.
  request('json');
  // Synchronous: process.exit below must not truncate a piped stdout.
  fs.writeSync(
    1,
    JSON.stringify({
      early,
      mode: status && status.mode,
      detail: status && status.detail,
      results,
      imported,
      warnings,
      workers,
      descriptor: descriptor ? (descriptor.get ? 'accessor' : 'data') : 'none',
      sameObject: sandbox.self.MonacoEnvironment === environment,
    }),
  );
  // The probe's own timeout may still be pending (the 'silent' scenario).
  process.exit(0);
}, 50);
