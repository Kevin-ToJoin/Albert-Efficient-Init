---
name: audit-security
description: Auditoria de seguridad completa del repositorio: secretos en el historial, dependencias vulnerables y control de acceso.
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git log *) Bash(git ls-files *) Bash(command -v *) Bash(gitleaks *) Bash(npm audit *) Bash(pip-audit *) Bash(osv-scanner *)
---

# Auditoria de seguridad

Alcance: `$ARGUMENTS` si se indica algo; si no, el repositorio completo.

Esto cubre lo que `/security-review` no cubre. Aquel revisa el diff pendiente;
esto revisa el repositorio entero, su historial y sus dependencias. Si el
usuario solo quiere revisar cambios sin commitear, dirigelo a
`/security-review` y para.

## Herramientas disponibles

```!
for t in gitleaks trufflehog osv-scanner semgrep npm pip-audit cargo; do
  if command -v "$t" >/dev/null 2>&1; then echo "disponible: $t"; else echo "AUSENTE:   $t"; fi
done 2>/dev/null || true
```

## Como proceder

Lanza los tres agentes en paralelo, cada uno con el alcance acotado:

1. `secret-scanner` sobre el historial de git.
2. `dep-auditor` sobre los manifiestos y lockfiles.
3. `authz-reviewer` sobre rutas, middleware y comprobaciones de permisos.

Si una herramienta figura como AUSENTE, el agente correspondiente lo dice en su
informe y cae a la revision manual. No inventes resultados de una herramienta
que no se ejecuto, y no digas "ejecuta esto tu mismo" sin haber intentado antes
la alternativa manual.

## Informe

Agrupa por severidad, no por agente. Una tabla:

| Severidad | Hallazgo | Ubicacion | Accion |
|---|---|---|---|

Reglas de severidad:

- **Critica**: credencial valida expuesta, RCE, autenticacion evitable.
- **Alta**: inyeccion, control de acceso roto, dependencia con CVE explotable
  en una ruta alcanzable.
- **Media**: CVE en dependencia sin ruta alcanzable demostrada, cripto debil.
- **Baja**: fortalecimiento defensivo, cabeceras ausentes.

No infles la severidad. Si no puedes demostrar que una ruta es alcanzable,
dilo y baja la severidad en consecuencia. Un informe con tres hallazgos
demostrados vale mas que uno con treinta especulativos.
