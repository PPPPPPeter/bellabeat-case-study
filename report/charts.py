"""Render the six report charts as PNGs from summary.json (same data as the web report)."""
import json, sys
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

D = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
OUT = Path(sys.argv[2]); OUT.mkdir(exist_ok=True)
TEAL, SOFT, PLUM, INK, MUTED, GRID = "#0e7470", "#a9d3cf", "#8b3a6c", "#1c2a29", "#5d6b69", "#e6ebe9"
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10, "axes.edgecolor": GRID,
                     "axes.labelcolor": MUTED, "xtick.color": MUTED, "ytick.color": MUTED,
                     "axes.spines.top": False, "axes.spines.right": False})


def save(fig, name):
    fig.tight_layout(); fig.savefig(OUT / name, dpi=200); plt.close(fig)


def hbar(name, labels, values, xmax, fmt, colors):
    fig, ax = plt.subplots(figsize=(6.5, 0.55 * len(labels) + 0.6))
    y = np.arange(len(labels))[::-1]
    ax.barh(y, [xmax] * len(labels), color=GRID, height=0.6)
    ax.barh(y, values, color=colors, height=0.6)
    for yi, v in zip(y, values):
        ax.text(v + xmax * 0.01, yi, fmt(v), va="center", color=INK)
    ax.set_yticks(y, labels); ax.set_xlim(0, xmax * 1.12); ax.set_xticks([])
    ax.spines[["bottom", "left"]].set_visible(False); ax.tick_params(left=False)
    save(fig, name)


def vbar(name, labels, values, hi, ylabel):
    fig, ax = plt.subplots(figsize=(6.5, 2.8))
    ax.bar(range(len(values)), values, color=[TEAL if h else SOFT for h in hi], width=0.7)
    ax.set_xticks(range(len(values)), labels); ax.set_ylabel(ylabel)
    ax.yaxis.grid(True, color=GRID); ax.set_axisbelow(True)
    ax.yaxis.set_major_formatter(matplotlib.ticker.StrMethodFormatter("{x:,.0f}"))
    save(fig, name)


ms = D["minutes_split"]
hbar("1_minutes.png", ["Sedentary", "Lightly active", "Fairly active", "Very active"],
     [ms["SedentaryMinutes"], ms["LightlyActiveMinutes"], ms["FairlyActiveMinutes"], ms["VeryActiveMinutes"]],
     1440, lambda v: f"{v:,} min", [PLUM, TEAL, TEAL, TEAL])

h = sorted(D["hourly"], key=int)
vbar("2_hourly.png", [f"{int(x):02d}" if int(x) % 3 == 0 else "" for x in h], [D["hourly"][x] for x in h],
     [int(x) in (12, 13, 14, 17, 18, 19) for x in h], "Avg steps per hour")

lv = list(D["levels"])
hbar("3_levels.png", [l.split(" (")[0] for l in lv], [D["levels"][l] for l in lv],
     max(D["levels"].values()) + 2, lambda v: f"{v} users", [TEAL] * 4)

pts = np.array(D["scatter_sed_sleep"])
fig, ax = plt.subplots(figsize=(6.5, 3.4))
ax.scatter(pts[:, 0] / 60, pts[:, 1] / 60, s=10, color=PLUM, alpha=0.45, linewidths=0)
b, a = np.polyfit(pts[:, 0] / 60, pts[:, 1] / 60, 1)
xs = np.array([pts[:, 0].min(), pts[:, 0].max()]) / 60
ax.plot(xs, a + b * xs, color=INK, lw=2)
ax.set_xlabel("Sedentary hours per day"); ax.set_ylabel("Hours asleep")
ax.grid(True, color=GRID); ax.set_axisbelow(True)
save(fig, "4_sleep.png")

wd = list(D["weekday"])
vbar("5_weekday.png", [d[:3] for d in wd], [D["weekday"][d]["steps"] for d in wd],
     [d == "Sunday" for d in wd], "Avg steps per day")

n = D["n_users"]
ad = [("Steps & activity", n), ("Sleep (any night)", D["sleep_users"]), ("Sleep (15+ nights)", D["sleep_users_regular"]),
      ("Heart rate", D["hr_users"]), ("Weight log", D["weight_users"])]
hbar("6_adoption.png", [a[0] for a in ad], [round(a[1] / n * 100) for a in ad], 100,
     lambda v: f"{v}%", [TEAL] + [PLUM] * 4)
print("charts:", sorted(p.name for p in OUT.glob("*.png")))
