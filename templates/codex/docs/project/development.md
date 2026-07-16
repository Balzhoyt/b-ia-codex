# Desarrollo

Registre requisitos locales, comandos reales, convenciones y procedimiento de adopción. No documente comandos no ejecutados ni dependencias no verificadas.

Las skills B-IA se instalan localmente bajo `.agents/skills/` mediante el manifiesto de adopción.

## Requisitos del consumidor

La adopción valida explícitamente `git`, `codex`, `gentle-ai`, `engram`, `jq`, `sha256sum`, `sync`, `stat`, `id`, `date`, `realpath` y `sleep`, porque instala y comprueba el conjunto completo de integración, incluido el registrador TDD pasivo. El preflight ejecutado de forma independiente solo exige `jq`, que utiliza para leer JSON estructurado sin combinar campos de objetos o niveles distintos. Cada operación falla con código `3` únicamente cuando falta una dependencia que esa operación consume.

## Recuperación confiable

Al adoptar, conserve la ruta del registro y el valor de la línea `SHA-256 esperado para rollback:`. Guarde ese digest fuera de `.bia-backup` y del repositorio consumidor; un archivo lateral dentro del backup comparte la misma frontera modificable y no autentica el registro. Sin ese digest, el rollback falla de forma segura y no modifica el consumidor.

Capture la salida completa y separe sus dos valores antes de guardar el digest en el sistema confiable elegido:

```bash
adoption_output="$("$template_root/templates/codex/.bia/adoption/adopt.sh" --root "$template_root" --consumer "$PWD" --manifest "$manifest")"
record="${adoption_output#Adopción completada: }"
record="${record%%$'\n'*}"
record_sha256="${adoption_output##*SHA-256 esperado para rollback: }"
.bia/adoption/rollback.sh --consumer "$PWD" --record "$record" --record-sha256 "$record_sha256"
```
