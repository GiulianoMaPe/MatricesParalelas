# Informe de Auditoría de Dispersión y Variabilidad Experimental — Sprint 8

- **Campaña:** `s08_oficial_integrada_03`
- **Candidata evaluada:** Commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d` en host `PCG1UL14N0`
- **Marco normativo:** docs/protocolo_medicion.md §6.3, §7.1 y docs/sprints/sprint-08.md

---

## 1. Resumen Ejecutivo y Alcance

La auditoría evalúa la dispersión de los grupos del resumen indicado, con el fin de:
1. Detectar configuraciones con dispersión anormal o atípica.
2. Evaluar formalmente si se justifican repeticiones bajo las reglas del protocolo.
3. Prevenir el sesgo de selección de observaciones favorables.

---

## 2. Metodología de Auditoría No Paramétrica

Conforme a la sección 6.3 del protocolo de medición, el estimador de tendencia central oficial es la **mediana** ($x_3$) y el indicador canónico de dispersión es el **Rango Intercuartílico** ($\text{IQR} = Q_3 - Q_1 = x_4 - x_2$) sobre las 5 observaciones válidas.

Se calculan las siguientes métricas derivadas:
- **Dispersión Relativa Intercuartílica:** $\text{RSD}_{\text{IQR}} = \frac{\text{IQR}}{\widetilde{T}} \times 100\%$
- **Ratio de Rango Extremo:** $\text{Ratio}_{\text{Rango}} = \frac{x_{\max} - x_{\min}}{\widetilde{T}} \times 100\%$
- **Vallas de Tukey:** Detección de posibles valores atípicos fuera del intervalo $[Q_1 - 1.5\text{IQR}, Q_3 + 1.5\text{IQR}]$.

### Criterios de Clasificación de Estabilidad:
- **EXCELENTE:** $\text{RSD}_{\text{IQR}} \le 2.0\%$
- **ESTABLE:** $2.0\% < \text{RSD}_{\text{IQR}} \le 5.0\%$
- **MODERADA:** $5.0\% < \text{RSD}_{\text{IQR}} \le 10.0\%$
- **ALTA (Anormal):** $\text{RSD}_{\text{IQR}} > 10.0\%$

---

## 3. Matriz Cuantitativa de Auditoría de Dispersión

| Versión | Configuración | $N$ | Workers ($W$) | Mediana `total_s` (s) | IQR (s) | $\text{RSD}_{\text{IQR}}$ (%) | Rango Extremo (%) | Outliers Tukey | Estabilidad | Dictamen |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `c_paralelo` | `c_paralelo_P1_T1` | 512 | 1 | 0.0588 | 0.0001 | 0.15 % | 0.57 % | 1 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P1_T2` | 512 | 1 | 0.0301 | 0.0002 | 0.64 % | 14.41 % | 1 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P1_T4` | 512 | 1 | 0.0166 | 0.0020 | 12.12 % | 14.03 % | 0 | **ALTA (Alerta)** | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P2_T1` | 512 | 1 | 0.0305 | 0.0002 | 0.58 % | 1.12 % | 0 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P2_T2` | 512 | 1 | 0.0169 | 0.0004 | 2.64 % | 36.67 % | 1 | ESTABLE | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P4_T1` | 512 | 1 | 0.0172 | 0.0005 | 2.66 % | 4.46 % | 0 | ESTABLE | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P1_T1` | 1024 | 1 | 0.4501 | 0.0087 | 1.93 % | 13.29 % | 1 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P1_T2` | 1024 | 1 | 0.2765 | 0.0156 | 5.64 % | 15.41 % | 0 | *MODERADA* | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P1_T4` | 1024 | 1 | 0.1427 | 0.0220 | 15.39 % | 23.72 % | 0 | **ALTA (Alerta)** | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P2_T1` | 1024 | 1 | 0.3063 | 0.0191 | 6.24 % | 7.85 % | 0 | *MODERADA* | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P2_T2` | 1024 | 1 | 0.1628 | 0.0081 | 4.98 % | 28.24 % | 1 | ESTABLE | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P4_T1` | 1024 | 1 | 0.2022 | 0.0197 | 9.76 % | 14.87 % | 0 | *MODERADA* | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P1_T1` | 2048 | 1 | 5.0776 | 0.0715 | 1.41 % | 7.70 % | 2 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P1_T2` | 2048 | 1 | 2.5289 | 0.0973 | 3.85 % | 8.26 % | 0 | ESTABLE | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P1_T4` | 2048 | 1 | 1.8140 | 0.0189 | 1.04 % | 2.57 % | 0 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P2_T1` | 2048 | 1 | 2.8715 | 0.0777 | 2.71 % | 8.82 % | 1 | ESTABLE | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P2_T2` | 2048 | 1 | 2.0588 | 0.0481 | 2.34 % | 5.94 % | 0 | ESTABLE | `CONSERVAR_CONFORME` |
| `c_paralelo` | `c_paralelo_P4_T1` | 2048 | 1 | 2.2482 | 0.0785 | 3.49 % | 5.78 % | 0 | ESTABLE | `CONSERVAR_CONFORME` |
| `c_secuencial` | `c_secuencial` | 512 | 1 | 0.0238 | 0.0001 | 0.46 % | 1.27 % | 1 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `c_secuencial` | `c_secuencial` | 1024 | 1 | 0.2029 | 0.0205 | 10.11 % | 19.08 % | 0 | **ALTA (Alerta)** | `CONSERVAR_CONFORME` |
| `c_secuencial` | `c_secuencial` | 2048 | 1 | 3.8168 | 0.0996 | 2.61 % | 8.63 % | 1 | ESTABLE | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W1` | 512 | 1 | 0.1340 | 0.0004 | 0.30 % | 2.47 % | 1 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W2` | 512 | 2 | 0.0677 | 0.0003 | 0.50 % | 0.63 % | 0 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W4` | 512 | 4 | 0.0348 | 0.0007 | 2.15 % | 7.71 % | 1 | ESTABLE | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W1` | 1024 | 1 | 1.0818 | 0.0263 | 2.44 % | 4.80 % | 0 | ESTABLE | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W2` | 1024 | 2 | 0.5524 | 0.0523 | 9.47 % | 16.51 % | 0 | *MODERADA* | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W4` | 1024 | 4 | 0.3037 | 0.0162 | 5.33 % | 9.97 % | 0 | *MODERADA* | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W1` | 2048 | 1 | 8.8620 | 0.1965 | 2.22 % | 3.65 % | 0 | ESTABLE | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W2` | 2048 | 2 | 4.5669 | 0.0429 | 0.94 % | 2.01 % | 0 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W4` | 2048 | 4 | 2.4971 | 0.1239 | 4.96 % | 6.07 % | 0 | ESTABLE | `CONSERVAR_CONFORME` |
| `go_secuencial` | `go_secuencial` | 512 | 1 | 0.0905 | 0.0004 | 0.45 % | 1.30 % | 1 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `go_secuencial` | `go_secuencial` | 1024 | 1 | 0.7262 | 0.0128 | 1.76 % | 6.36 % | 1 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `go_secuencial` | `go_secuencial` | 2048 | 1 | 6.2969 | 0.0429 | 0.68 % | 4.65 % | 2 | **EXCELENTE** | `CONSERVAR_CONFORME` |

---

## 4. Dictamen

- Grupos con dispersión alta: 3 de 33.
- Grupos con repetición justificada: 0.
- El protocolo §6.3 conserva las cinco observaciones de los grupos completos, incluidas las lentas y las señaladas por las vallas de Tukey.
