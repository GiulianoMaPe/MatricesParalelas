# Bitácora de experimentos — Sprint 8

## 24/11/2026

- Se completó el inventario técnico local de I6 en `docs/entorno/6-gerardo.md`.
- CPU local: Intel i3-12100F, 4 núcleos físicos y 8 lógicos.
- RAM física: 16 GB.
- Sistema: Windows 10 Pro for Workstations, build 26300.
- Plan activo: Economizador.
- Herramientas disponibles: Go 1.27.1, Git 2.51.2.1 y VS Code 1.147.0.
- No se detectaron cl.exe ni herramientas MS-MPI activas.
- La raíz descargada no contiene metadatos Git; no se pudo verificar un commit local.
- `go test` pasó para los módulos secuencial y paralelo de Go.
- Se generó `resultados/resumen/go_paralelo_resumen.csv` desde el CSV oficial ya recibido.
- No se alteró `resultados/raw/go_paralelo.csv` ni su manifiesto.

## 25/11/2026

- Se incorporaron los lotes de C secuencial y Go secuencial, el extractor de C paralelo y el control realizado en la PC de I1. Los CSV y manifiestos de las subcampañas permanecen en sus rutas de origen.
- El intento `s08_oficial_integrada_01` se interrumpió a las 15:34 (Lima) durante la corrida 61. Se conservaron las 60 observaciones completas y los archivos parciales del intento; no se usan para completar ni resumir la campaña oficial.
- Se inició `s08_oficial_integrada_02` en carpeta nueva conforme al protocolo de repetición completa. La candidata continúa siendo `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`, semilla 42 y PC `PCG1UL14N0`.
- El plan incluye N=512/1024/2048, W=1/2/4, 33 calentamientos y 165 mediciones en rondas alternadas. El timeout por corrida se fijó en 900 s por la duración observada de los intentos MPI con N=2048.
- El arnés registra carga y memoria disponible por corrida. La temperatura de CPU figura como no disponible. El estado final, la extracción de C paralelo y el inventario SHA-256 quedan sujetos a la verificación del segundo intento.

## Manifiesto de resultados y congelación de `resultados/raw/` (I8 · Roberto · 25/11/2026)

### Estado de congelación de `resultados/raw/`

A fecha **25/11/2026**, queda **congelada de forma inmutable** la porción oficial verificada de `resultados/raw/` correspondiente a **3 de las 4 versiones** del estudio bajo la candidata congelada S7→S8 (`97ccc981e9068d8ec0753cd8a4b7572a6bece34d`) en el host oficial `PCG1UL14N0` con semilla `42`:

- **Lotes CSV oficiales congelados (3/4):**
  - `resultados/raw/c_secuencial.csv` + `resultados/raw/c_secuencial.manifest.json`
  - `resultados/raw/go_secuencial.csv`
  - `resultados/raw/go_paralelo.csv` + `resultados/raw/go_paralelo.manifest.json`
- **Carpetas de subcampañas fuente oficiales congeladas:**
  - `resultados/raw/s08_i03_go_secuencial_03/` (`COMPLETE`, `VERIFIED`, 72/72 corridas)
  - `resultados/raw/s08_i04_go_paralelo_01/` (`COMPLETE`, `VERIFIED`, 108/108 corridas)
- **Lote pendiente (1/4):**
  - `resultados/raw/c_paralelo.csv` **NO existe aún**. Su generación y sellado quedan pendientes de la finalización, verificación y extracción oficial de la campaña integrada `s08_oficial_integrada_02` en `PCG1UL14N0`.

### Cadena de trazabilidad `commit -> binario/fuentes -> campaña -> CSV`

La auditoría de integridad de extremo a extremo verificó los cuatro eslabones de la cadena experimental para los lotes congelados:

1. **Commit y código fuente (`commit -> fuentes`):**
   - Commit oficial congelado (candidata S7→S8): `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.
   - En ambas campañas fuente (`s08_i03_go_secuencial_03` y `s08_i04_go_paralelo_01`), `source-hashes.json` registra los mismos **170 archivos fuente** con idéntico SHA-256 (`f7f593eb329a83af5c86d08d1fdae545dfe92a9a78635d30591d9de3d59692d6`), acreditando que las ejecuciones partieron exactamente del mismo estado del código.
2. **Entorno y estado de ejecución (`fuentes -> campaña`):**
   - Ambos `entorno.json` acreditan `git.dirty=false`, `phase=oficial`, `dry_run=false`, host `PCG1UL14N0` y commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d`.
   - `s08_i03_go_secuencial_03/estado.json`: `COMPLETE` (72/72 corridas, `wall_s=4625.56`, finalizó `2026-11-17T21:56:02Z`).
   - `s08_i04_go_paralelo_01/estado.json`: `COMPLETE` (108/108 corridas, `wall_s=5382.20`, finalizó `2026-11-19T21:07:00Z`).
   - `s08_i03_go_secuencial_03/verificacion.json`: `VERIFIED` (12 grupos, `data_sha256` = `6c972dc764bb3aef41e3c1a3cd3f091a7fc69f8925c7c0660e1cc14fe61849dc`).
   - `s08_i04_go_paralelo_01/verificacion.json`: `VERIFIED` (18 grupos, `data_sha256` = `2d8a9222ec26ae34aab5ecccd07d884d2f5d21411a4a04b8aefd565328776ce4`).
3. **Coincidencia exacta fila a fila e invariantes (`campaña -> CSV`):**
   - `resultados/raw/c_secuencial.csv`: 18 filas (3 warmups + 15 medidas, `N=512/1024/2048`), coincidencia **18/18 filas idénticas** contra `s08_i04_go_paralelo_01/mediciones.csv`. Codificación UTF-8 sin BOM (CRLF). El campo `os_version` reporta `Windows 10 Pro build 26300.9711` (correspondiente al kernel NT de Windows 11; conservado sin alterar el CSV crudo). `c_secuencial.manifest.json` (`status=VERIFIED_OFFICIAL`) coincide exactamente con el SHA-256 del CSV y las medianas/dispersiones calculadas.
   - `resultados/raw/go_secuencial.csv`: 18 filas (3 warmups + 15 medidas, `N=512/1024/2048`, `workers=1`, `gomaxprocs=1`), coincidencia **18/18 filas idénticas** contra `s08_i03_go_secuencial_03/mediciones.csv`.
   - `resultados/raw/go_paralelo.csv`: 54 filas (9 warmups + 45 medidas, `N=512/1024/2048`, `W=1/2/4`, `gomaxprocs=W`), coincidencia **54/54 filas idénticas** contra `s08_i04_go_paralelo_01/mediciones.csv`. `go_paralelo.manifest.json` (`status=VERIFIED`) coincide exactamente con los SHA-256 de `go_paralelo.csv`, `mediciones.csv` y `entorno.json`.
   - **Invariantes globales:** esquema de **20 columnas**, `validation_status=OK` y `0 < kernel_s <= total_s` en el **100% de las filas auditadas** (**0 violaciones**).

### Manifiesto de integridad SHA-256 (`resultados/raw/`)

| Ruta en `resultados/raw/` | Versión / Artefacto | Campaña fuente | Filas (total / warmup / medidas) | Tamaño (bytes) | SHA-256 | Invariantes | Estado |
| --- | --- | --- | --- | ---: | --- | --- | --- |
| `c_secuencial.csv` | `c_secuencial` (CSV oficial) | `s08_i04_go_paralelo_01` | 18 (3 / 15) | 4487 | `0f82f9fde140c6e928afb0476392e22181dedee534f42d7d20b3271973b3c854` | `20 col`, `validation_status=OK`, `0 < kernel_s <= total_s` (18/18) | Congelado |
| `c_secuencial.manifest.json` | Manifiesto `VERIFIED_OFFICIAL` | `s08_i04_go_paralelo_01` | N/A | 3224 | `dd4820268cf373c33c45e384508d125f5d06ad13f267fe542314e58077840bac` | SHA-256 y stats por `N` coincidentes | Congelado |
| `go_secuencial.csv` | `go_secuencial` (CSV oficial) | `s08_i03_go_secuencial_03` | 18 (3 / 15) | 4270 | `581fb5db9f78a2790f519473d791886ad18beb02adbbfbe0711e088abb494fd5` | `20 col`, `validation_status=OK`, `0 < kernel_s <= total_s` (18/18) | Congelado |
| `go_paralelo.csv` | `go_paralelo` (CSV oficial) | `s08_i04_go_paralelo_01` | 54 (9 / 45) | 12370 | `11b68f7ee37979ee35b621f0e03433b3635a1e01c3bad87f756dc62d0f14bd4c` | `20 col`, `validation_status=OK`, `0 < kernel_s <= total_s` (54/54) | Congelado |
| `go_paralelo.manifest.json` | Manifiesto `VERIFIED` | `s08_i04_go_paralelo_01` | N/A | 12504 | `2dfe4c1314ecb1ea0d07838cf03b4b17061a43ffcdbc00556c9bae9a79ce7686` | SHA-256 de CSV, `mediciones.csv` y `entorno.json` coincidentes | Congelado |
| `c_paralelo.csv` | `c_paralelo` (CSV oficial) | Pendiente (`s08_oficial_integrada_02`) | Pendiente | Pendiente | Pendiente de campaña integrada | Pendiente | **Pendiente (no existe aún)** |
| `s08_i03_go_secuencial_03/mediciones.csv` | Fuente subcampaña Go secuencial | `s08_i03_go_secuencial_03` | 72 datos | 16915 | `6c972dc764bb3aef41e3c1a3cd3f091a7fc69f8925c7c0660e1cc14fe61849dc` | `20 col`, `validation_status=OK`, `0 < kernel_s <= total_s` (72/72) | Congelado |
| `s08_i03_go_secuencial_03/verificacion.json` | Verificación `VERIFIED` (12 grupos) | `s08_i03_go_secuencial_03` | N/A | 585 | `21d1d70ea65ad1c2faf83ba2794f9a6ab1b474d3a2d81eb343b49508fae8e18b` | `data_sha256` = `mediciones.csv` | Congelado |
| `s08_i03_go_secuencial_03/source-hashes.json` | Hashes de 170 archivos fuente | `s08_i03_go_secuencial_03` | N/A | 18163 | `f7f593eb329a83af5c86d08d1fdae545dfe92a9a78635d30591d9de3d59692d6` | Coincide con `s08_i04_go_paralelo_01` | Congelado |
| `s08_i03_go_secuencial_03/entorno.json` | Entorno (`git.dirty=false`, `phase=oficial`) | `s08_i03_go_secuencial_03` | N/A | 50605 | `0f4854fd37e5105abf5ea30b89fceb5af348d78aa56822cb9823a97a5d8662e6` | Commit y host `PCG1UL14N0` válidos | Congelado |
| `s08_i03_go_secuencial_03/estado.json` | Estado `COMPLETE` (72/72, `wall_s=4625.56`) | `s08_i03_go_secuencial_03` | N/A | 157 | `a16046574cb3cab9280e2954ac58a50e40052954bb08edaf7ebeed0580363521` | Finalizó `2026-11-17T21:56:02Z` | Congelado |
| `s08_i04_go_paralelo_01/mediciones.csv` | Fuente subcampaña Go paralelo / C seq | `s08_i04_go_paralelo_01` | 108 datos | 25033 | `2d8a9222ec26ae34aab5ecccd07d884d2f5d21411a4a04b8aefd565328776ce4` | `20 col`, `validation_status=OK`, `0 < kernel_s <= total_s` (108/108) | Congelado |
| `s08_i04_go_paralelo_01/verificacion.json` | Verificación `VERIFIED` (18 grupos) | `s08_i04_go_paralelo_01` | N/A | 584 | `01bc227350d3fec62ddf52f2380fd0d9cdbde8eb3b1854277308e5594da3c1f4` | `data_sha256` = `mediciones.csv` | Congelado |
| `s08_i04_go_paralelo_01/source-hashes.json` | Hashes de 170 archivos fuente | `s08_i04_go_paralelo_01` | N/A | 18163 | `f7f593eb329a83af5c86d08d1fdae545dfe92a9a78635d30591d9de3d59692d6` | Coincide con `s08_i03_go_secuencial_03` | Congelado |
| `s08_i04_go_paralelo_01/entorno.json` | Entorno (`git.dirty=false`, `phase=oficial`) | `s08_i04_go_paralelo_01` | N/A | 50964 | `edfffca513b92673ecc6e6d34991894b861b43a88dd7e806d190b4a090f61dc7` | Commit y host `PCG1UL14N0` válidos | Congelado |
| `s08_i04_go_paralelo_01/estado.json` | Estado `COMPLETE` (108/108, `wall_s=5382.20`) | `s08_i04_go_paralelo_01` | N/A | 153 | `39b22581b4bdf7a7f8b9f90cc3bb8d30b6d8937627c10078e085c0008524f21f` | Finalizó `2026-11-19T21:07:00Z` | Congelado |

### Separación de evidencia de control independiente y resúmenes provisionales

Para evitar contaminación entre datos oficiales de comparación y artefactos auxiliares o de otro hardware, se mantiene separación estricta por directorio:

- **Control independiente (`resultados/control/s08_i01_c_secuencial_control/`, NO mezclado en `raw`):**
  - `c_secuencial_control.csv`: 9084 bytes | SHA-256: `8d7de5634677d04605839096a6785a02aa6604fe527edc4b559b3dcf02ae7c75` | 18 filas en host `YESSLY-TB14G9`, commit `5a54ede1dc6371fc570ee12fa4560d78df7f4b0d`, codificación UTF-16 LE con BOM generada por redirección de PowerShell 5.1.
  - `c_secuencial_control.manifest.json`: 3401 bytes | SHA-256: `1da80d3f37c25cfe4c354ab106aa57ecc788bedb9c399a1c960e08b33709e05e`.
  - Alcance: evidencia de control externo; no participa en los cálculos ni comparaciones oficiales de `PCG1UL14N0`.
- **Resúmenes provisionales (`resultados/resumen/`, cobertura parcial de 9 grupos de `go_paralelo`):**
  - `resultados/resumen/resumen_provisional.csv`: 4242 bytes | SHA-256: `0064f7c32659f8aff9e2a394dd4a45f3a747cb096a56bd758ece61354225100b`.
  - `resultados/resumen/dispersion_report.csv`: 3279 bytes | SHA-256: `9cd93dd0e51a8f3009c2c06dff5e38971f520cac315a302869dad2136c12b6a4`.
  - `resultados/resumen/go_paralelo_resumen.csv`: 4161 bytes | SHA-256: `90cd445aee8f956d8850013fe62f2c227e847c78534c2d4aa5d4beeca0c7ad59`.
  - Alcance: reflejan únicamente los 9 grupos de `go_paralelo` al momento de su generación y deberán regenerarse en Sprint 9 una vez sellados los 4 lotes completos.

### Política de inmutabilidad y protocolo de sellado final para `c_paralelo.csv`

1. **Reglas de no edición sobre `resultados/raw/`:**
   - Ningún archivo CSV, manifiesto o carpeta de campaña ya congelado en `resultados/raw/` (`c_secuencial.csv`, `go_secuencial.csv`, `go_paralelo.csv`, `s08_i03_go_secuencial_03/`, `s08_i04_go_paralelo_01/`) puede ser editado, reordenado, filtrado, recodificado ni sobrescrito.
   - Los intentos interrumpidos (como `s08_oficial_integrada_01`) se conservan intactos para diagnóstico y nunca se concatenan ni mezclan con lotes oficiales.
   - Cualquier corrida en hardware distinto a `PCG1UL14N0` permanece fuera de `resultados/raw/` (en `resultados/control/` o `resultados/diagnostico/`).
2. **Protocolo de sellado cuando cierre `s08_oficial_integrada_02`:**
   - Verificar en `resultados/raw/s08_oficial_integrada_02/` que `estado.json` indique `COMPLETE` (sin truncamientos), `verificacion.json` indique `VERIFIED`, `entorno.json` confirme `git.dirty=false`, `phase=oficial`, `dry_run=false`, host `PCG1UL14N0`, semilla `42` y commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d` (junto con `source-hashes.json`).
   - Ejecutar `scripts/extract_s08_c_paralelo.ps1` sobre `resultados/raw/s08_oficial_integrada_02` exigiendo `-Phase oficial -ExpectedCommit 97ccc981e9068d8ec0753cd8a4b7572a6bece34d` para producir `resultados/raw/c_paralelo.csv` y su manifiesto en UTF-8 sin BOM, validando esquema de 20 columnas, `validation_status=OK`, `0 < kernel_s <= total_s` e igualdad exacta con las filas correspondientes de `mediciones.csv`.
   - Registrar los tamaños en bytes y los hashes SHA-256 finales de `c_paralelo.csv`, su manifiesto y los artefactos de `s08_oficial_integrada_02` en esta bitácora, completando así la congelación total (4/4 versiones) previa al análisis de Sprint 9.
