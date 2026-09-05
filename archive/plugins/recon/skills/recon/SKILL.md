---
name: recon
description: Reconoce un proyecto desconocido, lo clasifica y emite un plan de auditoria priorizado.
disable-model-invocation: true
context: fork
agent: general-purpose
background: false
allowed-tools: Read Grep Glob Bash(git log *) Bash(git shortlog *) Bash(git ls-files *) Bash(git tag *) Bash(ls *) Bash(cat *) Bash(find *) Bash(wc *)
---

# Reconocimiento de proyecto

Argumentos recibidos: `$ARGUMENTS`

Si contienen `--save`, escribe el informe final en
`.claude/audits/<YYYY-MM-DD>-recon.md` ademas de mostrarlo. Si no, solo
muestralo.

## Datos del proyecto

Lo que sigue ya esta recogido. No vuelvas a ejecutar estos comandos.

### Raiz

```!
ls -a 2>/dev/null | head -40 || true
```

### Manifiestos de dependencias

```!
for f in package.json pyproject.toml requirements.txt go.mod Cargo.toml composer.json Gemfile pom.xml build.gradle Makefile; do
  if [ -f "$f" ]; then echo "=== $f ==="; head -60 "$f"; fi
done 2>/dev/null || true
```

### Actividad en git

```!
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "commits: $(git rev-list --count HEAD 2>/dev/null || echo 0)"
  echo "primer commit: $(git log --reverse --format=%as 2>/dev/null | head -1)"
  echo "ultimo commit: $(git log -1 --format='%as (%cr)' 2>/dev/null)"
  echo "tags: $(git tag 2>/dev/null | wc -l | tr -d ' ')"
  echo "--- autores ultimos 6 meses ---"
  git shortlog -sn --since='6 months ago' 2>/dev/null | head -15
  echo "--- ultimos 20 commits ---"
  git log --oneline -20 2>/dev/null
else
  echo "sin repositorio git"
fi || true
```

### Tamano y forma

```!
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ficheros versionados: $(git ls-files 2>/dev/null | wc -l | tr -d ' ')"
  echo "--- extensiones mas comunes ---"
  git ls-files 2>/dev/null | sed 's/.*\.//' | grep -v '/' | sort | uniq -c | sort -rn | head -12
fi
echo "--- CI ---"
ls .github/workflows .gitlab-ci.yml .circleci Jenkinsfile 2>/dev/null || echo "sin CI detectada"
echo "--- tests ---"
find . -maxdepth 3 -type d \( -name test -o -name tests -o -name __tests__ -o -name spec \) -not -path '*/node_modules/*' 2>/dev/null | head -10 || true
```

## Que producir

### 1. Clasificacion

Elige exactamente uno de estos cuatro estados. Cita el dato concreto que
sostiene la eleccion, no des un juicio sin respaldo.

| Estado | Criterio |
|---|---|
| **Nuevo** | Menos de 30 commits, o menos de 90 dias desde el primer commit, y sin tags de release |
| **Vivo** | Commit en los ultimos 30 dias, dos o mas autores en los ultimos 6 meses, y CI presente |
| **En mantenimiento** | Ultimo commit entre 30 dias y 12 meses, y los commits recientes son mayoritariamente fixes o bumps de dependencias |
| **Legacy** | Sin commits en 12 meses o mas; o bien sin tests y sin CI con mas de 500 ficheros versionados |

Si el proyecto encaja en dos, elige el mas conservador (el que implique mas
riesgo) y explica el empate en una linea.

### 2. Inventario

Maximo una linea por punto. Si un dato no es determinable, escribe "no
determinable" en lugar de suponerlo.

- Stack y version del runtime.
- Gestor de paquetes y si el lockfile esta versionado.
- Entrypoints: que se ejecuta para arrancar esto.
- Superficie expuesta: puertos, rutas HTTP, CLIs, jobs programados.
- Donde viven los secretos: `.env`, gestor de secretos, variables de CI.
- Estado de los tests: existen, se ejecutan en CI, cubren algo critico.

### 3. Plan de auditoria priorizado

Emite una lista ordenada. Cada entrada nombra la skill concreta a ejecutar y
la razon en una linea. Usa esta tabla de despacho segun la clasificacion:

| Estado | Orden recomendado |
|---|---|
| **Nuevo** | `/audit-security` (secretos antes de que el historial crezca), luego fijar tests y CI |
| **Vivo** | `/code-review` sobre el diff pendiente, `/audit-security` en dependencias, `/audit-quality` para huecos de cobertura |
| **En mantenimiento** | `/audit-security` completo, `/audit-quality` para dependencias sin mantenimiento |
| **Legacy** | `/audit-security` completo primero, luego `/audit-quality` para codigo muerto antes de tocar nada |

Anade `/audit-ui` al plan solo si detectaste una interfaz web servida por el
proyecto.

Estas skills viven en plugins separados del marketplace `aei`. Si alguna no
esta instalada, dilo en el plan en vez de asumir que esta disponible.

## Reglas

- No arregles nada. Esto es reconocimiento, no intervencion.
- No propongas refactors. El plan nombra auditorias, no cambios.
- Si el directorio no es un proyecto de codigo, dilo en una linea y para.
