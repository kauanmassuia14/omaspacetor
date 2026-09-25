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
    readonly property var customLabels: {
        try {
            var parsed = JSON.parse(String(setting("monitorLabels", "{}")))
            return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : ({})
        } catch (error) {
            return ({})
        }
    }

    function displayName(monitor) {
        if (!monitor) return "?"
        var configured = customLabels[String(monitor.name)]
        if (configured !== undefined && String(configured).trim() !== "")
            return String(configured).trim()
        if (/^(eDP|LVDS|DSI)/i.test(String(monitor.name))) return "Laptop"

        var externalIndex = 0
        for (var i = 0; i < monitors.length; i++) {
            if (/^(eDP|LVDS|DSI)/i.test(String(monitors[i].name))) continue
            externalIndex++
            if (monitors[i].name === monitor.name) break
        }
        return monitors.length === 1 ? "Monitor" : "Monitor " + externalIndex
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
        var key = slot === 10 ? "0" : String(slot)
        var lines = [displayName(monitor) + " · " + String(monitor.name), "Workspace " + slot]
        if (workspace) {
            var windowCount = workspace.toplevels.values.length
            lines.push(windowCount === 1 ? "1 janela" : windowCount + " janelas")
        } else {
            lines.push("Vazio; será criado neste monitor")
        }
        lines.push("Clique para alternar · Super+" + key + " (com integração de teclado)")
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
                    text: root.vertical ? String(monitorGroup.modelData.name).slice(0, 1).toUpperCase()
                        : root.displayName(monitorGroup.modelData)
                    fontSize: Style.font.bodySmall
                    horizontalMargin: 4
                    verticalPadding: 4
                    active: !!monitorGroup.modelData.focused
                    tooltipText: root.displayName(monitorGroup.modelData) + " · "
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
                        text: slot === 10 ? "0" : String(slot)
                        fontSize: Style.font.body
                        horizontalMargin: 5
                        verticalPadding: 4
                        dimmed: !occupied && !selected
                        active: selected
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
