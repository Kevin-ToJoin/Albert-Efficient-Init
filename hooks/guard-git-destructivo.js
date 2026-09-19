#!/usr/bin/env node
'use strict';

/*
 * Hook PreToolUse: bloquea comandos de git que destruyen trabajo.
 *
 * Lee el JSON del hook por stdin, mira tool_input.command, y sale con codigo 2
 * si el comando coincide con algo destructivo. En un PreToolUse, el codigo 2
 * bloquea la llamada y el stderr se le devuelve a Claude como explicacion.
 *
 * En Node y no en PowerShell para que corra igual en Windows, macOS y Linux,
 * incluidas las sesiones remotas. Sin dependencias: solo la libreria estandar.
 *
 * Falla abierto a proposito: si el JSON no parsea o no hay comando, sale 0 y
 * deja pasar. Un guard roto que bloquea todo es peor que no tener guard.
 *
 * Registrarlo en settings.json con matcher "Bash". Ver README.md.
 */

const fs = require('fs');

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

// Las expresiones van sin la bandera /i a proposito: en git la caja distingue
// y -D no es lo mismo que -d. Ese detalle costo un bug en la primera version.
const reglas = [
  {
    test: (c) =>
      /git\s+push\b/.test(c) &&
      (/--force(?!-with-lease)/.test(c) || /(^|\s)-f(\s|$)/.test(c)),
    motivo:
      'git push --force puede sobrescribir trabajo que ya esta en el remoto. Usa --force-with-lease, o pideselo al usuario para que lo ejecute el.',
  },
  {
    test: (c) => /git\s+reset\b[^|;&]*--hard/.test(c),
    motivo:
      'git reset --hard borra los cambios sin commitear y no hay forma de recuperarlos. Si de verdad hace falta, guarda antes con git stash -u.',
  },
  {
    test: (c) => /git\s+clean\b[^|;&]*\s-[a-zA-Z]*f/.test(c),
    motivo:
      'git clean -f borra archivos sin trackear de forma irreversible, incluido trabajo en curso. Corre git clean -n primero para ver que se llevaria.',
  },
  {
    test: (c) => /git\s+branch\b[^|;&]*\s-D\b/.test(c),
    motivo:
      'git branch -D borra una rama aunque tenga commits sin mergear. Usa -d, que falla si quedaria trabajo huerfano.',
  },
];

function denegar(parte, motivo) {
  const e = process.stderr;
  e.write('Bloqueado por el hook guard-git-destructivo.\n\n');
  e.write('  Comando: ' + parte + '\n');
  e.write('  Motivo:  ' + motivo + '\n\n');
  e.write('No reintentes con una variante para esquivar el guard. Si el usuario lo\n');
  e.write('pide explicitamente, explicale que tiene que ejecutarlo el a mano.\n');
  process.exit(2);
}

// Separa por ; && || | para evaluar cada comando encadenado por su cuenta, y
// que "git status && git push --force" no se escape partiendo la linea.
for (const parte of cmd.split(/&&|\|\||;|\|/)) {
  for (const regla of reglas) {
    if (regla.test(parte)) denegar(parte.trim(), regla.motivo);
  }
}

process.exit(0);
