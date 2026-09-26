---
name: iniciar
description: Integra Albert-Efficient-Init en el repo actual para todo el equipo - escribe el CLAUDE.md con las reglas base y deja en .claude/settings.json el marketplace y el plugin habilitados, para que cualquiera que clone el repo lo reciba. Usar cuando el usuario escribe /albert:iniciar o pide "integrar Albert", "inicializar el toolkit", "configurar este repo con Albert".
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(test *) Bash(ls *) Bash(cat *) Bash(grep *) Read Write Edit Glob
---

# /albert:iniciar

Deja el repo actual integrado con el toolkit. Dos archivos, los dos se
commitean:

- `CLAUDE.md` en la raiz, con las reglas base.
- `.claude/settings.json`, con el marketplace registrado y el plugin `albert`
  habilitado. Es lo que hace que el resto del equipo lo reciba al confiar en la
  carpeta, sin instalar nada.

## Estado del repositorio

```!
echo "### raiz"
if git rev-parse --show-toplevel 2>/dev/null; then true; else echo "NO-ES-REPO-GIT"; pwd; fi
echo "### claude-md"
if test -f CLAUDE.md; then echo "existe"; grep -c '' CLAUDE.md 2>/dev/null || true; grep -n '^# Reglas base' CLAUDE.md 2>/dev/null || echo "(sin seccion Reglas base)"; else echo "no-existe"; fi
echo "### settings"
if test -f .claude/settings.json; then cat .claude/settings.json; else echo "no-existe"; fi
echo "### gitignore"
grep -n -E '^/?(CLAUDE\.md|\.claude/?|\.claude/settings\.json)$' .gitignore 2>/dev/null || echo "(nada que afecte)"
true
```

## Procedimiento

Trabaja siempre en la raiz que dio `raiz`. Si salio `NO-ES-REPO-GIT`, sigue
igual en el directorio actual pero avisalo en el reporte: sin git no hay nada
que commitear.

### 1. `CLAUDE.md`

La plantilla esta en `${CLAUDE_SKILL_DIR}/CLAUDE-plantilla.md`. Leela con Read.

- **No existe**: copiala tal cual a `CLAUDE.md`.
- **Existe sin `# Reglas base`**: no la reemplaces. Agrega al **final** del
  archivo todo lo que en la plantilla va desde `# Reglas base` hasta el final,
  separado por una linea en blanco. El comentario HTML del principio de la
  plantilla no se agrega: el usuario ya tiene su propio encabezado.
- **Existe con `# Reglas base`**: ya esta integrado. Compara esa seccion con la
  de la plantilla. Si difieren, **no la pises**: el usuario pudo editarla a
  proposito. Reporta que hay una version nueva y deja que decida.

### 2. `.claude/settings.json`

Tiene que contener estas dos claves, con estos valores exactos:

```json
{
  "extraKnownMarketplaces": {
    "albert-efficient-init": {
      "source": { "source": "github", "repo": "Kevin-ToJoin/Albert-Efficient-Init" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "albert@albert-efficient-init": true
  }
}
```

- **No existe**: crealo con exactamente ese contenido.
- **Existe**: **mergea**, no reemplaces. Ahi viven tambien `permissions`, `hooks`
  y otras claves del equipo. Agrega solo la entrada `albert-efficient-init` a
  `extraKnownMarketplaces` y `albert@albert-efficient-init` a `enabledPlugins`,
  creando esos objetos si faltan. Si ya estaban, no toques nada.
- **Existe y no es JSON valido**: no lo toques. Reportalo como pendiente
  manual.

### 3. `.gitignore`

Si `gitignore` mostro que `CLAUDE.md` o `.claude/` estan ignorados, no edites
el `.gitignore`: puede ser una decision del equipo. Reportalo, porque asi el
resto del equipo no recibe el toolkit.

### 4. Sin commit

No commitees. Deja los cambios en el arbol para que el usuario los revise y
agregue lo especifico de su proyecto debajo de las reglas base del
`CLAUDE.md`, que es donde esta el valor real.

## Reporte

Una linea por archivo, con lo que paso: `creado`, `agregado`, `sin cambios` o
el motivo por el que no se toco. Despues, solo si aplica:

- Que falta el `CLAUDE.md` con lo especifico del proyecto: stack, comandos,
  convenciones.
- Lo del paso 3.
- Que los colaboradores lo reciben al abrir el repo en Claude Code y aceptar el
  dialogo de confianza de la carpeta.

Nada mas. Sin repetir el contenido de los archivos.
