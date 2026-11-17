import csv
import datetime
import hashlib
import json
import pathlib
import re
import statistics

base = pathlib.Path('resultados/piloto')
ids = ['s07_windows_20261117_piloto_03', 's07_windows_20261117_reproduccion_03']
folders = [base / name for name in ids]

def read_json(folder, name):
    return json.loads((folder / name).read_text(encoding='utf-8-sig'))

def rows(folder, name):
    with (folder / name).open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))

env = [read_json(folder, 'entorno.json') for folder in folders]
states = [read_json(folder, 'estado.json') for folder in folders]
verified = [read_json(folder, 'verificacion.json') for folder in folders]
summaries = [rows(folder, 'resumen_estadistico.csv') for folder in folders]
hashes = [read_json(folder, 'source-hashes.json') for folder in folders]
checks = {
    'same_commit': env[0]['git']['commit_full'] == env[1]['git']['commit_full'],
    'clean_sources': all(not item['git']['dirty'] for item in env),
    'clean_builds': all(not build['manifest']['dirty'] for item in env for build in item['build']['manifests'].values()),
    'same_binaries': env[0]['build']['executable_sha256_by_version'] == env[1]['build']['executable_sha256_by_version'],
    'same_sources': hashes[0] == hashes[1],
    'same_plan_bytes': (folders[0] / 'plan.csv').read_bytes() == (folders[1] / 'plan.csv').read_bytes(),
    'same_experiment': env[0]['experiment'] == env[1]['experiment'],
    'same_hardware_and_power': all(env[0]['hardware'][name] == env[1]['hardware'][name] for name in ['cpu_model','physical_cores','logical_processors','ram_visible_bytes','os_edition','os_build','power_source','power_plan']),
    'complete_198_each': all(item['status'] == 'COMPLETE' and item['accepted'] == item['planned'] == 198 for item in states),
    'verified_33_groups_each': all(item['status'] == 'VERIFIED' and item['observations'] == 198 and item['groups'] == 33 for item in verified),
    'all_groups_complete': all(len(summary) == 33 and all(row['status'] == 'COMPLETE' for row in summary) for summary in summaries),
    'three_sizes_all_versions': all({int(row['n']) for row in rows(folder, 'mediciones.csv')} == {256,512,1024} and {row['version'] for row in rows(folder, 'mediciones.csv')} == {'c_secuencial','c_paralelo','go_secuencial','go_paralelo'} for folder in folders),
}
if not all(checks.values()):
    raise SystemExit(json.dumps(checks, indent=2))
key = lambda row: (row['version'], int(row['n']), row['configuration'])
left, right = [{key(row): row for row in summary} for summary in summaries]
assert left.keys() == right.keys()
comparison = []
for group in sorted(left):
    a, b = left[group], right[group]
    # The public summary's column names are used directly; no reaggregation or
    # pooling of the independent attempts occurs here.
    median_column = next(name for name in a if name in ('total_s_median', 'median_total_s'))
    first, second = float(a[median_column]), float(b[median_column])
    comparison.append({'version': group[0], 'n': group[1], 'configuration': group[2],
        'pilot_total_s_median': first, 'reproduction_total_s_median': second,
        'relative_change_percent': None if first == 0 else 100 * (second - first) / first})
conditions = []
for folder in folders:
    text = (folder / 'bitacora.txt').read_text(encoding='utf-8-sig')
    loads = [float(value) for value in re.findall(r'cpu_load_percent=(\d+)', text)]
    free = [int(value) for value in re.findall(r'free_memory_kib=(\d+)', text)]
    conditions.append({'campaign_id': folder.name, 'load_samples': len(loads),
        'cpu_load_percent_min': min(loads), 'cpu_load_percent_max': max(loads),
        'minimum_free_memory_kib': min(free), 'temperature_sensor': 'unavailable',
        'maximum_process_wall_seconds':max(read_json(path.parent, path.name)['wall_s'] for path in (folder/'logs').glob('*/proceso.json')),
        'interpretation': 'Samples precede each run and may include prior benchmark load; no thermal measurement or attribution to background tasks.'})
out = base / 's07_windows_20261117_cierre_03'
out.mkdir(exist_ok=True)
with (out / 'comparacion_reproduccion.csv').open('w',encoding='utf-8',newline='') as stream:
    writer=csv.DictWriter(stream,fieldnames=list(comparison[0]))
    writer.writeheader(); writer.writerows(comparison)
result = {'recorded_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'campaigns':ids, 'commit':env[0]['git']['commit_full'], 'checks':checks,
    'executable_sha256':env[0]['build']['executable_sha256_by_version'],
    'data_sha256':{folder.name:hashlib.sha256((folder/'mediciones.csv').read_bytes()).hexdigest() for folder in folders},
    'pilot_wall_seconds':states[0]['wall_s'], 'reproduction_wall_seconds':states[1]['wall_s'],
    'estimates':[read_json(folder,'estimacion.json') for folder in folders],
    'conditions':conditions,
    'median_absolute_relative_change_percent': statistics.median(abs(row['relative_change_percent']) for row in comparison if row['relative_change_percent'] is not None),
    'maximum_absolute_relative_change_percent':max(abs(row['relative_change_percent']) for row in comparison if row['relative_change_percent'] is not None),
    'human_acceptance_file':'aceptacion_responsable.json', 's8_reservation_file':'reserva_maquina.json',
    'caveat':'No cross-attempt pooling, outlier deletion, thermal stability claim, or arbitrary performance equivalence threshold.'}
(out/'verificacion_cruzada.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(json.dumps(result,indent=2,ensure_ascii=False))
