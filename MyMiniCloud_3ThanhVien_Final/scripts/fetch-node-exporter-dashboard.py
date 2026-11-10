#!/usr/bin/env python3
"""Download and normalize Grafana.com dashboard 1860 revision 45."""

from __future__ import annotations

import json
from pathlib import Path
from urllib.request import Request, urlopen


DASHBOARD_ID = 1860
REVISION = 45
SOURCE_URL = (
    f"https://grafana.com/api/dashboards/{DASHBOARD_ID}/"
    f"revisions/{REVISION}/download"
)
OUTPUT = (
    Path(__file__).resolve().parents[1]
    / "monitoring-grafana-dashboard-server"
    / "dashboards"
    / "node-exporter-full.json"
)
DATASOURCE_UID = "prometheus"


def normalize_datasource(value: object) -> None:
    if isinstance(value, dict):
        datasource = value.get("datasource")
        if isinstance(datasource, dict) and datasource.get("uid") == "${ds_prometheus}":
            datasource["uid"] = DATASOURCE_UID
        for child in value.values():
            normalize_datasource(child)
    elif isinstance(value, list):
        for child in value:
            normalize_datasource(child)


def main() -> None:
    request = Request(SOURCE_URL, headers={"User-Agent": "MyMiniCloud/1.0"})
    with urlopen(request, timeout=30) as response:
        dashboard = json.load(response)

    if dashboard.get("title") != "Node Exporter Full":
        raise ValueError("Unexpected dashboard title from Grafana.com")

    normalize_datasource(dashboard)
    variables = dashboard.get("templating", {}).get("list", [])
    dashboard["templating"]["list"] = [
        variable for variable in variables if variable.get("name") != "ds_prometheus"
    ]
    dashboard["id"] = None
    dashboard["version"] = 1
    dashboard["tags"] = sorted(
        set(dashboard.get("tags", []))
        | {"Grafana.com 1860", "revision 45", "MyMiniCloud"}
    )

    serialized = json.dumps(dashboard, ensure_ascii=False, indent=2) + "\n"
    if "${ds_prometheus}" in serialized:
        raise ValueError("Datasource placeholder remains after normalization")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(serialized, encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT} ({len(serialized)} characters)")


if __name__ == "__main__":
    main()
