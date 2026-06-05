# Convenciones de código (genéricas)

> Homogeneidad extrema. La IA predice mejor cuando el repositorio se parece
> a sí mismo en todas partes.
>
> **Este archivo define principios agnósticos de lenguaje.** Lo específico de
> cada lenguaje/framework (runtime, build, runner de tests, imports, estilo
> concreto) vive en `docs/<área>/conventions.md`. Cuando un principio de aquí
> y la convención de un área choquen, **manda la del área**.

## Principios

- **Homogeneidad.** Imita el código existente del área antes de inventar un
  estilo nuevo. Mismo patrón en todas partes > preferencia personal.
- **Límites públicos explícitos.** Toda función/clase/módulo exportado declara
  su contrato (tipos/firmas/documentación según el lenguaje lo permita).
- **Modela el dominio.** Representa los conceptos del dominio con tipos/estructuras
  nombradas, no con datos sueltos sin forma.
- **Errores explícitos.** Lo que puede fallar (recurso inexistente, datos
  corruptos) lanza/retorna un error nombrado, no un valor silencioso ambiguo.
- **Inmutabilidad por defecto.** Evita mutar estado compartido; prefiere crear
  nuevas instancias cuando sea razonable en el lenguaje.
- **Mínima superficie de dependencias.** Una dependencia nueva se discute
  (estado `blocked`) antes de añadirse.

## Nombres

- Sé consistente con la convención del área (`camelCase`, `snake_case`,
  `PascalCase`, etc.). No mezcles convenciones dentro de la misma área.
- Nombres descriptivos que hagan innecesario el comentario.

## Tests

- **Un test por unidad lógica**, ubicado donde el área lo establezca
  (`docs/<área>/conventions.md`).
- Los tests verifican **resultados concretos**, no solo "que no lanza error".
- Evita mockear lo que puedas ejercitar de verdad (filesystem, etc.): usa
  recursos temporales reales y límpialos.
- Se ejecutan con el comando `verify` del área (`rules.areas[].verify`).

## Comentarios

Por defecto **no** se escriben. Solo cuando explican un *por qué* no obvio
(workaround documentado, invariante sutil). Los nombres hacen el resto.

## Específico por área

Cada área documenta en `docs/<área>/conventions.md`:

- Lenguaje + versión + gestor de paquetes / build.
- Estructura de carpetas (dónde vive el código y los tests del área).
- Estilo concreto (indentación, comillas, longitud de línea, linter/formatter).
- Manejo de errores idiomático del lenguaje.
- El comando `verify` exacto.
