#!/usr/bin/env python3
"""Focus a numbered workspace slot on a selected Hyprland monitor."""

import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote


PLUGIN_PREFIX = "omaspacetor:"
PLUGIN_ID = "kauanmassuia14.omaspacetor"


def hyprctl_json(kind):
    return json.loads(subprocess.check_output(["hyprctl", "-j", kind], text=True))


def is_laptop_monitor(monitor):
    return bool(re.match(r"^(eDP|LVDS|DSI)", str(monitor.get("name", "")), re.IGNORECASE))


def select_monitor(monitors, selector):
    if selector == "focused":
        return next((monitor for monitor in monitors if monitor.get("focused")), None)
    if selector == "NB":
        return next((monitor for monitor in monitors if is_laptop_monitor(monitor)), None)
    if re.fullmatch(r"M[1-9][0-9]*", selector):
        external = [monitor for monitor in monitors if not is_laptop_monitor(monitor)]
        index = int(selector[1:]) - 1
        return external[index] if index < len(external) else None
    return None


def configured_workspace_count():
    """Read this widget's visible slot count, falling back safely to ten."""
    config_path = Path.home() / ".config/omarchy/shell.json"
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
        layout = config.get("bar", {}).get("layout", {})
        for section in ("left", "center", "right"):
            entries = layout.get(section, [])
            if not isinstance(entries, list):
                continue
            for entry in entries:
                if not isinstance(entry, dict) or entry.get("id") != PLUGIN_ID:
                    continue
                count = entry.get("workspaceCount", 10)
                if isinstance(count, int) and not isinstance(count, bool):
                    return max(1, min(10, count))
                return 10
    except (OSError, json.JSONDecodeError, AttributeError, TypeError):
        pass
    return 10


def main():
    if (
        len(sys.argv) not in (2, 3)
        or not re.fullmatch(r"(?:[1-9]|10)", sys.argv[1])
        or (len(sys.argv) == 3 and not re.fullmatch(r"(?:focused|NB|M[1-9][0-9]*)", sys.argv[2]))
    ):
        print("Usage: focus-workspace.py <1-10> [focused|NB|M1...]", file=sys.stderr)
        return 2

    slot = int(sys.argv[1])
    selector = sys.argv[2] if len(sys.argv) == 3 else "focused"
    slot_count = configured_workspace_count()
    if slot > slot_count:
        print(
            f"OmaSpaceTor: this widget is configured for {slot_count} workspace slot(s).",
            file=sys.stderr,
        )
        return 2

    monitors = hyprctl_json("monitors")
    monitor = select_monitor(monitors, selector)
    if not monitor:
        print(f"OmaSpaceTor: monitor {selector} is not connected.", file=sys.stderr)
        return 1

    monitor_name = str(monitor["name"])
    workspaces = hyprctl_json("workspaces")

    # Reuse an existing numbered workspace on this monitor. This keeps current
    # Omarchy workspaces in place and creates a monitor-local named space only
    # when that number currently belongs to a different output.
    legacy = next(
        (
            workspace
            for workspace in workspaces
            if str(workspace.get("name")) == str(slot)
            and workspace.get("monitor") == monitor_name
        ),
        None,
    )
    if legacy:
        target = str(slot)
    else:
        monitor_token = quote(monitor_name, safe="~-._")
        target = "name:" + PLUGIN_PREFIX + monitor_token + ":" + str(slot)

    subprocess.run(["hyprctl", "dispatch", "focusmonitor", monitor_name], check=True)
    subprocess.run(["hyprctl", "dispatch", "workspace", target], check=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as error:
        print("OmaSpaceTor: hyprctl command failed.", file=sys.stderr)
        raise SystemExit(error.returncode or 1)
    except (json.JSONDecodeError, KeyError, OSError) as error:
        print("OmaSpaceTor: could not read Hyprland state: " + str(error), file=sys.stderr)
        raise SystemExit(1)
