---
name: lanzar-dominio
description: Checklist de puesta en marcha de un dominio - reparto en subdominios (app, correo transaccional, campanas), sitemap, robots.txt y alta en Google Search Console. Genera lo que se puede generar y marca lo que tienes que hacer tu a mano. Usar al comprar un dominio o antes de publicar un sitio.
argument-hint: "[dominio, p.ej. midominio.com]"
disable-model-invocation: true
allowed-tools: Bash(ls *) Bash(test *) Bash(grep *) Bash(cat *) Read Write Edit Glob Grep
---

# /albert:lanzar-dominio

Preparar un dominio nuevo. Dominio indicado por el usuario (puede venir vacio):
`$ARGUMENTS`

## Estado del proyecto

```!
echo "### archivos-seo (vacio = ninguno)"
ls robots.txt sitemap.xml sitemap_index.xml public/robots.txt public/sitemap.xml static/robots.txt static/sitemap.xml 2>/dev/null || true
echo "### framework"
test -f package.json || echo "(sin package.json)"
grep -oE '"(next|astro|nuxt|gatsby|remix|vite|svelte)"' package.json 2>/dev/null || true
echo "### carpeta-publica (vacio = ninguna)"
ls -d public static dist 2>/dev/null || true
true
```

## El reparto en subdominios

Esto es lo que mas se hace mal y lo que mas cuesta deshacer. La raiz y los
subdominios no se reparten por gusto estetico, sino para **aislar la reputacion
de envio**:

| Subdominio | Para que | Por que separado |
|---|---|---|
| `midominio.com` | Sitio de mercadeo, landing | Es lo que se indexa y lo que la gente teclea |
| `app.midominio.com` | La aplicacion | Se despliega distinto, tiene otras cookies y otro cache. Mezclarlo con el sitio complica los dos |
| `email.midominio.com` | Correo transaccional: registro, recuperar contrasena, recibos | Si tus campanas acaban marcadas como spam, esto **tiene** que seguir llegando |
| `info.midominio.com` | Campanas de mercadeo, newsletters | Es lo que mas riesgo tiene de que lo marquen. Aislado, no arrastra al resto |

Si mandas transaccional y campanas por el mismo dominio, una campana mal
recibida se lleva por delante los correos de recuperar contrasena. Ese es todo
el motivo.

## Procedimiento

### 1. Confirmar el dominio

Si `$ARGUMENTS` viene vacio, mira en el contexto de arriba si hay un dominio en
la configuracion. Si no lo hay, pregunta y para ahi: sin dominio no se puede
generar nada util.

### 2. Proponer el reparto

Presenta la tabla de arriba con el dominio real sustituido. No lo apliques: el
DNS lo configura el usuario en su registrador. Quedate en la propuesta.

### 3. `robots.txt`

Si no existe, crealo en la carpeta publica que detectaste (`public/`,
`static/`, o la raiz si no hay). Minimo:

```
User-agent: *
Allow: /

Sitemap: https://<dominio>/sitemap.xml
```

Si el sitio tiene zonas que no deben indexarse (un panel, un `/admin`, una
staging), anadelas como `Disallow`. Preguntale al usuario cuales son en vez de
adivinar.

### 4. `sitemap.xml`

Antes de escribir nada, mira como genera rutas el framework detectado. Next,
Astro, Nuxt y Gatsby tienen generadores propios o plugins: **si el framework
puede generarlo, configuralo en vez de escribir un XML a mano**, que se queda
viejo en el primer despliegue.

Solo si no hay generador, escribe el XML:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://midominio.com/</loc>
    <priority>1.0</priority>
    <changefreq>weekly</changefreq>
  </url>
</urlset>
```

Una entrada por ruta publica real. No inventes rutas que no existan en el
proyecto: comprueba antes con Glob.

### 5. Google Search Console

Esto no lo puedes hacer tu. Reportalo como pendiente manual con los pasos:

1. Dar de alta la propiedad en Search Console.
2. Verificar la propiedad, normalmente con un registro TXT en el DNS.
3. En *Sitemaps*, enviar `sitemap.xml` o `sitemap_index.xml`.
4. Repetirlo para `app.` si esa parte tambien se indexa. Lo habitual es que
   **no** se indexe: si la app es privada, va con `Disallow: /` y sin sitemap.

## Reporte

Dos bloques, sin preambulo:

```
Hecho:
- <archivo creado o configuracion cambiada>

Requiere tu accion:
- <paso manual, con el dato concreto que hace falta>
```

Los pasos de DNS, registrador y Search Console van **siempre** en el segundo
bloque: no son cosas del repo.

Si el sitio no se va a indexar (una app privada, una API), dilo y salta los
pasos 3 a 5 en vez de generar archivos que nadie va a usar.
