#!/usr/bin/env node
'use strict';

/*
 * Pruebas de los dos guards.
 *
 * Les mete el mismo JSON que les manda Claude Code por stdin y comprueba el
 * codigo de salida: 2 bloquea, 0 deja pasar.
 *
 * Buena parte de los casos comprueban lo que los guards NO deben bloquear. Un
 * guard que molesta acaba desactivado, y entonces no protege nada.
 *
 *   node hooks/guards.test.js
 */

const { spawnSync, execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

let fallos = 0;

function correr(hook, command, cwd) {
  const payload = {
    hook_event_name: 'PreToolUse',
    tool_name: 'Bash',
    tool_input: { command: command },
  };
  if (cwd) payload.cwd = cwd;
  return correrCrudo(hook, JSON.stringify(payload));
}

function correrCrudo(hook, entrada) {
  const r = spawnSync(process.execPath, [path.join(__dirname, hook)], {
    input: entrada,
    encoding: 'utf8',
  });
  return { code: r.status, stderr: r.stderr || '' };
}

function comprobar(hook, command, esperado, cwd, nota) {
  const { code } = correr(hook, command, cwd);
  const etiqueta = esperado === 2 ? 'BLOQUEA' : 'permite';
  const corto = command.length > 56 ? command.slice(0, 53) + '...' : command;
  if (code === esperado) {
    console.log('  PASS  ' + etiqueta.padEnd(7) + ' ' + corto);
  } else {
    console.log(
      '  FAIL  ' + etiqueta.padEnd(7) + ' ' + corto +
      '  (esperaba ' + esperado + ', dio ' + code + ')' + (nota ? ' ' + nota : '')
    );
    fallos++;
  }
}

function afirmar(cond, mensaje) {
  if (cond) console.log('  PASS  ' + mensaje);
  else { console.log('  FAIL  ' + mensaje); fallos++; }
}

// ---------------------------------------------------------------------------
const GIT = 'guard-git-destructivo.js';

console.log('=== guard-git-destructivo: debe BLOQUEAR ===');
comprobar(GIT, 'git push --force origin main', 2);
comprobar(GIT, 'git push -f', 2);
comprobar(GIT, 'git reset --hard HEAD~1', 2);
comprobar(GIT, 'git clean -fd', 2);
comprobar(GIT, 'git clean -f', 2);
comprobar(GIT, 'git branch -D feature/algo', 2);
comprobar(GIT, 'git status && git push --force', 2, null, 'encadenado');
comprobar(GIT, 'cd /tmp; git reset --hard', 2, null, 'encadenado con ;');

console.log('\n=== guard-git-destructivo: NO debe tocar ===');
comprobar(GIT, 'git push origin main', 0);
comprobar(GIT, 'git push --force-with-lease', 0, null, 'la variante segura');
comprobar(GIT, 'git status', 0);
comprobar(GIT, 'git reset HEAD~1', 0, null, 'reset soft');
comprobar(GIT, 'git clean -n', 0, null, 'dry run');
comprobar(GIT, 'git branch -d feature/algo', 0, null, 'minuscula: -d falla si hay huerfanos');
comprobar(GIT, 'npm run build -- -f', 0, null, 'tiene -f pero no es git push');
comprobar(GIT, 'git log --oneline', 0);

// ---------------------------------------------------------------------------
const SEC = 'guard-secretos.js';

console.log('\n=== guard-secretos: archivos de credenciales ===');
comprobar(SEC, 'git add .env', 2);
comprobar(SEC, 'git add config/.env.production', 2);
comprobar(SEC, 'git add id_rsa', 2);
comprobar(SEC, 'git add certs/server.pem', 2);
comprobar(SEC, 'git add credentials.json', 2);
comprobar(SEC, 'git add serviceAccountKey.json', 2);
comprobar(SEC, 'git commit -m "wip" .env.local', 2);

console.log('\n=== guard-secretos: plantillas SI se commitean ===');
comprobar(SEC, 'git add .env.example', 0);
comprobar(SEC, 'git add .env.template', 0);
comprobar(SEC, 'git add mcp/mcp.json.ejemplo', 0, null, 'plantilla de este repo');

console.log('\n=== guard-secretos: secretos literales en el comando ===');
comprobar(SEC, 'echo ghp_abcdefghijklmnopqrstuvwxyz012345 > t.txt', 2);
comprobar(SEC, 'export OPENAI_API_KEY=sk-abcdefghijklmnopqrstuvwxyz0123456789', 2);
comprobar(SEC, 'aws configure set k AKIAIOSFODNN7EXAMPLE', 2);
comprobar(SEC, 'echo "-----BEGIN RSA PRIVATE KEY-----" >> id', 2);

console.log('\n=== guard-secretos: NO debe tocar ===');
comprobar(SEC, 'git add src/index.js', 0);
comprobar(SEC, 'git add README.md', 0);
comprobar(SEC, 'git status', 0);
comprobar(SEC, 'npm install', 0);
comprobar(SEC, 'git commit -m "docs: explicar ${AIRTABLE_API_KEY}"', 0, null, 'placeholder');
comprobar(SEC, 'git log --oneline', 0);
comprobar(SEC, 'cat .env', 0, null, 'leerlo no es commitearlo');

console.log('\n=== guard-secretos: repo real con .env en el index ===');
const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), 'aei-secretos-'));
try {
  const g = (args) => execFileSync('git', args, { cwd: sandbox, stdio: 'ignore' });
  g(['init', '-q']);
  g(['config', 'user.email', 'test@test']);
  g(['config', 'user.name', 'test']);
  fs.writeFileSync(path.join(sandbox, '.env'), 'API_KEY=valor-real\n');
  fs.writeFileSync(path.join(sandbox, 'app.js'), 'hola\n');
  g(['add', '.env', 'app.js']);

  comprobar(SEC, 'git commit -m "primer commit"', 2, sandbox, 'el .env esta en el index');

  // git rm --cached, no git restore --staged: el repo aun no tiene HEAD y
  // restore --staged necesita uno.
  g(['rm', '--cached', '-q', '.env']);
  comprobar(SEC, 'git commit -m "primer commit"', 0, sandbox, 'ya sin el .env');
} finally {
  fs.rmSync(sandbox, { recursive: true, force: true });
}

// ---------------------------------------------------------------------------
console.log('\n=== Los dos deben fallar abierto ===');
for (const hook of [GIT, SEC]) {
  for (const entrada of ['no soy json', '', '{"tool_name":"Read","tool_input":{"file_path":"x"}}']) {
    const { code } = correrCrudo(hook, entrada);
    afirmar(code === 0, hook + ' deja pasar entrada rara');
  }
}

console.log('\n=== El stderr explica que hacer ===');
const eGit = correr(GIT, 'git push --force').stderr;
afirmar(
  /guard-git-destructivo/.test(eGit) && /force-with-lease/.test(eGit),
  'guard-git-destructivo da motivo y alternativa'
);
const eSec = correr(SEC, 'git add .env').stderr;
afirmar(
  /guard-secretos/.test(eSec) && /gitignore/.test(eSec) && /historial/.test(eSec),
  'guard-secretos da motivo y salida'
);

console.log('');
console.log(fallos === 0 ? 'TODO OK (0 fallos)' : fallos + ' FALLOS');
process.exit(fallos === 0 ? 0 : 1);
