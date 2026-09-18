---
name: finalizar
description: Cierra la sesion de trabajo del repo actual - mergea la rama actual a la rama base (main/master), registra los pendientes en deuda-tecnica.md, y reporta unicamente lo que requiere accion manual del usuario. Usar cuando el usuario escribe /finalizar o pide "finalizar", "cerrar la sesion", "cerrar el trabajo".
argument-hint: "[mensaje de commit opcional]"
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(test *) Bash(ls *) Bash(cat *) Read Write Edit Glob Grep
---

# /finalizar

Cierre de sesion de trabajo. Tres cosas: mergear a la rama base, registrar la
deuda tecnica, y reportar al usuario solo lo que el tiene que hacer a mano.

Mensaje de commit indicado por el usuario (puede venir vacio): `$ARGUMENTS`

## Estado del repositorio

```!
echo "### rama-actual"
if git rev-parse --git-dir >/dev/null 2>&1; then
  git symbolic-ref --short -q HEAD || echo "HEAD-DESPRENDIDO"
else
  echo "NO-ES-REPO-GIT"
fi
echo "### estado-arbol"
git status --porcelain 2>/dev/null | head -60 || true
echo "### ramas-locales"
git branch --format='%(refname:short)' 2>/dev/null | head -40 || true
echo "### remotos"
git remote 2>/dev/null | grep . || echo "(sin remoto)"
echo "### origin-head"
git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo "(no definido)"
echo "### commits-adelante-de-base"
git log --oneline --no-decorate HEAD --not main 2>/dev/null \
  || git log --oneline --no-decorate HEAD --not master 2>/dev/null \
  || echo "(sin rama base local)"
echo "### archivos-de-la-rama"
{ git diff --name-only main...HEAD 2>/dev/null \
    || git diff --name-only master...HEAD 2>/dev/null || true
  git status --porcelain 2>/dev/null | awk '{print $NF}'; } | sort -u | head -60
echo "### deuda-tecnica"
if test -f deuda-tecnica.md; then echo "existe"; else echo "no-existe"; fi
true
```

## Procedimiento

Ejecuta los pasos en orden. Si un paso falla, **no abortes el resto**: anota el
fallo como pendiente manual y sigue con lo que si se pueda hacer.

### 0. Verificar que aplica

- `rama-actual` = `NO-ES-REPO-GIT`: para aqui y di solo
  `No es un repositorio git.` Nada mas.
- `rama-actual` = `HEAD-DESPRENDIDO`: no mergees nada. Reporta como pendiente
  manual que el HEAD esta desprendido y que hay que crear o elegir una rama.
- Repo sin ningun commit (`commits-adelante-de-base` vacio y `estado-arbol` con
  todo sin trackear): haz el primer commit y para ahi; no hay nada que mergear.

### 1. Determinar la rama base

En este orden, la primera que exista:

1. `main` local
2. `master` local
3. la rama a la que apunta `origin/HEAD`

Si no existe ninguna, para y reportalo como pendiente manual.

Si ya estas en la rama base, el paso 4 (merge) se omite y el resto sigue igual.

### 2. Actualizar `deuda-tecnica.md`

Se escribe en la rama **actual**, antes del merge, para que viaje con el.

Reune los pendientes de estas cuatro fuentes:

1. **La sesion actual.** Lo que quedo a medias, los atajos que tomaste, las
   decisiones diferidas, lo que dijiste "despues lo vemos". Esta es la fuente
   mas valiosa y la unica que solo tu conoces.
2. **Marcadores en el codigo que tocaste en esta sesion.** Busca `TODO`,
   `FIXME`, `HACK`, `XXX`, `WIP` con Grep, solo en los archivos que aparecen en
   `archivos-tocados-vs-HEAD` y en los commits de la rama. No inventariar todo
   el repo.
3. **Tests.** Tests saltados, `skip`, `xfail`, `it.only`, o funcionalidad nueva
   sin test.
4. **Lo que dejaste sin verificar.** Codigo que escribiste pero no ejecutaste ni
   probaste.

Si el archivo no existe, crealo con esta plantilla exacta:

```markdown
# Deuda tecnica

Registro de pendientes, atajos y decisiones diferidas de este repositorio.
Lo mantiene el comando `/finalizar` de Claude Code.

Convencion: cada item lleva `[M]` si requiere accion manual del usuario
(credenciales, decision de producto, acceso, algo fuera del repo), o `[A]` si
es trabajo que un agente puede hacer solo.

## Abiertos

## Cerrados

## Bitacora
```

Reglas de escritura:

- **Append, nunca sobrescribir.** Respeta lo que ya hay, incluido lo editado a
  mano por el usuario.
- **`## Abiertos`**: lista de checkboxes. Cada item en una linea:
  `- [ ] [M|A] <descripcion concreta> - <archivo:linea si aplica>`
  Concreto y accionable. `- [ ] [A] extraer la validacion duplicada de
  auth.ts:44 y auth.ts:91` sirve; `- [ ] mejorar el codigo` no sirve.
- **Deduplica.** Si un pendiente ya esta en `## Abiertos`, no lo repitas;
  actualiza la linea existente si cambio.
- **Cierra lo resuelto.** Si un item de `## Abiertos` quedo resuelto en esta
  sesion, muevelo a `## Cerrados` marcado `- [x]` con la fecha.
- **`## Bitacora`**: una entrada por corrida, la mas reciente arriba:
  ```
  ### <YYYY-MM-DD> - rama `<rama>`
  <una o dos lineas de que se hizo>
  Nuevos pendientes: <n> | Cerrados: <n>
  ```
- Si de verdad no hay ningun pendiente nuevo, igual agrega la entrada de
  bitacora con `Nuevos pendientes: 0`. Deja constancia de la corrida.
- Sin deuda inventada. Si no hay nada que anotar, no rellenes.

### 3. Commit

Si el arbol tiene cambios (incluido `deuda-tecnica.md`), commitealos:

- `git add -A` y un solo commit.
- Mensaje: usa `$ARGUMENTS` si el usuario lo dio. Si no, derivalo de los
  cambios reales en imperativo, una linea, sin prefijo de herramienta.
- Si el arbol ya estaba limpio y no hubo cambios en la deuda, no hay commit.
  No fuerces uno vacio.

### 4. Merge a la rama base

Solo si no estabas ya en la rama base.

1. `git switch <base>`
2. Si hay remoto: `git pull --ff-only origin <base>`. Si el pull falla, sigue
   con lo local y anotalo como pendiente manual.
3. `git merge --no-edit <rama-de-trabajo>`
4. **Si hay conflicto**: `git merge --abort`, vuelve con
   `git switch <rama-de-trabajo>`, y registra como pendiente manual la lista de
   archivos en conflicto. No resuelvas conflictos de merge dentro de
   `/finalizar` sin que el usuario lo pida.

### 5. Push

Solo si hay remoto.

- `git push origin <base>`
- Si el push es rechazado porque la rama esta protegida o por falta de
  permisos: **no hagas force push**. En su lugar, empuja la rama de trabajo
  (`git push -u origin <rama-de-trabajo>`) y registra como pendiente manual
  que hay que abrir/mergear un PR. Incluye el nombre de la rama.
- Si el push falla por red, reintenta una vez. Si vuelve a fallar, pendiente
  manual.

### 6. Reporte al usuario

Esta es la parte que importa. El usuario no quiere un resumen.

**Si NO hay pendientes que requieran accion manual suya**, responde
exactamente una linea:

```
OK
```

Nada mas. Sin resumen de lo que hiciste, sin lista de commits, sin "he
mergeado exitosamente", sin ofrecer siguientes pasos.

**Si SI hay pendientes manuales**, responde solo esos, en este formato, sin
preambulo:

```
Requiere tu accion:
- <pendiente 1>
- <pendiente 2>
```

Cuenta como pendiente manual unicamente:

- Conflicto de merge que necesita que el usuario decida.
- Push rechazado / rama protegida / PR por abrir o mergear.
- Credenciales, secretos, variables de entorno o accesos que faltan.
- Una decision de producto o de arquitectura que no te corresponde tomar.
- Algo fuera del repo (configurar un servicio, un permiso, un DNS).
- Un fallo de comando que no pudiste resolver.

**No** cuenta como pendiente manual, y por lo tanto **no** se reporta:

- Deuda tecnica normal que ya quedo anotada en `deuda-tecnica.md`.
- Refactors, tests faltantes, TODOs del codigo: eso vive en el archivo.
- Lo que hiciste bien.
