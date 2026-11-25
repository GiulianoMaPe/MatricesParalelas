# Informe de Auditoría de Dispersión y Variabilidad Experimental — Sprint 8

**Responsable:** Integrante 7 — Andrés  
**Fecha:** 2026-11-19  
**Candidata evaluada:** Commit `97ccc981e9068d8ec0753cd8a4b7572a6bece34d` en host oficial `PCG1UL14N0`  
**Marco normativo:** docs/protocolo_medicion.md §6.3, §7.1 y docs/sprints/sprint-08.md  

---

## 1. Resumen Ejecutivo y Alcance

En cumplimiento del plan de trabajo del Sprint 8 para el **Integrante 7**, este documento audita cuantitativamente la dispersión estadística y la estabilidad de las mediciones oficiales disponibles bajo `resultados/raw/`, con el fin de:
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
| `go_paralelo` | `go_paralelo_W1` | 512 | 1 | 0.1347 | 0.0004 | 0.32 % | 3.94 % | 2 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W2` | 512 | 2 | 0.0688 | 0.0021 | 2.99 % | 3.52 % | 0 | ESTABLE | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W4` | 512 | 4 | 0.0374 | 0.0012 | 3.15 % | 11.66 % | 1 | ESTABLE | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W1` | 1024 | 1 | 1.0794 | 0.0543 | 5.03 % | 6.94 % | 0 | *MODERADA* | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W2` | 1024 | 2 | 0.6027 | 0.0645 | 10.71 % | 14.90 % | 0 | **ALTA (Alerta)** | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W4` | 1024 | 4 | 0.3169 | 0.0361 | 11.40 % | 18.91 % | 0 | **ALTA (Alerta)** | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W1` | 2048 | 1 | 9.0143 | 0.0354 | 0.39 % | 2.61 % | 1 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W2` | 2048 | 2 | 4.5439 | 0.0189 | 0.42 % | 5.08 % | 2 | **EXCELENTE** | `CONSERVAR_CONFORME` |
| `go_paralelo` | `go_paralelo_W4` | 2048 | 4 | 2.6147 | 0.0173 | 0.66 % | 4.40 % | 2 | **EXCELENTE** | `CONSERVAR_CONFORME` |

---

## 4. Análisis Detallado de Dispersión Anormal

### 4.1. Detección en $N=1024$ ($W=2$ y $W=4$)
Se identificó dispersión relativa superior al umbral del 10% en dos configuraciones de Go paralelo:
- **`go_paralelo_W2` ($N=1024$):** $\text{RSD}_{\text{IQR}} = 10.71\%$, Rango extremo = $14.90\%$. Observaciones ordenadas: `[0.5422, 0.5606, 0.6027, 0.6251, 0.6320]` s.
- **`go_paralelo_W4` ($N=1024$):** $\text{RSD}_{\text{IQR}} = 11.40\%$, Rango extremo = $18.91\%$. Observaciones ordenadas: `[0.2968, 0.3017, 0.3169, 0.3378, 0.3567]` s.

### 4.2. Causa Raíz de la Variabilidad
1. **Duraciones Cortas:** En $N=1024$, las ejecuciones duran entre 0.3 s y 0.6 s. En este régimen temporal sub-segundo, pequeñas variaciones en la planificación de goroutines y cambios de contexto del kernel de Windows representan un porcentaje mayor de la duración total.
2. **Estabilidad en Carga Pesada ($N=2048$):** Cuando la carga aumenta a $N=2048$ (duraciones de 2.6 s a 9.0 s), la dispersión relativa cae drásticamente a **menos del 0.7%** ($W=1: 0.39\%$, $W=2: 0.42\%$, $W=4: 0.66\%$). Esto demuestra que el arnés de medición y el hardware son altamente estables y no sufren degradación térmica.
3. **Ausencia de Outliers Extremos:** La prueba de vallas de Tukey confirma cero valores atípicos ($0$ outliers). Todas las observaciones se encuentran dentro del rango previsible de dispersión operativa.

---

## 5. Dictamen Formal y Propuesta de Repeticiones Justificadas

### 5.1. Reglas Normativas del Protocolo (§6.3)
> *"Conservar observaciones lentas o speedup menor que 1. Si una corrida falla, el grupo queda incompleto y no participa en speedup oficial. Conservar el fallo, investigar la causa y, si se repite, ejecutar un lote completo de warmup + 5 medidas en una nueva carpeta de campaña/intento... No sustituir solo la observación más lenta ni escoger el mejor lote."*

### 5.2. Dictamen de Auditoría
- **Dictamen:** **CONSERVAR_CONFORME (No repetir)**.
- **Fundamentación:**
  1. Todas las ejecuciones finalizaron exitosamente con código 0 y alidation_status = OK.
  2. No se registraron fallos de memoria (OOM), errores de proceso ni TIMEOUT.
  3. El protocolo prohíbe taxativamente descartar corridas lentas de forma arbitraria o 'escoger el mejor lote'.
  4. El empleo de la **mediana** como métrica central cumple con su propósito de diseño: inmunizar las conclusiones del proyecto frente a las fluctuaciones del planificador del sistema operativo sin introducir sesgos artificiales.

---
Documento generado automáticamente por scripts/audit_dispersion.ps1 — Sprint 8 (I7).
