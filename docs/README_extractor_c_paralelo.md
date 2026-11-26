# Guion de exposición: extractor de C paralelo

Material breve para explicar `scripts/extract_s08_c_paralelo.ps1`. Los guiones
describen la herramienta y distinguen el diagnóstico de la campaña oficial.

## Diálogo 1: ¿Qué problema resuelve?

**Expositor:** En Sprint 8 teníamos una campaña integrada con resultados de las
cuatro versiones. ¿Cómo aislamos las mediciones del híbrido C sin copiar filas
equivocadas?

**Compañero:** Con `extract_s08_c_paralelo.ps1`. Lee los archivos de la campaña y
selecciona únicamente las filas cuya versión es `c_paralelo`.

**Expositor:** ¿El script vuelve a ejecutar la multiplicación o calcula de nuevo
los tiempos?

**Compañero:** No. Solo revisa la evidencia y copia las filas originales byte a
byte. No reconstruye ni modifica las mediciones.

**Expositor:** ¿Qué revisa antes de aceptar el lote?

**Compañero:** Comprueba el formato CSV, el plan y las repeticiones; contrasta P,
T y los hilos observados; verifica `OMP_NUM_THREADS`, `OMP_DYNAMIC=FALSE`, el
comando `mpiexec -n P`, la participación de los ranks, la bitácora y la
coherencia entre la salida de cada proceso y el CSV integrado.

**Expositor:** ¿Qué entrega?

**Compañero:** Una vista CSV solo de C paralelo y un manifiesto con hashes,
estado y anomalías. Así podemos revisar qué se extrajo y de qué campaña procede.

## Diálogo 2: Demostración y límites

**Expositor:** Voy a mostrar primero el uso de diagnóstico con un piloto
preservado. Este comando sirve para verificar una extracción y no la convierte
en resultado oficial:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\extract_s08_c_paralelo.ps1 `
    -CampaignDirectory .\resultados\piloto\s07_windows_20261117_reproduccion_06 `
    -Phase piloto -ExpectedSizes 256,512,1024 `
    -OutputPath .\resultados\diagnostico\s08_i02_piloto_s07\c_paralelo_piloto.csv `
    -ManifestPath .\resultados\diagnostico\s08_i02_piloto_s07\revision_i02.json
```

**Compañero:** ¿Qué resultado esperamos de esa ejecución?

**Expositor:** Una extracción identificada como piloto. La evidencia de Sprint 8
registra 108 filas, 18 grupos y cero anomalías críticas para ese diagnóstico.
Esas filas vienen del piloto S7, no sustituyen el CSV oficial de S8.

**Compañero:** ¿Y cómo se ejecutará para la campaña oficial?

**Expositor:** En la PC oficial, después de completar la campaña integrada con la
fase `oficial` y conservar los registros. El extractor valida también que la
candidata esté limpia, que las dimensiones sean 512, 1024 y 2048 y que los
grupos estén completos. Si todo pasa, el destino acordado es
`resultados/raw/c_paralelo.csv`.

**Compañero:** ¿Qué ocurre si falta un proceso, un hilo o una repetición?

**Expositor:** El manifiesto registra la anomalía y una falla crítica impide
acreditar el lote oficial. `-AllowIncomplete` permite conservar una vista
marcada `INCOMPLETE` para diagnóstico, pero termina con error y no certifica una
campaña válida.

**Compañero:** ¿Ya tenemos el CSV oficial de Sprint 8?

**Expositor:** No. El registro del sprint indica que el extractor y sus pruebas
están entregados, y que existe una extracción de diagnóstico del piloto S7. La
campaña oficial y `resultados/raw/c_paralelo.csv` siguen pendientes de ejecución
en la PC oficial.

## Referencias

- [Plan y handoff de Sprint 8 para I2](sprints/sprint-08-i02-plan.md)
- [Registro general de Sprint 8](sprints/sprint-08.md)
- [Extractor](../scripts/extract_s08_c_paralelo.ps1)
- [Pruebas del extractor](../tests/extract_s08_c_paralelo_test.ps1)
