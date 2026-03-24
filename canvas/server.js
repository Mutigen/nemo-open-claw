const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const HOST = '127.0.0.1';
const PORT = 8081;
const LOCAL_OLLAMA_HOST = '127.0.0.1';
const LOCAL_OLLAMA_PORT = 11434;
const CLOUD_OLLAMA_HOST = 'ollama.com';
const CLOUD_OLLAMA_PORT = 443;
const OPENCLAW_PS1 = process.env.OPENCLAW_PS1 || 'C:\\Users\\levan\\AppData\\Roaming\\npm\\openclaw.ps1';

const CLOUD_PROVIDER_ID = 'ollama-cloud';
const CLOUD_PROFILE_ID = 'ollama-cloud:manual';
const CLOUD_MODEL_ID = 'qwen3-coder:480b';

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 1_000_000) {
        reject(new Error('Request body too large'));
      }
    });
    req.on('end', () => {
      if (!raw.trim()) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (error) {
        reject(new Error(`Invalid JSON: ${error.message}`));
      }
    });
    req.on('error', reject);
  });
}

function runCommand(command, args = [], options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      shell: false,
      windowsHide: true,
      ...options,
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) {
        resolve({ stdout, stderr, code });
      } else {
        reject(new Error((stderr || stdout || `exit ${code}`).trim()));
      }
    });
  });
}

function runOpenclaw(args = [], stdinText = null) {
  return new Promise((resolve, reject) => {
    const child = spawn('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      OPENCLAW_PS1,
      ...args,
    ], {
      shell: false,
      windowsHide: true,
      env: process.env,
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    child.on('error', reject);

    if (stdinText !== null) {
      child.stdin.write(String(stdinText));
      if (!String(stdinText).endsWith('\n')) child.stdin.write('\n');
    }
    child.stdin.end();

    child.on('close', (code) => {
      if (code === 0) {
        resolve({ stdout, stderr, code });
      } else {
        reject(new Error((stderr || stdout || `exit ${code}`).trim()));
      }
    });
  });
}

async function ensureCloudToken(cloudApiKey) {
  if (!cloudApiKey || !String(cloudApiKey).trim()) {
    throw new Error('Cloud Key fehlt.');
  }

  await runOpenclaw([
    'models',
    'auth',
    'paste-token',
    '--provider',
    CLOUD_PROVIDER_ID,
    '--profile-id',
    CLOUD_PROFILE_ID,
  ], String(cloudApiKey));
}

async function setPrimaryModel(primaryModel) {
  await runOpenclaw(['config', 'set', 'agents.defaults.model.primary', primaryModel]);
}

async function runOpenclawTurn({ message, sessionId }) {
  const { stdout } = await runOpenclaw([
    'agent',
    '--agent',
    'main',
    '--local',
    '--session-id',
    sessionId,
    '--message',
    message,
    '--json',
  ]);

  const firstBrace = stdout.indexOf('{');
  if (firstBrace < 0) {
    throw new Error(`OpenClaw output parse error: ${stdout.trim()}`);
  }
  const jsonPart = stdout.slice(firstBrace);
  const parsed = JSON.parse(jsonPart);
  const text = parsed?.payloads?.[0]?.text ?? '';
  if (!text) {
    throw new Error('OpenClaw lieferte keine Antwort.');
  }
  return text;
}

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(payload));
}

function sendFile(res, filePath, contentType) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end(`Datei konnte nicht geladen werden: ${err.message}`);
      return;
    }

    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

function proxyRequest(req, res, target) {
  const sourcePrefix = target.prefix;
  const upstreamPath = req.url.replace(sourcePrefix, '/v1/');
  const requestModule = target.protocol === 'https' ? https : http;
  const incomingHeaders = { ...req.headers };

  const cloudApiKey = incomingHeaders['x-ollama-api-key'];
  delete incomingHeaders['x-ollama-api-key'];

  if (target.kind === 'cloud') {
    if (!cloudApiKey || !String(cloudApiKey).trim()) {
      res.writeHead(401, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ error: 'Cloud Key fehlt (x-ollama-api-key).' }));
      return;
    }
    incomingHeaders.authorization = `Bearer ${String(cloudApiKey).trim()}`;
  }

  const options = {
    host: target.host,
    port: target.port,
    path: upstreamPath,
    method: req.method,
    headers: {
      ...incomingHeaders,
      host: target.host,
    },
  };

  const upstream = requestModule.request(options, (upstreamRes) => {
    const headers = { ...upstreamRes.headers };
    delete headers['content-security-policy'];
    res.writeHead(upstreamRes.statusCode || 502, headers);
    upstreamRes.pipe(res);
  });

  upstream.on('error', (error) => {
    res.writeHead(502, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ error: `Upstream nicht erreichbar (${target.kind}): ${error.message}` }));
  });

  req.pipe(upstream);
}

async function handleOpenclawModels(req, res) {
  const url = new URL(req.url, `http://${HOST}:${PORT}`);
  const mode = url.searchParams.get('mode') || 'local';

  if (mode === 'cloud') {
    sendJson(res, 200, {
      object: 'list',
      data: [{ id: CLOUD_MODEL_ID, object: 'model', owned_by: 'ollama-cloud' }],
    });
    return;
  }

  sendJson(res, 200, {
    object: 'list',
    data: [
      { id: 'qwen2.5:3b', object: 'model', owned_by: 'ollama-local' },
      { id: 'qwen2.5:7b', object: 'model', owned_by: 'ollama-local' },
    ],
  });
}

async function handleOpenclawChat(req, res) {
  try {
    const body = await readJsonBody(req);
    const mode = body.mode === 'cloud' ? 'cloud' : 'local';
    const model = typeof body.model === 'string' ? body.model : '';
    const sessionId = typeof body.sessionId === 'string' && body.sessionId.trim()
      ? body.sessionId.trim()
      : 'ui-session';
    const messages = Array.isArray(body.messages) ? body.messages : [];
    const lastUser = [...messages].reverse().find((m) => m && m.role === 'user' && typeof m.content === 'string');

    if (!lastUser?.content?.trim()) {
      sendJson(res, 400, { error: 'Keine User-Nachricht gefunden.' });
      return;
    }

    if (mode === 'cloud') {
      const cloudApiKey = req.headers['x-ollama-api-key'];
      await ensureCloudToken(cloudApiKey);
      await setPrimaryModel(`ollama-cloud/${model || CLOUD_MODEL_ID}`);
    } else {
      await setPrimaryModel(`ollama-local/${model || 'qwen2.5:3b'}`);
    }

    const answer = await runOpenclawTurn({
      message: lastUser.content,
      sessionId,
    });

    sendJson(res, 200, {
      choices: [
        {
          message: { role: 'assistant', content: answer },
        },
      ],
    });
  } catch (error) {
    sendJson(res, 500, { error: error.message || String(error) });
  }
}

const server = http.createServer((req, res) => {
  if (!req.url) {
    res.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Ungültige Anfrage');
    return;
  }

  if (req.url === '/' || req.url === '/index.html') {
    sendFile(res, path.join(__dirname, 'index.html'), 'text/html; charset=utf-8');
    return;
  }

  if (req.method === 'GET' && req.url.startsWith('/openclaw/models')) {
    handleOpenclawModels(req, res);
    return;
  }

  if (req.method === 'POST' && req.url === '/openclaw/chat') {
    handleOpenclawChat(req, res);
    return;
  }

  if (req.url.startsWith('/proxy/local/v1/')) {
    proxyRequest(req, res, {
      kind: 'local',
      protocol: 'http',
      host: LOCAL_OLLAMA_HOST,
      port: LOCAL_OLLAMA_PORT,
      prefix: '/proxy/local/v1/'
    });
    return;
  }

  if (req.url.startsWith('/proxy/cloud/v1/')) {
    proxyRequest(req, res, {
      kind: 'cloud',
      protocol: 'https',
      host: CLOUD_OLLAMA_HOST,
      port: CLOUD_OLLAMA_PORT,
      prefix: '/proxy/cloud/v1/'
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('Nicht gefunden');
});

server.listen(PORT, HOST, () => {
  console.log(`NemoClaw UI läuft auf http://${HOST}:${PORT}`);
  console.log(`Proxy local: http://${LOCAL_OLLAMA_HOST}:${LOCAL_OLLAMA_PORT}`);
  console.log(`Proxy cloud: https://${CLOUD_OLLAMA_HOST}/v1`);
  console.log('OpenClaw backend: openclaw agent --local');
});