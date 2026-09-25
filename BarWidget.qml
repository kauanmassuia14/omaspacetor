import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "kauanmassuia14.omaspacetor"

    readonly property int slotCount: Math.max(1, Math.min(10, Number(setting("workspaceCount", 10)) || 10))
    readonly property var monitors: Hyprland.monitors.values
    readonly property var workspaces: Hyprland.workspaces.values
    readonly property var customLabels: objectSetting("monitorLabels")
    readonly property var customColors: objectSetting("monitorColors")
    readonly property var customWorkspaceLabels: objectSetting("workspaceLabels")
    readonly property var colorPalettes: ({
        pastel: ["#89B4FA", "#F38BA8", "#A6E3A1", "#CBA6F7", "#F9E2AF", "#94E2D5"],
        neon: ["#00E5FF", "#FF2E97", "#B7FF00", "#BF5AF2", "#FF9F0A", "#00D084"],
        warm: ["#E76F51", "#2A9D8F", "#E9C46A", "#D78A76", "#CC7BBA", "#8AB17D"],
        nord: ["#88C0D0", "#BF616A", "#A3BE8C", "#B48EAD", "#EBCB8B", "#81A1C1"],
        monochrome: ["#E5E7EB", "#BFC5CE", "#9CA3AF", "#D1D5DB", "#A1A1AA", "#F4F4F5"]
    })

    function objectSetting(key) {
        var value = setting(key, ({}))
        if (typeof value === "string") {
            try {
                value = JSON.parse(value)
            } catch (error) {
                return ({})
            }
        }
        return value && typeof value === "object" && !Array.isArray(value) ? value : ({})
    }

    function isLaptopMonitor(monitor) {
        return !!monitor && /^(eDP|LVDS|DSI)/i.test(String(monitor.name))
    }

    function externalMonitorNumber(monitor) {
        var number = 0
        for (var i = 0; i < monitors.length; i++) {
            if (isLaptopMonitor(monitors[i])) continue
            number++
            if (String(monitors[i].name) === String(monitor.name)) return number
        }
        return Math.max(1, number)
    }

    function monitorRole(monitor) {
        return isLaptopMonitor(monitor) ? "Notebook" : "Monitor " + externalMonitorNumber(monitor)
    }

    function displayName(monitor) {
        if (!monitor) return "?"

        var configured = customLabels[String(monitor.name)]
        if (configured !== undefined && String(configured).trim() !== "")
            return String(configured).trim()

        var style = String(setting("monitorLabelStyle", "short")).toLowerCase()
        if (style === "output") return String(monitor.name)
        if (style === "full") return monitorRole(monitor)
        return isLaptopMonitor(monitor) ? "NB" : "M" + externalMonitorNumber(monitor)
    }

    function monitorIndex(monitor) {
        for (var i = 0; i < monitors.length; i++) {
            if (String(monitors[i].name) === String(monitor.name)) return i
        }
        return 0
    }

    function isHexColor(value) {
        return /^#[0-9A-Fa-f]{6}$/.test(String(value || "").trim())
    }

    function monitorColor(monitor) {
        if (!monitor) return "#89B4FA"

        var configured = customColors[String(monitor.name)]
        if (isHexColor(configured)) return String(configured).trim()

        var theme = String(setting("monitorColorTheme", "Pastel")).toLowerCase()
        var palette = colorPalettes[theme] || colorPalettes.pastel
        return palette[monitorIndex(monitor) % palette.length]
    }

    function workspaceLabel(slot) {
        var configured = customWorkspaceLabels[String(slot)]
        if (configured !== undefined && String(configured).trim() !== "")
            return String(configured).trim()
        return slot === 10 ? "0" : String(slot)
    }

    function workspaceKey(slot) {
        return slot === 10 ? "0" : String(slot)
    }

    function encodedMonitorName(name) {
        // Match Python's urllib.parse.quote(..., safe="~-._") in focus-workspace.py.
        return encodeURIComponent(String(name)).replace(/[!'()*]/g, function(character) {
            return "%" + character.charCodeAt(0).toString(16).toUpperCase()
        })
    }

    function localWorkspaceName(monitor, slot) {
        return "omaspacetor:" + encodedMonitorName(monitor.name) + ":" + slot
    }

    function legacyWorkspace(monitor, slot) {
        var name = String(slot)
        for (var i = 0; i < workspaces.length; i++) {
            var workspace = workspaces[i]
            if (workspace.name === name && workspace.monitor && workspace.monitor.name === monitor.name)
                return workspace
        }
        return null
    }

    function workspaceForSlot(monitor, slot) {
        var legacy = legacyWorkspace(monitor, slot)
        if (legacy) return legacy

        var targetName = localWorkspaceName(monitor, slot)
        for (var i = 0; i < workspaces.length; i++) {
            var workspace = workspaces[i]
            if (workspace.name === targetName && workspace.monitor && workspace.monitor.name === monitor.name)
                return workspace
        }
        return null
    }

    function focusMonitor(monitor) {
        if (!monitor || !bar) return
        bar.run("hyprctl dispatch focusmonitor " + Util.shellQuote(String(monitor.name)))
    }

    function focusWorkspace(monitor, slot) {
        if (!monitor || !bar) return
        var legacy = legacyWorkspace(monitor, slot)
        var target = legacy ? String(slot) : "name:" + localWorkspaceName(monitor, slot)
        var command = "hyprctl dispatch focusmonitor " + Util.shellQuote(String(monitor.name))
            + " && hyprctl dispatch workspace " + Util.shellQuote(target)
        bar.run(command)
    }

    function workspaceTooltip(monitor, slot, workspace) {
        var alias = String(customWorkspaceLabels[String(slot)] || "").trim()
        var title = "Workspace " + slot + (alias ? " · " + String(alias) : "")
        var lines = [displayName(monitor) + " · " + monitorRole(monitor) + " · " + String(monitor.name), title]
        if (workspace) {
            var windowCount = workspace.toplevels.values.length
            lines.push(windowCount === 1 ? "1 janela" : windowCount + " janelas")
        } else {
            lines.push("Vazio; será criado neste monitor")
        }
        lines.push("Clique para alternar · Super+" + workspaceKey(slot) + " com integração de teclado")
        return lines.join("\n")
    }

    implicitWidth: monitorLayout.implicitWidth
    implicitHeight: monitorLayout.implicitHeight

    GridLayout {
        id: monitorLayout
        columns: root.vertical ? 1 : Math.max(1, root.monitors.length)
        columnSpacing: root.vertical ? 0 : Style.space(5)
        rowSpacing: root.vertical ? Style.space(2) : 0

        Repeater {
            model: root.monitors

            delegate: GridLayout {
                id: monitorGroup
                required property var modelData

                columns: root.vertical ? 1 : root.slotCount + 1
                rows: root.vertical ? root.slotCount + 1 : 1
                columnSpacing: root.vertical ? 0 : Style.space(1)
                rowSpacing: root.vertical ? Style.space(1) : 0

                WidgetButton {
                    Layout.row: 0
                    Layout.column: 0
                    bar: root.bar
                    text: root.displayName(monitorGroup.modelData)
                    fontSize: Style.font.bodySmall
                    horizontalMargin: 4
                    verticalPadding: 4
                    active: !!monitorGroup.modelData.focused
                    activeColor: root.monitorColor(monitorGroup.modelData)
                    tooltipText: root.displayName(monitorGroup.modelData) + " · "
                        + root.monitorRole(monitorGroup.modelData) + " · "
                        + String(monitorGroup.modelData.name)
                        + (monitorGroup.modelData.focused ? "\nFoco do teclado aqui" : "\nClique para focar este monitor")
                    onPressed: function(button) {
                        if (button === Qt.LeftButton) root.focusMonitor(monitorGroup.modelData)
                    }
                }

                Repeater {
                    model: root.slotCount

                    delegate: WidgetButton {
                        required property int index

                        readonly property int slot: index + 1
                        readonly property var workspace: root.workspaceForSlot(monitorGroup.modelData, slot)
                        readonly property var activeWorkspace: monitorGroup.modelData.activeWorkspace
                        readonly property bool selected: activeWorkspace
                            && (activeWorkspace.name === String(slot)
                                || activeWorkspace.name === root.localWorkspaceName(monitorGroup.modelData, slot))
                        readonly property bool occupied: workspace && workspace.toplevels.values.length > 0

                        Layout.row: root.vertical ? slot : 0
                        Layout.column: root.vertical ? 0 : slot
                        bar: root.bar
                        text: root.workspaceLabel(slot)
                        fontSize: Style.font.body
                        horizontalMargin: 5
                        verticalPadding: 4
                        dimmed: !occupied && !selected
                        active: selected
                        activeColor: root.monitorColor(monitorGroup.modelData)
                        tooltipText: root.workspaceTooltip(monitorGroup.modelData, slot, workspace)
                        onPressed: function(button) {
                            if (button === Qt.LeftButton)
                                root.focusWorkspace(monitorGroup.modelData, slot)
                        }
                    }
                }
            }
        }
    }
}
