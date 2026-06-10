# Design — «name»

> Copia esta plantilla a `specs/<name>/design.md` y rellena los «...».
> No es ingeniería desde primeros principios: apóyate en `docs/architecture.md`
> y `docs/<área>/conventions.md`. Documenta solo lo que esta feature decide.
> Tipos: bug → añade `## Causa raíz` (no el síntoma);
> refactor → añade `## Contrato público preservado`.

## Archivos
- «ruta/al/archivo» — «se crea | se modifica: qué cambia»

## Firmas nuevas
- «firma de función/clase/comando, o "ninguna"»

## Errores
- «excepciones/códigos de error que se reutilizan o añaden, o "ninguno"»

## Alternativa descartada
- «alternativa considerada» — descartada porque «razón».

## Conformidad
<!-- Obligatoria si el ítem tiene `area`. check-spec.sh verifica que las citas
     `archivo:línea` existan y el reviewer que las skills citadas estén en el
     SKILLS.md del área. -->
- Skills seguidas: «nombre-skill» (docs/«área»/skills/«skill».md)
- Patrón imitado: `«archivo»:«línea»` («qué estructura se imita»)
- Desvíos: «ninguno | justificación explícita de cada desvío»

## Aceptación observable
<!-- Obligatoria si alguna área del ítem tiene qa.kind != none. Prosa de caja
     negra, NO código: el agente qa la traduce a Playwright/curl. -->
- AC1 «criterio de aceptance»: el usuario/cliente hace «acción» y ve
  «resultado visible: texto en pantalla / código HTTP / cuerpo». Valida: R«n».
