---
name: iniciar
description: Revisa y completa la integracion de Albert-Efficient-Init en el repo actual - deja .claude/settings.json con el marketplace, el plugin y la actualizacion automatica, y crea un CLAUDE.md para lo propio del proyecto. Opcional. Usar cuando el usuario escribe /albert:iniciar o pide "revisar la integracion de Albert", "crear el CLAUDE.md del proyecto".
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(test *) Bash(ls *) Bash(cat *) Bash(grep *) Read Write Edit Glob
---

# /albert:iniciar

Opcional. El toolkit ya funciona con solo tener `.claude/settings.json`: las
skills, los agentes, los hooks y las reglas base llegan solos. Este comando
revisa que ese archivo este completo y deja un `CLAUDE.md` para lo propio del
proyecto.

## Estado del repositorio

```!
echo "### raiz"
if git rev-parse --show-toplevel 2>/dev/null; then true; else echo "NO-ES-REPO-GIT"; pwd; fi
echo "### settings"
if test -f .claude/settings.json; then cat .claude/settings.json; else echo "no-existe"; fi
echo "### claude-md"
if test -f CLAUDE.md; then echo "existe"; grep -n '^# Reglas base' CLAUDE.md 2>/dev/null || echo "(sin reglas copiadas)"; else echo "no-existe"; fi
echo "### gitignore"
grep -n -E '^/?(CLAUDE\.md|\.claude/?|\.claude/settings\.json)$' .gitignore 2>/dev/null || echo "(nada que afecte)"
true
```

## Procedimiento

Trabaja en la raiz que dio `raiz`. Si salio `NO-ES-REPO-GIT`, sigue en el
directorio actual pero avisalo: sin git no hay nada que commitear.

### 1. `.claude/settings.json`

Tiene que contener estas dos claves con estos valores:

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
  y otras claves del equipo. Agrega lo que falte, incluido `"autoUpdate": true`
  si la entrada del marketplace existe sin el: es lo que falta cuando se
  instalo desde el panel de `/plugin`. Si ya esta todo, no toques nada.
- **Existe y no es JSON valido**: no lo toques. Reportalo.

### 2. `CLAUDE.md`

- **No existe**: copia `${CLAUDE_SKILL_DIR}/CLAUDE-proyecto.md` a `CLAUDE.md`.
  Leelo con Read.
- **Existe sin reglas copiadas**: no lo toques.
- **Existe con `# Reglas base`**: lo dejo una version anterior de este comando,
  cuando las reglas se copiaban. Ahora llegan solas con el plugin, asi que esa
  seccion esta duplicada y ademas no se actualiza. **Pregunta** antes de
  quitarla: quita solo desde `# Reglas base` hasta el siguiente encabezado de
  nivel 1 o el final, y nada de lo que escribio el equipo.

### 3. `.gitignore`

Si `gitignore` mostro que `.claude/` o `.claude/settings.json` estan ignorados,
no lo edites: reportalo, porque asi el equipo no recibe el toolkit.

### 4. Sin commit

No commitees. Deja los cambios para que el usuario los revise.

## Reporte

Una linea por archivo con lo que paso: `creado`, `completado`, `sin cambios` o
el motivo por el que no se toco. Despues, solo si aplica:

- Lo del paso 3.
- Que falta commitear y subir `.claude/settings.json` para que el equipo lo
  reciba.

Nada mas. Sin repetir el contenido de los archivos.
