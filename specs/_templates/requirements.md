# Requirements — «name»

> Copia esta plantilla a `specs/<name>/requirements.md` y rellena los «...».
> Un requirement por bloque `## R<n>`, con UN solo DEBE, en un patrón EARS:
>
> | Patrón     | Plantilla                                                   |
> |------------|-------------------------------------------------------------|
> | Ubicuo     | `El sistema DEBE <acción>.`                                 |
> | Evento     | `CUANDO <disparador>, el sistema DEBE <acción>.`            |
> | Estado     | `MIENTRAS <estado>, el sistema DEBE <acción>.`              |
> | Opcional   | `DONDE <feature opcional>, el sistema DEBE <acción>.`       |
> | No deseado | `SI <evento no deseado> ENTONCES el sistema DEBE <acción>.` |
>
> Cada R<n> debe ser verificable por al menos un test concreto. Sin verbos
> blandos (podría/debería). `./check-spec.sh <name> --stage spec` valida esto.
> Tipos: bug → R1 es la reproducción («hoy hace X, DEBE hacer Y»);
> refactor → R1 es la invariante de conducta (sin conducta nueva).

## R1
CUANDO «disparador», el sistema DEBE «acción observable».

## R2
SI «evento no deseado» ENTONCES el sistema DEBE «acción (mensaje de error, exit code…)».
