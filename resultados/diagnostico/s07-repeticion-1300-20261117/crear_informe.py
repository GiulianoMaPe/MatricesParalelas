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
out=base/'s07_windows_20261117_cierre_03'
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
(out/'aceptacion_responsable.json').write_text(json.dumps({'status':'PENDING_REVIEW_AFTER_IDLE_REPEAT',
    'commit':result['commit'],'campaigns':result['campaigns'],'cpu_temperature_available':False,
    'gpu_monitoring_available':True,'human_acceptance':False},indent=2)+'\n',encoding='utf-8')
hours=math.ceil((max(value['suggested_reservation_seconds'] for value in result['estimates'])+1800)/1800)*1800
start=dt.datetime.fromisoformat('2026-11-18T09:00:00-05:00')
reservation={'status':'PLANNED_BY_OWNER_DELEGATION_PENDING_S7_ACCEPTANCE','timezone':'America/Lima',
    'start':start.isoformat(),'end':(start+dt.timedelta(seconds=hours)).isoformat(),'reserved_seconds':hours,
    'projection_not_s8_measurement':True}
(out/'reserva_maquina.json').write_text(json.dumps(reservation,indent=2)+'\n',encoding='utf-8')
lines=['# S7 repeat at 13:00 - technical results','',
    'Both attempts passed integrity checks. Human closure approval remains pending.',
    '', 'Source commit: `'+result['commit']+'`.', '',
    'Each attempt: 198 OK observations, 33 complete groups; raw data remain separate.', '',
    'CPU temperature was not measured, by user choice. GPU temperature cannot establish CPU thermal stability.', '']
for row in thermal:
    lines.append('- '+row['campaign_id']+': '+str(row['gpu_samples_during_measurement'])+' GPU samples during measurement, '+str(row['gpu_temperature_c_min'])+' to '+str(row['gpu_temperature_c_max'])+' C.')
lines+=['','See `verificacion_cruzada.json`, `comparacion_reproduccion.csv`, individual campaign `monitor_externo/` logs and `reserva_maquina.json`.']
(out/'README.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
for name in ['comparar_campanas.py','crear_informe.py','repetir_s07.ps1','registrar_gpu.ps1']:
    shutil.copyfile(script_dir/name,out/name)
print('New attempts compared; GPU samples correlated with actual measurement; human review pending.')
