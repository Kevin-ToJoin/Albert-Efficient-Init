#!/usr/bin/env node
'use strict';

/*
 * Hook SessionStart y SubagentStart: inyecta las reglas base en el contexto.
 *
 * Es lo que reemplaza a copiar las reglas en el CLAUDE.md de cada repo: llegan
 * solas a toda sesion y a todo subagente, y se actualizan con el plugin. El
 * CLAUDE.md del repo destino queda para lo propio del proyecto.
 *
 * Lee plugin/reglas-base.md y lo devuelve como additionalContext, con el
 * nombre del evento que llego por stdin. Los subagentes no ven el contexto de
 * la sesion principal, por eso el mismo hook se registra en los dos eventos.
 *
 * Falla abierto: si no encuentra el archivo o algo va mal, sale 0 sin salida.
 * Una sesion sin reglas base es mejor que una sesion con un error al arrancar.
 */

const fs = require('fs');
const path = require('path');

function leerStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch (e) {
    return '';
  }
}

let evento = 'SessionStart';
try {
  const entrada = JSON.parse(leerStdin() || '{}');
  if (entrada.hook_event_name === 'SubagentStart') evento = 'SubagentStart';
} catch (e) {
  // Sin entrada valida se asume SessionStart.
}

let reglas;
try {
  reglas = fs.readFileSync(path.join(__dirname, '..', 'reglas-base.md'), 'utf8').trim();
} catch (e) {
  process.exit(0);
}
if (!reglas) process.exit(0);

process.stdout.write(
  JSON.stringify({
    hookSpecificOutput: { hookEventName: evento, additionalContext: reglas },
  })
);
