# Arquitectura — Qué significa "hacer un buen trabajo"

> Este documento define el estándar de calidad. Los agentes revisores
> evalúan código contra este archivo. Si no está aquí, no es un requisito.
>
> **Plantilla:** completa las secciones marcadas con `«...»` con la arquitectura
> real de tu proyecto antes de empezar a implementar features.

## Principios

1. **Capas claras.** Define las capas de tu proyecto y respétalas. No
   introduzcas capas adicionales (servicios, repositorios, ORMs) hasta que
   haya una razón concreta documentada en `feature_list.json`.

   Capas de este proyecto:
   - `«capa»` — «responsabilidad».
   - `«capa»` — «responsabilidad».

2. **Dependencias bajo control.** Si una feature requiere una dependencia
   externa, primero se discute (estado `blocked`). Mantén la superficie de
   dependencias mínima y justificada.

3. **Errores explícitos.** Las funciones que pueden fallar (recurso no existe,
   datos corruptos) lanzan errores nombrados, no devuelven `null`/`undefined`
   silenciosos.

4. **Inmutabilidad por defecto.** Modelos de dominio inmutables: modificar =
   crear una nueva instancia. Evita mutar estado compartido.

5. **Operaciones de IO seguras.** Toda escritura que pueda corromper datos se
   hace de forma atómica (escribir a temporal + renombrar). Nunca dejes un
   recurso a medio escribir.

## Flujo de datos

```
«describe aquí el flujo de datos de tu proyecto:
 quién entra, qué transformaciones ocurren y dónde se persiste»
```

## Qué NO hacer

- No usar la salida estándar para errores. Usa `stderr` y exit code != 0.
- No mezclar IO con lógica de dominio en el mismo módulo.
- No leer/escribir el recurso en cada operación dentro de un bucle.
  Carga al inicio, modifica en memoria, guarda al final.
- No añadir un sistema de configuración prematuro. Pasa las rutas/parámetros
  explícitamente o usa una constante por defecto.
