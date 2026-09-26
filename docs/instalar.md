# Guia: integrar Albert-Efficient-Init en un repo

Para quien nunca lo ha hecho. Al terminar, tu repo tiene los comandos
`/albert:...`, los subagentes, los hooks de seguridad y las reglas base, y
cualquiera que lo clone los recibe sin hacer nada.

**Es un solo archivo.** Lo creas, lo commiteas, y listo.

---

## Antes de empezar

En la maquina de cada persona que use el repo:

| Necesitas | Para que | Comprobarlo |
|---|---|---|
| [Claude Code](https://code.claude.com/docs/en/setup) | Todo | `claude --version` |
| git | Claude Code descarga el toolkit con git | `git --version` |
| [Node](https://nodejs.org) | Los hooks de seguridad y las reglas base | `node --version` |

No hace falta cuenta ni credenciales de GitHub: el toolkit es publico.

> Sin Node, los comandos y los subagentes funcionan igual, pero los guards no
> protegen y las reglas base no llegan.

---

## Integrarlo (una vez por repo)

### 1. Crea el archivo

En una terminal, desde la **raiz** del repo (la carpeta que tiene `.git`):

**Mac o Linux:**

```bash
if [ -e .claude/settings.json ]; then echo "Ya existe .claude/settings.json: ve al caso de abajo."; else mkdir -p .claude && curl -fsSL https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/instalar/settings.json -o .claude/settings.json && echo "Listo."; fi
```

**Windows (PowerShell):**

```powershell
if (Test-Path .claude/settings.json) { "Ya existe .claude/settings.json: ve al caso de abajo." } else { New-Item -ItemType Directory -Force .claude | Out-Null; [Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/instalar/settings.json -OutFile .claude/settings.json; "Listo." }
```

**Si tu repo ya tenia `.claude/settings.json`**, no lo reemplaces: ahi puede
haber permisos del equipo. Abre el repo con `claude` y pega esto:

> Agrega a .claude/settings.json las claves de
> https://raw.githubusercontent.com/Kevin-ToJoin/Albert-Efficient-Init/main/instalar/settings.json
> sin quitar nada de lo que ya tiene

### 2. Commitea y sube

```bash
git add .claude/settings.json
git commit -m "Integrar Albert-Efficient-Init"
git push
```

Si `git add` dice que el archivo esta ignorado, quita `.claude/` del
`.gitignore`: si no se sube, el equipo no recibe nada.

### 3. Abre el repo en Claude Code

```bash
claude
```

Cuando pregunte si confias en la carpeta, di **que si**. Claude Code registra
el toolkit y lo carga. Ya esta.

---

## Comprueba que funciona

1. Escribe `/albert:` y tienen que aparecer `iniciar`, `finalizar`,
   `lanzar-dominio` y los tres `perfil-...`.
2. Pidele a Claude: *"ejecuta `git branch -D rama-que-no-existe`"*. Tiene que
   contestar que un hook lo bloqueo.

## Opcional: el CLAUDE.md de tu proyecto

Las reglas base ya llegan solas. Tu `CLAUDE.md` es para lo que solo aplica a
**tu** proyecto: stack, comandos, convenciones, trampas. Para empezar con la
estructura sugerida:

```text
/albert:iniciar
```

Crea el `CLAUDE.md` si no existe y revisa que `.claude/settings.json` este
completo. No commitea: revisa y sube tu.

---

## Si te sumas a un repo que ya lo tiene

1. Revisa la tabla de *Antes de empezar*.
2. Clona el repo, abrelo con `claude` y acepta la confianza de la carpeta.

Nada mas.

---

## Que tienes ahora

| Que | Como se usa |
|---|---|
| Reglas base | Siempre activas. Estan en [plugin/reglas-base.md](../plugin/reglas-base.md) |
| Perfiles de codigo, analisis y seguridad | Se cargan solos cuando la tarea lo pide |
| Guards | Siempre activos: bloquean `push --force`, `reset --hard` y commitear `.env` o llaves |
| `/albert:finalizar` | Al terminar de trabajar: registra pendientes, commitea, mergea y hace push |
| `/albert:lanzar-dominio` | Al comprar un dominio o antes de publicar un sitio |
| `/albert:iniciar` | Opcional: crea tu `CLAUDE.md` y revisa la integracion |
| `@agent-albert:auditor-deuda` | *"@agent-albert:auditor-deuda revisa que deuda falta registrar"* |
| `@agent-albert:auditor-seguridad` | Antes de publicar: audita la app contra nueve puntos basicos |

## Actualizaciones

Automaticas. Al abrir una sesion, Claude Code busca cambios en segundo plano y
**la siguiente** sesion ya usa la version nueva. Si ves
`Plugin updated ... Run /reload-plugins to apply`, escribe `/reload-plugins`
para no esperar.

Para forzarla: `/plugin marketplace update albert-efficient-init`.

## Quitarlo

- **Para todo el equipo:** borra las claves `albert-efficient-init` y
  `albert@albert-efficient-init` de `.claude/settings.json` y commitea.
- **Solo para ti:** `/plugin`, pestana **Installed**, desactiva `albert`.

---

## Problemas frecuentes

| Ves esto | Que pasa | Que hacer |
|---|---|---|
| `/albert:` no muestra nada | No aceptaste la confianza de la carpeta, o el plugin no cargo | Reabre `claude` y acepta; si sigue, `/plugin`, pestana **Errors** |
| A un companero no le aparece | Su copia no tiene `.claude/settings.json` | Que haga `git pull`; revisa que el archivo se subio |
| El equipo no recibe nada | `.claude/` esta en el `.gitignore` | Quitalo del `.gitignore` y sube el archivo |
| Aviso de hook con `node` al abrir la sesion o en cada comando | Node no esta instalado | Instala Node |
| El comando de Windows falla al descargar | PowerShell sin acceso a internet o bloqueado por la red | Crea `.claude/settings.json` a mano con el contenido del [README](../README.md#integrarlo-en-un-repositorio) |
| No llegan las actualizaciones | El auto-update no corrio | `/plugin marketplace update albert-efficient-init` |
