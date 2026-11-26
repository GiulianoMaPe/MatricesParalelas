"""Genera las figuras del Sprint 9 a partir del resumen oficial del Sprint 8."""

import argparse
import csv
from dataclasses import dataclass
from math import isfinite
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.ticker import FuncFormatter, MaxNLocator


ROOT = Path(__file__).resolve().parents[1]
CAMPAIGN = "s08_oficial_integrada_03"
SUMMARY = ROOT / "resultados" / "resumen" / CAMPAIGN / "resumen_estadistico.csv"
OUTPUT = ROOT / "resultados" / "graficos" / CAMPAIGN
SIZES = (512, 1024, 2048)


@dataclass(frozen=True)
class Configuration:
    key: str
    label: str
    color: str
    marker: str


C_CONFIGS = (
    Configuration("c_secuencial", "C secuencial", "#24334b", "D"),
    Configuration("c_paralelo_P1_T1", "C · P=1, T=1", "#155f84", "o"),
    Configuration("c_paralelo_P1_T2", "C · P=1, T=2", "#155f84", "o"),
    Configuration("c_paralelo_P1_T4", "C · P=1, T=4", "#155f84", "o"),
    Configuration("c_paralelo_P2_T1", "C · P=2, T=1", "#155f84", "o"),
    Configuration("c_paralelo_P2_T2", "C · P=2, T=2", "#155f84", "o"),
    Configuration("c_paralelo_P4_T1", "C · P=4, T=1", "#155f84", "o"),
)
GO_CONFIGS = (
    Configuration("go_secuencial", "Go secuencial", "#24334b", "D"),
    Configuration("go_paralelo_W1", "Go · W=1", "#a14e15", "s"),
    Configuration("go_paralelo_W2", "Go · W=2", "#a14e15", "s"),
    Configuration("go_paralelo_W4", "Go · W=4", "#a14e15", "s"),
)
TIME_STATS = ("min", "q1", "median", "q3", "max")


def read_summary():
    rows = {}
    with SUMMARY.open(encoding="utf-8-sig", newline="") as source:
        for row in csv.DictReader(source):
            key = (int(row["n"]), row["configuration"])
            if key in rows or (
                row["campaign_id"], row["status"], row["reps_count"]
            ) != (CAMPAIGN, "COMPLETE", "5"):
                raise ValueError(f"Grupo duplicado o fuera de la campaña completa: {key}")

            metrics = {name: float(row[name]) for name in ("speedup", "efficiency")}
            for metric in ("total_s", "kernel_s"):
                values = [float(row[f"{metric}_{stat}"]) for stat in TIME_STATS]
                if values != sorted(values):
                    raise ValueError(f"Estadísticos desordenados para {metric}: {key}")
                metrics.update(zip((f"{metric}_{stat}" for stat in TIME_STATS), values))
            if any(not isfinite(value) or value <= 0 for value in metrics.values()):
                raise ValueError(f"Métrica no finita o no positiva: {key}")
            rows[key] = metrics

    expected = {(size, config.key) for size in SIZES for config in C_CONFIGS + GO_CONFIGS}
    if rows.keys() != expected:
        raise ValueError(f"Configuraciones faltantes o inesperadas: {rows.keys() ^ expected}")
    return rows


def make_panels(title, axis_label, configurations):
    figure, axes = plt.subplots(1, len(SIZES), figsize=(11.4, 5.6), sharey=True)
    figure.subplots_adjust(left=0.14, right=0.97, top=0.83, bottom=0.24, wspace=0.11)
    figure.suptitle(title, x=0.14, y=0.96, ha="left", fontsize=19, fontweight="bold")
    figure.text(0.14, 0.895, f"Campaña oficial {CAMPAIGN} · 5 mediciones por grupo", fontsize=11)
    figure.supxlabel(axis_label, x=0.555, y=0.125, fontsize=11)
    for size, axis in zip(SIZES, axes):
        axis.set_title(f"N = {size}", fontsize=12, pad=10)
        axis.set_yticks(range(len(configurations)), [config.label for config in configurations])
        axis.set_ylim(len(configurations) - 0.5, -0.5)
        axis.axhspan(-0.5, len(configurations) - 0.5, color="#f7f9fc", zorder=-2)
        axis.grid(axis="x", color="#d8dfe8", linewidth=0.7)
        axis.set_axisbelow(True)
        axis.tick_params(axis="y", length=0, pad=8)
        axis.spines[["top", "right", "left"]].set_visible(False)
        axis.spines["bottom"].set_color("#a4b0bf")
    return figure, axes


def save(figure, destination, legend):
    figure.legend(handles=legend, loc="lower center", bbox_to_anchor=(0.555, 0.023),
                  ncols=len(legend), frameon=False)
    figure.savefig(destination, dpi=200, facecolor="white")
    plt.close(figure)


def plot_times(rows, output, metric, title, filename):
    configurations = C_CONFIGS + GO_CONFIGS
    figure, axes = make_panels(title, "Tiempo (s) · escala logarítmica", configurations)
    ticks = (0.01, 0.03, 0.1, 0.3, 1, 3, 10)
    lower = min(row[f"{metric}_min"] for row in rows.values())
    upper = max(row[f"{metric}_max"] for row in rows.values())
    for size, axis in zip(SIZES, axes):
        axis.set_xscale("log")
        axis.set_xticks(ticks, [str(value).replace(".", ",") for value in ticks])
        axis.set_xlim(min(0.009, lower / 1.1), max(11, upper * 1.1))
        axis.tick_params(axis="x", which="minor", bottom=False)
        axis.axhline(len(C_CONFIGS) - 0.5, color="#c8d2df", linewidth=0.8)
        for position, config in enumerate(configurations):
            row = rows[size, config.key]
            minimum, q1, median, q3, maximum = [row[f"{metric}_{stat}"] for stat in TIME_STATS]
            axis.hlines(position, minimum, maximum, color="#8796ab", linewidth=1)
            axis.vlines([minimum, maximum], position - 0.11, position + 0.11,
                        color="#8796ab", linewidth=1)
            axis.hlines(position, q1, q3, color=config.color, linewidth=4)
            axis.vlines(median, position - 0.17, position + 0.17,
                        color="#172637", linewidth=1.3)

    save(figure, output / filename, [
        Line2D([], [], color="#172637", marker="|", markersize=9, markeredgewidth=1.3,
               linestyle="none", label="Mediana"),
        Line2D([], [], color="#24334b", linewidth=4, label="Q1–Q3"),
        Line2D([], [], color="#8796ab", marker="|", linewidth=1, label="Mínimo–máximo"),
    ])


def plot_ratio(rows, output, metric, title, axis_label, reference, filename, upper):
    configurations = C_CONFIGS[1:] + GO_CONFIGS[1:]
    figure, axes = make_panels(title, axis_label, configurations)
    maximum = max(rows[size, config.key][metric] for size in SIZES for config in configurations)
    for size, axis in zip(SIZES, axes):
        axis.set_xlim(0, max(upper, maximum * 1.05))
        axis.xaxis.set_major_locator(MaxNLocator(6))
        axis.xaxis.set_major_formatter(FuncFormatter(lambda value, _: f"{value:g}".replace(".", ",")))
        axis.axvline(1, color="#53617a", linestyle="--", linewidth=1)
        axis.axhline(len(C_CONFIGS) - 1.5, color="#c8d2df", linewidth=0.8)
        for position, config in enumerate(configurations):
            value = rows[size, config.key][metric]
            axis.plot(value, position, marker=config.marker, color=config.color, markersize=7)

    save(figure, output / filename, [
        Line2D([], [], color="#53617a", linestyle="--", label=reference),
    ])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--salida", type=Path, default=OUTPUT, help="Carpeta de salida de los PNG")
    output = parser.parse_args().salida
    rows = read_summary()
    output.mkdir(parents=True, exist_ok=True)
    plt.rcParams.update({"font.family": "DejaVu Sans", "text.color": "#172637",
                         "xtick.color": "#24334b", "ytick.color": "#24334b"})
    plot_times(rows, output, "total_s", "Tiempo total por configuración", "tiempo_total.png")
    plot_times(rows, output, "kernel_s", "Tiempo del núcleo por configuración", "tiempo_kernel.png")
    plot_ratio(rows, output, "speedup", "Aceleración frente al secuencial",
               "Speedup (×)", "1× · mismo tiempo que el secuencial", "speedup.png", 3)
    plot_ratio(rows, output, "efficiency", "Eficiencia por trabajador nominal",
               "Eficiencia (fracción)", "1 · aceleración lineal", "eficiencia.png", 1.06)
    print(f"Se generaron 4 figuras en {output}")


if __name__ == "__main__":
    main()
