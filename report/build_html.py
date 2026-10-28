"""Inject summary.json into template.html: python build_html.py <summary.json> <out.html>"""
import sys
from pathlib import Path

here = Path(__file__).parent
data = Path(sys.argv[1]).read_text(encoding="utf-8")
html = (here / "template.html").read_text(encoding="utf-8").replace("/*DATA*/null", data)
Path(sys.argv[2]).write_text(html, encoding="utf-8")
