# Solicitud de revisión S7 · I2→I3

Borrador preparado; todavía no enviado ni aprobado.

Se corrigió la entrega de I3 para conservar los casos individuales C secuencial,
C paralelo y Go paralelo en módulos separados, con un despacho común.
La aceptación Windows PowerShell 5.1 pasó: 81 casos I3, 23 I2 y 26 I4.
Se registraron 8 horas reales totales confirmadas por Giuliano.

Revisar scripts/bench_windows.ps1 y scripts/bench_go_secuencial.ps1, así como
la extracción de los módulos de I1/I2/I4. Ver evidencia en
resultados/diagnostico/s07-i03/aceptacion_windows_20261112/.
El rango público de Repetitions se conserva; Go secuencial exige cinco.

I2: confirmar la conservación de su caso y registrar revisión/aprobación real.
I5: confirmar la interfaz Invoke-GoSequentialMeasurement para el plan intercalado.
all continúa reservado a esa integración; los ensayos no son el piloto oficial.

El binario probado corresponde al HEAD 97f7729 y el medidor tiene cambios locales.
Después de publicar una nueva revisión/commit, recompilar Release y repetir
-WithExecutable si se requiere evidencia de la versión candidata congelada.