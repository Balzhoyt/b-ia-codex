---
name: bia-finalizar-trabajo
description: Cierra la jornada con una bitácora local e híbrida basada exclusivamente en evidencia.
---

# Finalizar trabajo

Esta skill se activa con `finalizar trabajo` o `$bia-finalizar-trabajo`; ambas expresiones delegan este mismo workflow.

Reconstruya la jornada desde Git, OpenSpec, pruebas, verificaciones y Engram. La conversación sola no prueba finalización. Separe completado, en progreso, bloqueado, decisiones y siguiente paso. Evalúe ADRs significativos y nunca cree commits.

Consulte a Gentle AI para registrar el estado y `nextRecommended`, sin ejecutar una fase nueva.

Genere una instantánea idempotente en `docs/worklog/YYYY/YYYY-MM-DD.md` con `America/Mexico_City` y persista contenido canónicamente idéntico en `worklog/YYYY-MM-DD` de Engram. Ante fallo parcial, conserve `.bia/tmp/*.pending` y no declare el cierre.
