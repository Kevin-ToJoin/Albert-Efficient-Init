# Guia paso a paso: integrar Albert-Efficient-Init en un repo

Para quien nunca lo ha hecho. Al terminar, tu repo tiene los comandos
`/albert:...`, los subagentes, los hooks de seguridad y las reglas base, y
cualquiera que clone el repo los recibe sin hacer nada.

Hay dos papeles:

- **Quien integra** (una sola vez por repo): pasos 0 a 6.
- **El resto del equipo**: solo la seccion [Si te sumas a un repo que ya lo
  tiene](#si-te-sumas-a-un-repo-que-ya-lo-tiene).

---

## 0. Antes de empezar

Comprueba estas tres cosas. Casi todos los problemas vienen de aqui.

**1. Claude Code instalado y actualizado.**

```bash
claude --version
claude update
```

**2. Node instalado.** Los hooks son scripts de Node. Sin Node, los comandos
funcionan pero los guards de seguridad no.

```bash
node --version
```

Si no sale un numero, instalalo desde [nodejs.org](https://nodejs.org).

**3. Git instalado.** Claude Code descarga el toolkit con `git`. El repo
del toolkit es publico, asi que no hace falta cuenta ni credenciales de GitHub.
Para comprobar que llegas a el:

```bash
git ls-remote https://github.com/Kevin-ToJoin/Albert-Efficient-Init.git
```

Tiene que listar ramas sin pedirte nada.

> Si usas una llave SSH con GitHub y te da problemas, fuerza HTTPS con la
> variable de entorno `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`.

---

## 1. Abre tu repo en Claude Code

En una terminal, entra a la **raiz** del repo donde quieres el toolkit (la
carpeta que tiene `.git`) y arranca Claude Code:

```bash
cd ruta/a/tu-repo
claude
```

Si pregunta si confias en la carpeta, di que si.

## 2. Agrega el catalogo

Dentro de Claude Code, escribe:

```text
/plugin marketplace add Kevin-ToJoin/Albert-Efficient-Init
```

Tiene que responder `Successfully added marketplace: albert-efficient-init`.
Si falla, vuelve al punto 3 del paso 0.

## 3. Instala el plugin para todo el repo

```text
/plugin install albert@albert-efficient-init
```

Se abre un panel con lo que trae el plugin. Elige:

> **Install for all collaborators on this repository (project scope)**

No elijas "for you": en ese caso solo lo tendrias tu.

Si al final dice `Run /reload-plugins to activate`, escribe `/reload-plugins`.

## 4. Deja el repo configurado

```text
/albert:iniciar
```

Este comando te va a pedir permiso para escribir archivos. **Acepta**, sobre
todo el de `.claude/settings.json`: es el que hace que el equipo reciba el
toolkit.

Deja listos dos archivos:

| Archivo | Que hace |
|---|---|
| `CLAUDE.md` | Las reglas base para Claude. Si ya tenias uno, las agrega al final sin tocar lo tuyo |
| `.claude/settings.json` | Registra el catalogo y activa el plugin para quien abra el repo |

Si te avisa que `.claude/` o `CLAUDE.md` estan en el `.gitignore`, quita esas
lineas del `.gitignore`. Si no, esos archivos no se suben y el equipo no recibe
nada.

## 5. Agrega lo tuyo al CLAUDE.md

Abre `CLAUDE.md`. Debajo de las reglas base, agrega lo especifico de **tu**
proyecto. Es donde esta el valor real:

```markdown
## Este proyecto

- Stack: Next.js 15 + Supabase.
- Levantar: `npm run dev`. Tests: `npm test`.
- Los commits van en ingles, en imperativo.
```

Corto y concreto. Agrega una regla cuando te descubras corrigiendo lo mismo dos
veces.

## 6. Sube los cambios

```bash
git add CLAUDE.md .claude/settings.json
git commit -m "Integrar Albert-Efficient-Init"
git push
```

Listo. Ya esta integrado.

---

## Comprueba que funciona

En Claude Code, dentro del repo:

1. Escribe `/albert:` y tienen que aparecer `iniciar`, `finalizar`,
   `lanzar-dominio` y los tres `perfil-...`.
2. Escribe `/plugin` y ve a la pestana **Installed**: tiene que aparecer
   `albert` con alcance de proyecto.
3. Prueba un guard. Pidele a Claude: *"ejecuta `git branch -D rama-que-no-existe`"*.
   Tiene que contestar que un hook lo bloqueo.

## Que tienes ahora

| Que | Como se usa |
|---|---|
| `/albert:finalizar` | Al terminar de trabajar: registra pendientes en `deuda-tecnica.md`, commitea, mergea a `main` y hace push |
| `/albert:lanzar-dominio` | Al comprar un dominio o antes de publicar un sitio |
| `/albert:iniciar` | Volver a correrlo no duplica nada |
| Perfiles de codigo, analisis y seguridad | Se cargan solos cuando la tarea lo pide |
| `@agent-albert:auditor-deuda` | *"@agent-albert:auditor-deuda revisa que deuda falta registrar"* |
| `@agent-albert:auditor-seguridad` | Antes de publicar: audita la app contra nueve puntos basicos |
| Guards | Siempre activos: bloquean `push --force`, `reset --hard` y commitear `.env` o llaves |

---

## Si te sumas a un repo que ya lo tiene

1. Haz el **paso 0** completo (Claude Code, Node y git).
2. Clona el repo y abrelo con `claude`.
3. Cuando pregunte si confias en la carpeta, di **que si**.

Nada mas: Claude Code registra el catalogo y carga el plugin solo. Comprueba
con `/albert:`.

Si no aparece, escribe `/plugin` y mira la pestana **Errors**. Si dice que el
plugin esta habilitado pero no instalado, correlo una vez:

```text
/plugin install albert@albert-efficient-init
```

y elige otra vez alcance de proyecto.

---

## Actualizaciones

Son automaticas: al abrir una sesion, Claude Code busca cambios en segundo
plano y **la siguiente** sesion ya usa la version nueva. Si ves
`Plugin updated ... Run /reload-plugins to apply`, puedes escribir
`/reload-plugins` para no esperar.

Para forzarla en el momento:

```text
/plugin marketplace update albert-efficient-init
```

## Quitarlo

```text
/plugin uninstall albert@albert-efficient-init
```

Te pregunta si quieres desactivarlo solo para ti (`y`) o quitarlo para todo el
equipo (`u`). Si lo quitas para todos, borra tambien, si quieres, la seccion
`# Reglas base` del `CLAUDE.md`, y commitea.

---

## Plan B: sin usar comandos dentro de Claude Code

Por ejemplo, para prepararlo desde un script. Desde la raiz de tu repo, en la
terminal:

```bash
claude plugin marketplace add Kevin-ToJoin/Albert-Efficient-Init --scope project
claude plugin install albert@albert-efficient-init --scope project
```

Eso deja `.claude/settings.json` listo. Luego abre `claude` y corre
`/albert:iniciar` para el `CLAUDE.md`, o crea el `.claude/settings.json` a mano
con esto:

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

Si el archivo ya existia, **no lo reemplaces**: agrega solo esas dos claves,
porque ahi puede haber permisos del equipo.

---

## Problemas frecuentes

| Ves esto | Que pasa | Que hacer |
|---|---|---|
| Falla `marketplace add` o dice que no encuentra el repo | Sin red, o git no instalado | Paso 0, punto 3 |
| `/albert:` no muestra nada | El plugin no cargo | `/plugin`, pestana **Errors** |
| A un companero no le aparece | No acepto la confianza de la carpeta | Que haga la seccion *Si te sumas...* |
| El equipo no recibe nada | `.claude/settings.json` no se subio | Revisa el `.gitignore` y haz `git push` |
| Aviso de hook con `node` en cada comando | Node no esta instalado | Instala Node |
| No llegan las actualizaciones | El auto-update no corrio | `/plugin marketplace update albert-efficient-init` |
