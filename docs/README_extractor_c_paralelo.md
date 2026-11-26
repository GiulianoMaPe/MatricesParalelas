# Guiones de exposición: extractor de C paralelo

Dos exposiciones individuales para presentar `scripts/extract_s08_c_paralelo.ps1`.

## Exposición 1: Propósito y funcionamiento

En Sprint 8 necesitábamos separar las mediciones del híbrido C de una campaña
integrada que también contiene resultados de las otras versiones. Para eso
preparamos `extract_s08_c_paralelo.ps1`.

El extractor lee la evidencia de una campaña y selecciona únicamente las filas
cuya versión es `c_paralelo`. No vuelve a ejecutar la multiplicación ni calcula
de nuevo los tiempos: valida la información y copia las filas originales byte a
byte.

Antes de aceptar el lote, revisa el formato CSV, el plan y las repeticiones.
También contrasta la cantidad de procesos y los hilos solicitados y observados;
verifica `OMP_NUM_THREADS`, `OMP_DYNAMIC=FALSE`, el comando `mpiexec -n P`, la
participación de los ranks, la bitácora y la coherencia entre la salida de cada
proceso y el CSV integrado.

Como resultado, genera una vista CSV solo de C paralelo y un manifiesto con
hashes, estado y anomalías. Esto permite rastrear qué se extrajo y de qué
campaña procede.

## Exposición 2: Demostración y alcance

Voy a mostrar el uso de diagnóstico con un piloto preservado. Este comando
verifica una extracción, pero no convierte el piloto en resultado oficial:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_c_paralelo.ps1 `
    -CampaignDirectory .\resultados\piloto\s07_windows_20261117_reproduccion_06 `
    -Phase piloto -ExpectedSizes 256,512,1024 `
    -OutputPath .\resultados\diagnostico\s08_i02_piloto_s07\c_paralelo_piloto.csv `
    -ManifestPath .\resultados\diagnostico\s08_i02_piloto_s07\revision_i02.json
```

La salida esperada es una extracción identificada como piloto. El registro de
Sprint 8 conserva 108 filas, 18 grupos y cero anomalías críticas en ese
diagnóstico. Esas mediciones proceden del piloto S7, por lo que no sustituyen el
CSV oficial de S8.

Para la campaña oficial, el extractor se ejecuta en la PC oficial después de
completar la campaña integrada y conservar sus registros. En esa fase también
valida que la candidata esté limpia, que se hayan medido las dimensiones 512,
1024 y 2048 y que los grupos estén completos. Si las verificaciones pasan, el
resultado va a `resultados/raw/c_paralelo.csv`.

Si falta un proceso, un hilo o una repetición, el manifiesto registra la
anomalía y una falla crítica impide acreditar el lote oficial. La opción
`-AllowIncomplete` conserva una vista marcada `INCOMPLETE` para diagnóstico,
pero termina con error y no certifica una campaña válida.

Actualmente están entregados el extractor, sus pruebas y una extracción de
diagnóstico del piloto S7. La campaña oficial y
`resultados/raw/c_paralelo.csv` siguen pendientes de ejecución en la PC oficial.

## Referencias

- [Plan y handoff de Sprint 8 para I2](sprints/sprint-08-i02-plan.md)
- [Registro general de Sprint 8](sprints/sprint-08.md)
- [Extractor](../scripts/extract_s08_c_paralelo.ps1)
- [Pruebas del extractor](../tests/extract_s08_c_paralelo_test.ps1)
