#!/usr/bin/env node
'use strict';

/*
 * Hook PreToolUse: impide que un secreto llegue a un commit.
 *
 * Vigila los comandos de git y bloquea dos cosas:
 *
 *   1. Stagear o commitear archivos de credenciales (.env, *.pem, id_rsa,
 *      credentials.json...). Las plantillas tipo .env.example si pasan: estan
 *      hechas para commitearse.
 *   2. Comandos que llevan un secreto literal escrito dentro (tokens de
 *      GitHub, claves de OpenAI, claves de AWS, bloques PEM).
 *
 * En Node y no en PowerShell para que corra igual en Windows, macOS y Linux,
 * incluidas las sesiones remotas. Sin dependencias: solo la libreria estandar.
 *
 * Falla abierto a proposito: si el JSON no parsea o git no responde, sale 0.
 * Un guard roto que bloquea todo acaba desactivado, y entonces no protege nada.
 *
 * Registrarlo en settings.json con matcher "Bash". Ver README.md.
 */

const fs = require('fs');
const { execFileSync } = require('child_process');

function leerStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch (e) {
    return '';
  }
}

const raw = leerStdin();
if (!raw || !raw.trim()) process.exit(0);

let payload;
try {
  payload = JSON.parse(raw);
} catch (e) {
  process.exit(0);
}

const cmd = payload && payload.tool_input && payload.tool_input.command;
if (typeof cmd !== 'string' || !cmd.trim()) process.exit(0);

function denegar(que, motivo, salida) {
  const e = process.stderr;
  e.write('Bloqueado por el hook guard-secretos.\n\n');
  e.write('  Detectado: ' + que + '\n');
  e.write('  Motivo:    ' + motivo + '\n');
  e.write('  Que hacer: ' + salida + '\n\n');
  e.write('No lo reintentes esquivando el guard. Un secreto commiteado sigue en el\n');
  e.write('historial aunque despues lo borres, y hay que rotarlo igual.\n');
  process.exit(2);
}

// --- 1. Secretos literales escritos en el propio comando ---------------------

const patronesSecreto = [
  { re: /ghp_[A-Za-z0-9]{20,}/, que: 'token de acceso personal de GitHub' },
  { re: /github_pat_[A-Za-z0-9_]{20,}/, que: 'token de acceso personal de GitHub' },
  { re: /sk-[A-Za-z0-9]{32,}/, que: 'clave de API estilo OpenAI' },
  { re: /AKIA[0-9A-Z]{16}/, que: 'access key de AWS' },
  { re: /-----BEGIN [A-Z ]*PRIVATE KEY-----/, que: 'clave privada en formato PEM' },
  { re: /xox[baprs]-[A-Za-z0-9-]{10,}/, que: 'token de Slack' },
];

for (const p of patronesSecreto) {
  if (p.re.test(cmd)) {
    denegar(
      p.que,
      'el comando lleva la credencial escrita en texto plano, y eso acaba en el historial de shell y probablemente en un archivo.',
      'pon el valor en una variable de entorno o en un .env gitignoreado, y en el codigo referencia la variable.'
    );
  }
}

// --- 2. Archivos de credenciales en git add / git commit ---------------------

if (!/git\s+(add|commit|stash\s+push)\b/.test(cmd)) process.exit(0);

// Nombres que son credenciales. Las plantillas quedan fuera a proposito.
const reSensible =
  /(^|\/)(\.env(\.[A-Za-z0-9_-]+)?|credentials\.json|secrets\.json|serviceAccount[A-Za-z0-9_-]*\.json|id_rsa|id_ed25519|id_dsa|[^/]+\.(pem|pfx|p12|keystore|jks))$/;
const rePlantilla = /\.(example|sample|template|dist|ejemplo)$/;

function esSensible(ruta) {
  const r = String(ruta).trim().replace(/^["']|["']$/g, '').replace(/\\/g, '/');
  if (!r) return false;
  if (rePlantilla.test(r)) return false;
  return reSensible.test(r);
}

const encontrados = new Set();

// 2a. Rutas nombradas en el comando. Solo para los comandos cuyos argumentos
// SON rutas.
//
// En `git commit` no se mira el texto, a proposito. Sus argumentos son sobre
// todo un mensaje, y un mensaje que habla de un .env no es un .env. La primera
// version escaneaba el comando entero y se bloqueo a si misma al commitear el
// arreglo de este mismo guard. Intentar separar el mensaje con expresiones
// regulares tampoco vale: en cuanto el mensaje lleva comillas dentro, el
// emparejamiento se desalinea y vuelve el falso positivo.
//
// Para `git commit` manda el index (2b), que es la verdad de git y no una
// suposicion sobre el texto.
if (/git\s+(add|stash\s+push)\b/.test(cmd)) {
  // Lo entrecomillado se aparta, y de ahi solo cuenta lo que es una ruta y
  // nada mas, para que `git add ".env"` siga bloqueado.
  const entrecomillados = [];
  const sinComillas = cmd.replace(/"([^"]*)"|'([^']*)'/g, (m, d, s) => {
    entrecomillados.push(d !== undefined ? d : s);
    return ' ';
  });

  for (const token of sinComillas.split(/\s+/)) {
    if (token.startsWith('-')) continue;
    if (esSensible(token)) encontrados.add(token);
  }

  for (const seg of entrecomillados) {
    const s = seg.trim();
    if (!s || /[\s$`;|&]/.test(s)) continue;
    if (esSensible(s)) encontrados.add(s);
  }
}

// 2b. Lo que ya este en el index. Cubre "git add ." seguido de "git commit".
try {
  const cwd = payload.cwd;
  if (cwd && fs.existsSync(cwd)) {
    const out = execFileSync('git', ['diff', '--cached', '--name-only'], {
      cwd: cwd,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    for (const f of out.split('\n')) {
      if (f && esSensible(f)) encontrados.add(f.trim());
    }
  }
} catch (e) {
  // git no disponible, o no es un repo: no bloqueamos por eso.
}

if (encontrados.size > 0) {
  const lista = Array.from(encontrados).sort().join(', ');
  denegar(
    'archivo de credenciales en el commit: ' + lista,
    'un secreto commiteado queda en el historial para siempre, y en un repo publico se considera filtrado desde el primer push.',
    'agregalo al .gitignore, quitalo del index con git rm --cached <archivo>, y si necesitas versionar su forma, commitea un .env.example sin valores reales.'
  );
}

process.exit(0);
