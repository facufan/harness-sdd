# Skills — área `core`

> Índice de skills de esta área. Cada área **debe** tener este archivo (el
> arnés lo exige en `init.sh`). Es el catálogo que el `spec-author` y el
> `implementer` leen para elegir, por su "cuándo", la skill aplicable a la tarea.
>
> Una skill = un procedimiento reutilizable y verificado para hacer algo en
> esta área, con un ejemplo real (`archivo:línea`). La sección `## Conformidad`
> del `design.md` debe citar la(s) skill(s) usada(s) de este índice.

## Cómo registrar una skill

Cada skill es un archivo en esta carpeta con frontmatter:

```markdown
---
name: nombre-de-la-skill
when: "Cuándo aplicar esta skill (el agente la elige por esto)"
---
# Título
Pasos + ejemplo real: `ruta/al/archivo.ext:NN`.
```

> **Apuntar a skills externas:** si tu proyecto ya tiene skills en otro lado
> (p. ej. `.claude/skills/`), este índice puede simplemente listarlas y enlazar
> a ellas en vez de duplicarlas; o apunta `rules.areas[].skills` a ese índice.

## Índice

| Skill | Cuándo usarla |
|-------|---------------|
| «add-skill» | «TODO: registra aquí tu primera skill de esta área» |
