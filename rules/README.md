# rules/

Reglas de eficiencia para Claude Code, pensadas para vivir **gitignoreadas** en
el proyecto destino: reflejan tu preferencia personal sin imponérsela a tus
colaboradores.

Esta carpeta es un espejo de lo que aterriza en el proyecto. Son dos cosas:

```
rules/CLAUDE-root-template.md   ->  <proyecto>/CLAUDE.md
rules/Efficiency/               ->  <proyecto>/Efficiency/
```

> **Ojo al editar la plantilla.** El `CLAUDE.md` de la raiz de este repo la
> importa con `@rules/CLAUDE-root-template.md`, asi que un cambio ahi tambien
> cambia como se comporta Claude Code trabajando *en este* repo. Es a proposito:
> una sola fuente, y comemos de nuestra propia comida. La plantilla tiene que
> seguir siendo **autocontenida**, porque cuando viaja a otro proyecto va sola y
> ahi no hay nada que importar.

## Copiarlas a un proyecto

```powershell
Copy-Item "<repo>\rules\CLAUDE-root-template.md" "<proyecto>\CLAUDE.md"
Copy-Item "<repo>\rules\Efficiency" "<proyecto>\Efficiency" -Recurse
```

Y gitignorear las dos, que es el punto:

```gitignore
# Albert-Efficient-Init (reglas local-only)
/CLAUDE.md
/Efficiency/
```

> Se copian, no se enlazan. Un `CLAUDE.md` es contexto que quieres poder tocar
> por proyecto sin que el cambio se propague a todos los demás — al revés que los
> comandos de `skills/`, que sí conviene tener enlazados y sincronizados.

## Cómo funcionan

`CLAUDE.md` se carga siempre y lleva las reglas base: leer antes de escribir,
salida concisa, nada de inventar APIs ni rutas, sin relleno conversacional.

Los perfiles de `Efficiency/` se leen **solo cuando la tarea lo pide**, para no
gastar contexto en reglas que no aplican:

- `rules-coding.md` — desarrollo, code review, debugging, refactors.
- `rules-analysis.md` — análisis de datos, research, reporting.
- `rules-seguridad.md` — autenticación, datos de usuarios, endpoints públicos,
  pagos, secretos.

También puedes pedirlo explícitamente en un prompt: *"aplica el perfil de coding
y revisa esta función"*.

## Agregar un perfil

Deja un `rules-<nombre>.md` en `Efficiency/` y añádelo a la sección *Profiles*
de `CLAUDE-root-template.md` para que Claude sepa cuándo leerlo. Si solo creas el
archivo y no lo listas, nunca se carga.

## Quitarlas

Borra `CLAUDE.md` y `Efficiency/` del proyecto. No dejan rastro: nunca estuvieron
trackeadas.
