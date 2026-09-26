# Seguridad

Este toolkit se ejecuta dentro de otros repositorios: sus hooks corren como
procesos en la máquina de cada persona que trabaja en un repo que lo integra, y
sus skills le dan instrucciones a Claude Code allí. Un fallo aquí afecta a
todos esos repos a la vez.

## Reportar una vulnerabilidad

**No abras un issue público.** Usa el reporte privado de GitHub:
[Security → Report a vulnerability](https://github.com/Kevin-ToJoin/Albert-Efficient-Init/security/advisories/new).

Incluye qué pieza está afectada (`plugin/hooks/`, una skill, un agente), cómo
reproducirlo y qué podría hacer un atacante con ello.

## Qué cuenta

- Un hook que ejecute algo distinto de lo que dice, lea o envíe datos fuera de
  la máquina, o sea explotable con un comando o un nombre de archivo preparado.
- Una skill o un agente que se pueda manipular para filtrar código o
  credenciales del repo donde corre.
- Cualquier forma de que un cambio llegue a `main` sin revisión.

Que un guard no bloquee una variante de un comando peligroso es un bug, no una
vulnerabilidad: los guards protegen contra errores del modelo, no contra un
atacante que ya ejecuta comandos en tu máquina. Repórtalo como issue normal.

## Cómo se protege `main`

Un push a `main` le llega a todos los repos integrados con la siguiente
actualización automática. Por eso `main` exige pull request con revisión y no
admite force push, y el repo tiene activado el escaneo de secretos.
