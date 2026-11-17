import csv
import datetime as dt
import json
import math
import pathlib
import runpy
import shutil

script_dir=pathlib.Path(__file__).resolve().parent
runpy.run_path(str(script_dir/'comparar_campanas.py'),run_name='__main__')
base=pathlib.Path('resultados/piloto')
out=base/'s07_windows_20261117_cierre_06'
result=json.loads((out/'verificacion_cruzada.json').read_text(encoding='utf-8'))
def timestamp(value):
    return dt.datetime.fromisoformat(value.strip().replace('Z','+00:00'))
thermal=[]
for name in result['campaigns']:
    folder=base/name
    start=timestamp(json.loads((folder/'entorno.json').read_text(encoding='utf-8-sig'))['started_at_utc'])
    end=timestamp(json.loads((folder/'estado.json').read_text(encoding='utf-8-sig'))['ended_at_utc'])
    with (folder/'monitor_externo/gpu.csv').open(encoding='utf-8',newline='') as stream:
        rows=list(csv.DictReader(stream,skipinitialspace=True))
    measured=[row for row in rows if start<=timestamp(row['sample_utc'])<=end]
    assert len(measured)>=2,'No GPU samples during measurement: '+name
    values=[float(row['gpu_temperature_c']) for row in measured]
    thermal.append({'campaign_id':name,'gpu_samples_during_measurement':len(measured),
        'gpu_temperature_c_min':min(values),'gpu_temperature_c_max':max(values),
        'cpu_temperature_available':False,'cpu_reason':'User chose GPU only; no CPU driver installed.'})
result['gpu_monitoring']=thermal
result['checks']['gpu_samples_during_each_measurement']=True
(out/'verificacion_cruzada.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
(out/'aceptacion_responsable.json').write_text(json.dumps({'status':'PENDING_REVIEW_AFTER_CURRENT_ENVIRONMENT_REPEAT',
    'commit':result['commit'],'campaigns':result['campaigns'],'cpu_temperature_available':False,
    'gpu_monitoring_available':True,'human_acceptance':False},indent=2)+'\n',encoding='utf-8')
hours=math.ceil((max(value['suggested_reservation_seconds'] for value in result['estimates'])+1800)/1800)*1800
start=dt.datetime.fromisoformat('2026-11-18T09:00:00-05:00')
reservation={'status':'PLANNED_BY_OWNER_DELEGATION_PENDING_S7_ACCEPTANCE','timezone':'America/Lima',
    'start':start.isoformat(),'end':(start+dt.timedelta(seconds=hours)).isoformat(),'reserved_seconds':hours,
    'projection_not_s8_measurement':True}
(out/'reserva_maquina.json').write_text(json.dumps(reservation,indent=2)+'\n',encoding='utf-8')
with (out/'comparacion_reproduccion.csv').open(encoding='utf-8', newline='') as stream:
    comparison_rows=list(csv.DictReader(stream))
max_change=max(comparison_rows,key=lambda row:abs(float(row['relative_change_percent'])))
lines=['# Repetición de S7 en Windows: resultados técnicos','',
    '**Estado:** ambas campañas completas y verificadas; falta la revisión y conformidad final del responsable.',
    '', 'Commit medido: `'+result['commit']+'`.', '',
    'Cada campaña registró 198/198 observaciones válidas y 33 grupos completos. Las 13 comprobaciones cruzadas son verdaderas; los logs de aceptación y verificación están en cada campaña. Los datos se conservan como conjuntos separados, sin filtrar atípicos ni combinarlos.', '',
    '## Condiciones observadas','',
    'El responsable autorizó dejar activas las aplicaciones existentes. Se guardó una instantánea de ventanas al inicio; Zoom/navegadores se supervisaron cada cinco segundos, la carga CPU se registró por corrida y la GPU cada cinco segundos. No se afirma que el equipo estuviera inactivo ni se atribuyen diferencias a una aplicación.', '']
for row, condition, gpu in zip(result['campaigns'], result['conditions'], thermal):
    lines.append('- **'+row+':** 198/198, 33 grupos; carga CPU '+str(condition['cpu_load_percent_min'])+'–'+str(condition['cpu_load_percent_max'])+'%; memoria libre mínima '+f"{condition['minimum_free_memory_kib']/1024:.0f}"+' MiB; GPU '+str(gpu['gpu_temperature_c_min'])+'–'+str(gpu['gpu_temperature_c_max'])+' °C ('+str(gpu['gpu_samples_during_measurement'])+' muestras). Procesos visibles observados: '+', '.join(condition['observed_app_process_names'])+'.')
direction='disminuyó' if float(max_change['relative_change_percent']) < 0 else 'aumentó'
lines+=['', 'La CPU no tiene lectura térmica, según la decisión del responsable. La temperatura GPU no determina la temperatura ni estabilidad térmica de la CPU.', '',
    '## Comparación y reserva S8','',
    'Cambio absoluto mediano entre medianas: '+f"{result['median_absolute_relative_change_percent']:.2f}"+'%. Mayor cambio: '+f"{abs(float(max_change['relative_change_percent'])):.2f}"+'% ('+direction+') en '+max_change['version']+', N='+max_change['n']+', '+max_change['configuration']+'.',
    'Proyección S8 para N=2048: '+f"{result['s8_matrix_footprint_estimate_mib']} MiB"+' estimados para matrices (sin runtime ni stacks). Reserva provisional por delegación: '+reservation['start']+' a '+reservation['end']+' (hora de Lima); es una proyección inicial, no una medición de S8.', '',
    'Intentos previos excluidos del análisis: `_03` se interrumpió al reaparecer Zoom; `_04` no midió porque quedó un lock de prueba huérfano. Ambos se conservaron aparte.', '',
    'Ver `verificacion_cruzada.json`, `comparacion_reproduccion.csv`, los logs individuales `monitor_externo/`, `aceptacion_responsable.json` y `reserva_maquina.json`.']
(out/'README.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
for name in ['comparar_campanas.py','crear_informe.py','repetir_s07.ps1','registrar_gpu.ps1']:
    shutil.copyfile(script_dir/name,out/name)
print('New attempts compared; GPU samples correlated with actual measurement; human review pending.')
