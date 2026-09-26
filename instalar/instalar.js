#!/usr/bin/env node
'use strict';

/*
 * Integra Albert-Efficient-Init en el repo actual.
 *
 *   curl -fsSL https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/instalar/instalar.js | node -
 *
 * Por defecto es personal: escribe .claude/settings.local.json y lo excluye de
 * git en .git/info/exclude, que es local y no se commitea. El repo queda sin
 * ningun cambio que commitear. Con --equipo escribe .claude/settings.json, que
 * se commitea para que todo el equipo lo reciba.
 *
 * Agrega sus dos claves al archivo sin tocar lo demas: settings.local.json
 * suele existir ya, con los permisos que el usuario fue aprobando.
 *
 * En Node porque es lo unico que el toolkit ya exige, y asi es una sola
 * implementacion para Windows, macOS y Linux. Sin dependencias.
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const MARKETPLACE = 'albert-efficient-init';
const PLUGIN = 'albert@albert-efficient-init';
const ENTRADA = {
  source: { source: 'github', repo: 'Kevin-ToJoin/Albert-Efficient-Init' },
  autoUpdate: true,
};

const equipo = process.argv.includes('--equipo');

function git(args, cwd) {
  try {
    return execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
  } catch (e) {
    return null;
  }
}

const raiz = git(['rev-parse', '--show-toplevel'], process.cwd()) || process.cwd();
const esGit = git(['rev-parse', '--git-dir'], raiz) !== null;
const nombre = equipo ? 'settings.json' : 'settings.local.json';
const relativo = '.claude/' + nombre;
const archivo = path.join(raiz, '.claude', nombre);

// 1. El archivo de settings, mergeado.
let datos = {};
if (fs.existsSync(archivo)) {
  try {
    datos = JSON.parse(fs.readFileSync(archivo, 'utf8'));
  } catch (e) {
    console.error('No se toco ' + relativo + ': no es JSON valido. Corrigelo y vuelve a correr el comando.');
    process.exit(1);
  }
  if (!datos || typeof datos !== 'object' || Array.isArray(datos)) {
    console.error('No se toco ' + relativo + ': no contiene un objeto JSON.');
    process.exit(1);
  }
}

const antes = JSON.stringify(datos);
datos.extraKnownMarketplaces = Object.assign({}, datos.extraKnownMarketplaces, { [MARKETPLACE]: ENTRADA });
datos.enabledPlugins = Object.assign({}, datos.enabledPlugins, { [PLUGIN]: true });

if (JSON.stringify(datos) === antes) {
  console.log('Sin cambios: ' + relativo + ' ya tenia el toolkit.');
} else {
  fs.mkdirSync(path.dirname(archivo), { recursive: true });
  fs.writeFileSync(archivo, JSON.stringify(datos, null, 2) + '\n');
  console.log('Listo: ' + relativo);
}

// 2. Personal: fuera de git sin tocar el .gitignore del repo.
if (!equipo && esGit) {
  const exclude = path.resolve(raiz, git(['rev-parse', '--git-path', 'info/exclude'], raiz));
  const regla = '/' + relativo;
  const actual = fs.existsSync(exclude) ? fs.readFileSync(exclude, 'utf8') : '';
  if (!actual.split(/\r?\n/).includes(regla)) {
    fs.mkdirSync(path.dirname(exclude), { recursive: true });
    fs.appendFileSync(exclude, (actual && !actual.endsWith('\n') ? '\n' : '') + regla + '\n');
  }
  if (git(['ls-files', '--error-unmatch', relativo], raiz) !== null) {
    console.log('Ojo: ' + relativo + ' ya estaba commiteado en este repo, asi que git lo sigue viendo.');
  } else {
    console.log('Excluido de git en .git/info/exclude: no hay nada que commitear.');
  }
}

if (equipo) console.log('Commitea ' + relativo + ' para que el equipo lo reciba.');
if (!esGit) console.log('Aviso: esta carpeta no es un repo git.');
console.log('Abre el repo con `claude` y acepta la confianza de la carpeta.');
