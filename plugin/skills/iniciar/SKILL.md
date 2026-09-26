---
name: iniciar
description: Revisa y completa la integracion de Albert-Efficient-Init en el repo actual - comprueba que .claude/settings.local.json o .claude/settings.json tengan el marketplace, el plugin y la actualizacion automatica, y crea un CLAUDE.md para lo propio del proyecto. Opcional. Usar cuando el usuario escribe /albert:iniciar o pide "revisar la integracion de Albert", "crear el CLAUDE.md del proyecto".
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(test *) Bash(ls *) Bash(cat *) Bash(grep *) Read Write Edit Glob
---

# /albert:iniciar

Opcional. El toolkit ya funciona con solo tener sus claves en
`.claude/settings.local.json` (personal, fuera de git, lo que escribe el
instalador por defecto) o en `.claude/settings.json` (commiteado, para el
equipo). Este comando revisa que esten completas y deja un `CLAUDE.md` para lo
propio del proyecto.

## Estado del repositorio

```!
echo "### raiz"
if git rev-parse --show-toplevel 2>/dev/null; then true; else echo "NO-ES-REPO-GIT"; pwd; fi
echo "### settings-local"
if test -f .claude/settings.local.json; then cat .claude/settings.local.json; else echo "no-existe"; fi
echo "### settings-equipo"
if test -f .claude/settings.json; then cat .claude/settings.json; else echo "no-existe"; fi
echo "### claude-md"
if test -f CLAUDE.md; then echo "existe"; grep -n '^# Reglas base' CLAUDE.md 2>/dev/null || echo "(sin reglas copiadas)"; else echo "no-existe"; fi
echo "### gitignore"
git check-ignore -v .claude/settings.local.json .claude/settings.json 2>/dev/null || echo "(ninguno ignorado)"
true
```

## Procedimiento

Trabaja en la raiz que dio `raiz`. Si salio `NO-ES-REPO-GIT`, sigue en el
directorio actual pero avisalo: sin git no hay nada que commitear.

### 1. Las claves del toolkit

Las que tiene que haber, en uno de los dos archivos:

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

- **Estan completas en alguno**: no toques nada.
- **Estan en uno pero falta `"autoUpdate": true`**: agregalo en ese mismo
  archivo. Es lo que pasa cuando se instalo desde el panel de `/plugin`.
- **No estan en ninguno**: el plugin llego por otro lado, por ejemplo instalado
  para el usuario. No escribas nada: reporta que para integrarlo en este repo
  se corre el instalador, personal por defecto o con `--equipo`, que esta en
  https://github.com/Kevin-ToJoin/Albert-Efficient-Init/blob/main/docs/instalar.md
- Al editar, **mergea**: ahi viven tambien permisos y otras claves. Si el
  archivo no es JSON valido, no lo toques y reportalo.

### 2. `CLAUDE.md`

- **No existe**: copia `${CLAUDE_SKILL_DIR}/CLAUDE-proyecto.md` a `CLAUDE.md`.
  Leelo con Read.
- **Existe sin reglas copiadas**: no lo toques.
- **Existe con `# Reglas base`**: lo dejo una version anterior de este comando,
  cuando las reglas se copiaban. Ahora llegan solas con el plugin, asi que esa
  seccion esta duplicada y ademas no se actualiza. **Pregunta** antes de
  quitarla: quita solo desde `# Reglas base` hasta el siguiente encabezado de
  nivel 1 o el final, y nada de lo que escribio el equipo.

### 3. Git

Mira `gitignore`. Lo esperado es que `settings.local.json` salga ignorado y
`settings.json` no. Si `settings.json` tiene las claves y esta ignorado, el
equipo no recibe el toolkit: reportalo, sin editar el `.gitignore`.

### 4. Sin commit

No commitees. Deja los cambios para que el usuario los revise.

## Reporte

Una linea por archivo con lo que paso: `creado`, `completado`, `sin cambios` o
el motivo por el que no se toco. Despues, solo si aplica:

- Lo del paso 3.
- Si las claves estan en `settings.json` y hay cambios: que hay que
  commitearlo para que el equipo lo reciba.

Nada mas. Sin repetir el contenido de los archivos.
