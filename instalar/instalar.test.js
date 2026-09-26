#!/usr/bin/env node
'use strict';

/*
 * Pruebas de instalar.js. Correr con:
 *   node instalar/instalar.test.js
 *
 * Cada caso corre el script como lo corre un usuario, por stdin a `node -`, en
 * un repo temporal y con un HOME vacio: asi ninguna regla global de git de
 * esta maquina tapa si el archivo quedo de verdad fuera de git.
 */

const { spawnSync, execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const script = fs.readFileSync(path.join(__dirname, 'instalar.js'), 'utf8');
const base = fs.mkdtempSync(path.join(os.tmpdir(), 'aei-instalar-'));
const home = path.join(base, 'home');
fs.mkdirSync(home);
const entorno = Object.assign({}, process.env, {
  HOME: home,
  USERPROFILE: home,
  XDG_CONFIG_HOME: path.join(home, '.config'),
  GIT_CONFIG_GLOBAL: path.join(home, '.gitconfig'),
  GIT_AUTHOR_NAME: 't', GIT_AUTHOR_EMAIL: 't@example.com',
  GIT_COMMITTER_NAME: 't', GIT_COMMITTER_EMAIL: 't@example.com',
});

let fallos = 0;
function afirmar(cond, mensaje) {
  if (cond) console.log('  PASS  ' + mensaje);
  else { console.log('  FAIL  ' + mensaje); fallos++; }
}

function repo(nombre, conGit = true) {
  const dir = path.join(base, nombre);
  fs.mkdirSync(dir, { recursive: true });
  if (conGit) {
    execFileSync('git', ['init', '-q', '-b', 'main'], { cwd: dir, env: entorno });
    execFileSync('git', ['commit', '-q', '--allow-empty', '-m', 'x'], { cwd: dir, env: entorno });
  }
  return dir;
}

function instalar(cwd, ...args) {
  return spawnSync(process.execPath, ['-', ...args], { cwd, input: script, encoding: 'utf8', env: entorno });
}

function leer(dir, nombre) {
  return JSON.parse(fs.readFileSync(path.join(dir, '.claude', nombre), 'utf8'));
}

function limpio(dir) {
  return execFileSync('git', ['status', '--porcelain', '--untracked-files=all'], { cwd: dir, env: entorno, encoding: 'utf8' }) === '';
}

function tieneToolkit(d) {
  return d.extraKnownMarketplaces['albert-efficient-init'].autoUpdate === true &&
    d.extraKnownMarketplaces['albert-efficient-init'].source.repo === 'Kevin-ToJoin/Albert-Efficient-Init' &&
    d.enabledPlugins['albert@albert-efficient-init'] === true;
}

console.log('\n=== Personal, repo nuevo ===');
{
  const dir = repo('nuevo');
  const r = instalar(dir);
  afirmar(r.status === 0, 'sale 0');
  afirmar(tieneToolkit(leer(dir, 'settings.local.json')), 'escribe settings.local.json con el toolkit');
  afirmar(!fs.existsSync(path.join(dir, '.claude', 'settings.json')), 'no crea settings.json');
  afirmar(limpio(dir), 'git status queda limpio: nada que commitear');
  afirmar(!fs.existsSync(path.join(dir, '.gitignore')), 'no crea ni toca .gitignore');
}

console.log('\n=== Personal, settings.local.json con permisos previos ===');
{
  const dir = repo('existente');
  fs.mkdirSync(path.join(dir, '.claude'));
  const previo = { permissions: { allow: ['Bash(npm test)'] }, enabledPlugins: { 'otro@mkt': true } };
  fs.writeFileSync(path.join(dir, '.claude', 'settings.local.json'), JSON.stringify(previo));
  instalar(dir);
  const d = leer(dir, 'settings.local.json');
  afirmar(tieneToolkit(d), 'agrega el toolkit');
  afirmar(d.permissions.allow[0] === 'Bash(npm test)', 'conserva los permisos');
  afirmar(d.enabledPlugins['otro@mkt'] === true, 'conserva los otros plugins');
}

console.log('\n=== Idempotente ===');
{
  const dir = repo('dos-veces');
  instalar(dir);
  const r = instalar(dir);
  afirmar(/Sin cambios/.test(r.stdout), 'la segunda vez dice Sin cambios');
  const exclude = fs.readFileSync(path.join(dir, '.git', 'info', 'exclude'), 'utf8');
  afirmar(exclude.split('\n').filter((l) => l === '/.claude/settings.local.json').length === 1, 'no duplica la regla en exclude');
}

console.log('\n=== JSON invalido no se toca ===');
{
  const dir = repo('roto');
  fs.mkdirSync(path.join(dir, '.claude'));
  fs.writeFileSync(path.join(dir, '.claude', 'settings.local.json'), '{ esto no es json');
  const r = instalar(dir);
  afirmar(r.status === 1, 'sale 1');
  afirmar(fs.readFileSync(path.join(dir, '.claude', 'settings.local.json'), 'utf8') === '{ esto no es json', 'deja el archivo intacto');
}

console.log('\n=== Desde una subcarpeta escribe en la raiz ===');
{
  const dir = repo('sub');
  fs.mkdirSync(path.join(dir, 'src', 'app'), { recursive: true });
  instalar(path.join(dir, 'src', 'app'));
  afirmar(fs.existsSync(path.join(dir, '.claude', 'settings.local.json')), 'el archivo queda en la raiz del repo');
  afirmar(!fs.existsSync(path.join(dir, 'src', 'app', '.claude')), 'no crea .claude en la subcarpeta');
}

console.log('\n=== --equipo ===');
{
  const dir = repo('equipo');
  const r = instalar(dir, '--equipo');
  afirmar(r.status === 0 && tieneToolkit(leer(dir, 'settings.json')), 'escribe settings.json con el toolkit');
  afirmar(!limpio(dir), 'queda para commitear');
  afirmar(/Commitea/.test(r.stdout), 'dice que hay que commitearlo');
}

console.log('\n=== Carpeta sin git ===');
{
  const dir = repo('sin-git', false);
  const r = instalar(dir);
  afirmar(r.status === 0 && tieneToolkit(leer(dir, 'settings.local.json')), 'escribe igual y sale 0');
  afirmar(/no es un repo git/.test(r.stdout), 'avisa que no es un repo git');
}

fs.rmSync(base, { recursive: true, force: true });
console.log('');
console.log(fallos === 0 ? 'TODO OK (0 fallos)' : fallos + ' FALLOS');
process.exit(fallos === 0 ? 0 : 1);
