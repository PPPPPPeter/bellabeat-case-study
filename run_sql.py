"""Run the SQL pipeline in DuckDB and write summary.json + cleaned tables.

usage: python run_sql.py <dataset folder> <output folder>
"""
import json, re, sys
from pathlib import Path
import duckdb

ROOT, OUT = Path(sys.argv[1]).as_posix(), Path(sys.argv[2])
SQL = Path(__file__).parent / "sql"
OUT.mkdir(parents=True, exist_ok=True)
con = duckdb.connect(str(OUT / "bellabeat.duckdb"))

for f in ("01_load.sql", "02_clean.sql"):
    con.execute((SQL / f).read_text(encoding="utf-8").replace("{ROOT}", ROOT))

bad = [r for r in con.execute("SELECT * FROM checks").fetchall() if r[1] != 0]
assert not bad, f"integrity checks failed: {bad}"


def rows(sql):
    cur = con.execute(sql)
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, r)) for r in cur.fetchall()]


q = {}
for block in re.split(r"^-- name: ", (SQL / "03_analysis.sql").read_text(encoding="utf-8"), flags=re.M)[1:]:
    name, sql = block.split("\n", 1)
    q[name.strip()] = rows(sql)

ov = q["overview"][0]
res = {
    "log": [r["line"] for r in q["log"]],
    **{k: v for k, v in ov.items() if k not in ("date_min", "date_max")},
    "date_range": [ov["date_min"], ov["date_max"]],
    "levels": {r["level"]: r["users"] for r in q["levels"]},
    "minutes_split": q["minutes_split"][0],
    "weekday": {r["Weekday"]: {"steps": r["steps"], "sed": r["sed"]} for r in q["weekday"]},
    "hourly": {r["Hour"]: r["steps"] for r in q["hourly"]},
    **q["sleep"][0], **q["adoption"][0],
    "days_per_user": q["days_per_user"][0],
    "scatter_sed_sleep": [list(r.values()) for r in q["scatter_sed_sleep"]],
    "scatter_steps_cal": [list(r.values()) for r in q["scatter_steps_cal"]],
}
(OUT / "summary.json").write_text(json.dumps(res, ensure_ascii=False, indent=1), encoding="utf-8")
for t in ("daily", "sleep", "user_summary"):
    con.execute(f"COPY {t} TO '{(OUT / (t + '_clean.csv')).as_posix()}' (HEADER)")
print(json.dumps({k: v for k, v in res.items() if not k.startswith("scatter")}, ensure_ascii=False, indent=1))
