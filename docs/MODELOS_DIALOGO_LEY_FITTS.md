# Modelos de diálogo y Ley de Fitts — Lulistrack 3.0

## Objetivo
Reducir la incertidumbre durante el flujo de entrega y facilitar la interacción del repartidor en movimiento mediante respuestas consistentes del sistema y objetivos táctiles accesibles.

## 1. Modelos de diálogo

La aplicación utiliza un componente reutilizable en `lib/widgets/lulistrack_dialog.dart` para conservar el mismo lenguaje visual y de interacción.

| Modelo | Cuándo se utiliza | Respuesta del sistema |
|---|---|---|
| Confirmación | Antes de registrar definitivamente una entrega | Explica la consecuencia y ofrece Confirmar / Cancelar |
| Advertencia | Falta firma, fotografía o información requerida | Indica qué debe corregirse |
| Error | No se pudo guardar evidencia o completar una operación | Explica el problema y ofrece reintentar |
| Éxito | Una acción termina correctamente | Confirma el resultado sin dejar dudas |
| Feedback breve | Acciones secundarias como capturar una foto | Mensaje temporal y respuesta háptica |

### Flujo de confirmación de entrega
1. El repartidor revisa fotografía y firma.
2. Pulsa **Confirmar entrega**.
3. El diálogo explica que la evidencia se guardará localmente y se intentará sincronizar.
4. Si confirma, comienza el guardado y sincronización.
5. La pantalla de recibo comunica si la entrega quedó sincronizada o pendiente.

Cancelar cierra el diálogo y conserva al usuario en la revisión; no se inicia el envío.

## 2. Ley de Fitts

La Ley de Fitts modela el tiempo de movimiento hacia un objetivo:

\[
T = a + b\log_2\left(1 + \frac{D}{W}\right)
\]

- **T:** tiempo estimado para alcanzar el objetivo.
- **D:** distancia desde la posición inicial hasta el objetivo.
- **W:** ancho efectivo del objetivo en la dirección del movimiento.
- **a y b:** constantes empíricas que dependen del usuario, dispositivo y contexto.

La distancia \(D\) se mide desde la posición inicial del dedo hasta el centro del objetivo; \(W\) es el ancho efectivo del objetivo en la dirección del movimiento. El índice de dificultad es:

\[
ID = \log_2\left(1 + \frac{D}{W}\right)
\]

Al aumentar el ancho del objetivo (W) o reducir la distancia (D), disminuye el índice de dificultad y, en el modelo, el tiempo esperado de selección.

## 3. Aplicación en la interfaz

Se centralizan los criterios en `lib/widgets/fitts_touch_target.dart`:

- 48 logical px como mínimo para objetivos táctiles.
- 56 logical px para acciones principales del flujo de entrega.
- Botones principales de ancho completo en la zona inferior, cerca del alcance natural del pulgar.
- Acciones críticas separadas visualmente de acciones secundarias para reducir errores.
- Diálogos con botones grandes, separados y etiquetas explícitas.

### Ejemplos en Lulistrack

| Pantalla | Objetivo | Aplicación |
|---|---|---|
| Evidencia fotográfica | Continuar con entrega | Acción primaria de 56 px |
| Firma digital | Guardar firma | Acción primaria de 56 px |
| Revisión | Confirmar entrega | Acción primaria de 56 px y confirmación explícita |
| Diálogos | Confirmar / cancelar | Controles de al menos 48 px de alto |

## 4. Ejemplo matemático ilustrativo

Supóngase una interacción táctil hipotética con constantes de ejemplo: `a = 0.20 s` y `b = 0.10 s`.

- Objetivo pequeño: `D = 300 px`, `W = 40 px`.
- Objetivo amplio: `D = 180 px`, `W = 56 px`.

\[
T_1=0.20+0.10\log_2(1+300/40)\approx0.509\,s
\]

\[
T_2=0.20+0.10\log_2(1+180/56)\approx0.408\,s
\]

En este ejemplo teórico, acercar y ampliar el objetivo reduce el tiempo estimado aproximadamente 20%. Los valores de `a`, `b`, `D` y `W` son ilustrativos; no representan mediciones realizadas con usuarios de Lulistrack.

## 5. Criterios de evaluación

Para validar la propuesta con usuarios se recomienda medir:
- Tiempo desde que se presenta la acción hasta que se selecciona.
- Porcentaje de pulsaciones equivocadas.
- Veces que el usuario cancela o repite una acción.
- Comprensión de los mensajes de confirmación, advertencia y error.

**Nota:** la implementación aplica principios de diseño derivados de la Ley de Fitts. Para afirmar una mejora cuantitativa real, se requiere una prueba de usabilidad con tareas y participantes, comparando la versión anterior y la versión mejorada.
