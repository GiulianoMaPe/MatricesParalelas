# Evidencia del Sprint 6 — alcance Linux

- [Intento A](20261112T033150Z_fedora/entorno.json): 342 corridas OK, 57 grupos. Se conservan
  [observaciones](20261112T033150Z_fedora/observaciones.jsonl) y [resumen](20261112T033150Z_fedora/resumen.csv).
  Sus resultados C son exploratorios y quedan supersedidos por B al corregir
  la visibilidad de compilación; los Go se usan como diagnóstico.
- [Intento B, C controlado](20261112T035217Z_fedora/entorno.json): 144 corridas OK, 24 grupos,
  con base y candidata en unidades separadas, sin LTO. Se conservan
  [observaciones](20261112T035217Z_fedora/observaciones.jsonl) y [resumen](20261112T035217Z_fedora/resumen.csv).
- [Regresión portable](verificacion_20261112T032934Z/verificacion.json): comandos,
  códigos, reportes de compilador y salidas. ASan no se pudo enlazar por falta de
  libasan; los contratos sin sanitizador pasaron con -O0/-g y -O2.

Son 486 corridas brutas: 81 calentamientos y 405 medidas. Para las comparativas
se usa cada grupo C de B y cada grupo Go de A, sin mezclar observaciones entre
intentos ni escoger resultados por ser más rápidos. Las carpetas usan fecha UTC;
los lotes comenzaron el 11/11/2026 en Lima.

Este directorio no contiene la campaña Windows. C/OpenMP local no ejecuta MPI.
Cada intento conserva fuentes, hashes, entorno, plan y datos originales. Los
builds regenerables están ignorados. Repetir desde la raíz con
`python3 -B scripts/sprint06_lab.py --go /ruta/a/go`; para C solo, añadir
`--versions c_secuencial c_openmp_local`. Cada ejecución crea un intento nuevo.
