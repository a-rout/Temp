; =============================================================================
; Touch Edge Gestures - Touchscreen Edge Swipe for Volume & Brightness
; =============================================================================
; Control system volume and display brightness by touch-dragging along the
; extreme edges of the touchscreen.
;
; How to use (ONE finger):
;   1. Place one finger on the RIGHT edge of the screen (last ~40 pixels)
;   2. Hold still for a brief moment (~150ms) - a tooltip confirms activation
;   3. Drag UP to increase volume, DOWN to decrease
;   4. Lift finger to confirm
;   Same on LEFT edge → Brightness control
;
; Note: Windows converts a touchscreen long-press into a right-click.
;   This script suppresses that right-click in the edge zone to prevent
;   the context menu from appearing during gestures.
;
; Setup:
;   For best results, disable Windows edge gestures:
;   Settings → Bluetooth & devices → Touch → disable "Touch screen edge gestures"
;
; Features:
;   - Right edge drag: 🔊 Volume (system master)
;   - Left edge drag: ☀️ Brightness (WMI + DDC/CI)
;   - Hold-to-activate prevents false triggers
;   - Visual OSD bar during adjustment
;   - Tray menu: Enable/Disable, Reload, Exit
;
; Hotkeys:
;   (none - touch gestures only)
; =============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

Persistent
SendMode "Input"
CoordMode "Mouse", "Screen"

; Set tray icon (speaker icon)
TraySetIcon("shell32.dll", 168)

; =============================================================================
; CONFIGURATION
; =============================================================================

; Width of the edge detection zone in pixels from each screen edge
; 40px ≈ 5mm on a typical display — easy to hit with one finger,
; narrow enough that normal scrolling won't reach this zone
global EDGE_WIDTH := 40

; Time (ms) to hold still before gesture activates
; 150ms feels instant but filters out scrolling (which moves immediately)
global HOLD_TIME_MS := 150

; Max pixel movement during hold phase to count as "holding still"
global HOLD_MOVE_THRESHOLD := 10

; Min vertical drag (px) before adjustment starts (prevents micro-adjustments)
global MIN_DRAG_PX := 20

; Tracking loop interval in ms (~60fps)
global TRACK_INTERVAL := 16

; Sensitivity: multiplier for drag-to-percentage mapping
; 1.5 = dragging 2/3 of screen height covers 0-100% range
global SENSITIVITY := 1.5

; Tooltip display time after gesture ends (ms)
global OSD_TIMEOUT := 1500

; =============================================================================
; INTERNAL STATE
; =============================================================================

; Whether edge gestures are currently active
global _gesturesEnabled := true

; Tracks whether the finger is currently holding the touchscreen/mouse down
global gIsTouchDown := false

; =============================================================================
; TRAY MENU
; =============================================================================

A_IconTip := "Touch Edge Gestures"

tray := A_TrayMenu
tray.Delete()
tray.Add("✅ Edge Gestures Enabled", ToggleEnabled)
tray.Add()
tray.Add("Reload", (*) => (Reload(), 0))
tray.Add("Exit", (*) => (ExitApp(), 0))

; =============================================================================
; HOTKEYS - Edge Zone Touch Interception
; =============================================================================

; InputLevel 1: our re-sent clicks (at default level 0) won't retrigger this
#InputLevel 1

#HotIf MouseInEdgeZone() && _gesturesEnabled
*LButton:: {
    global gIsTouchDown
    gIsTouchDown := true
    EdgeTouchHandler()
}
*RButton:: return  ; Suppress Windows long-press right-click in edge zone
#HotIf

; Reset touch state globally when finger lifts
~*LButton Up:: {
    global gIsTouchDown
    gIsTouchDown := false
}

#InputLevel 0

; =============================================================================
; MAIN FUNCTIONS
; =============================================================================

/**
 * Checks if the mouse/touch cursor is within an edge zone.
 * Called by #HotIf to conditionally intercept LButton in edge areas only.
 * @returns {Boolean} True if cursor is in the left or right edge zone
 */
MouseInEdgeZone() {
    MouseGetPos(&x, )
    return (x <= EDGE_WIDTH || x >= A_ScreenWidth - EDGE_WIDTH)
}

/**
 * Main handler for touch events in the edge zone.
 *
 * Flow:
 *   1. Hold Detection: Wait HOLD_TIME_MS for user to hold still
 *      - If finger moves too much → pass through as normal click/scroll
 *      - If finger lifts → pass through as normal tap
 *   2. Gesture Mode: Track vertical movement, adjust volume/brightness
 *      - Left edge = brightness, right edge = volume
 *      - Drag up = increase, drag down = decrease
 *   3. Release: Show final value, dismiss tooltip after delay
 */
EdgeTouchHandler() {
    MouseGetPos(&startX, &startY)
    startTick := A_TickCount

    ; Determine which edge and what to control
    isLeftEdge := (startX <= EDGE_WIDTH)
    mode := isLeftEdge ? "brightness" : "volume"
    emoji := isLeftEdge ? "☀️" : "🔊"
    label := isLeftEdge ? "Brightness" : "Volume"

    ; -------------------------------------------------------------------------
    ; Phase 1: Hold Detection
    ; -------------------------------------------------------------------------
    ; Wait for the user to hold still for HOLD_TIME_MS.
    ; Normal scrolling starts moving immediately — this filters it out.
    activated := false
    while gIsTouchDown {
        elapsed := A_TickCount - startTick
        MouseGetPos(&cx, &cy)
        moved := (Abs(cy - startY) > HOLD_MOVE_THRESHOLD
            || Abs(cx - startX) > HOLD_MOVE_THRESHOLD)

        if moved {
            ; Finger moved before hold time → normal scroll/drag, pass through
            break
        }

        if (elapsed >= HOLD_TIME_MS) {
            activated := true
            break
        }

        Sleep(10)
    }

    if !activated {
        ; Not a gesture — forward as normal touch event
        PassThroughTouch(startX, startY)
        return
    }

    ; -------------------------------------------------------------------------
    ; Phase 2: Gesture Mode
    ; -------------------------------------------------------------------------
    ; Get current level
    if (mode = "volume") {
        baseLevel := Round(SoundGetVolume())
    } else {
        baseLevel := GetCurrentBrightness()
    }

    anchorY := startY
    lastAppliedLevel := baseLevel
    dragStarted := false

    ; Show activation indicator
    ToolTip(emoji " " label ": " baseLevel "% — drag ↕")

    ; Track vertical movement until finger lifts
    while gIsTouchDown {
        MouseGetPos(, &nowY)

        ; Calculate delta: UP (negative Y) = INCREASE
        deltaY := anchorY - nowY
        absDelta := Abs(deltaY)

        ; Require minimum drag before adjusting (prevents micro-jitter)
        if (!dragStarted && absDelta < MIN_DRAG_PX) {
            Sleep(TRACK_INTERVAL)
            continue
        }
        dragStarted := true

        ; Map pixel movement to percentage change
        deltaPercent := (deltaY / A_ScreenHeight) * 100 * SENSITIVITY

        newLevel := Round(Max(0, Min(100, baseLevel + deltaPercent)))

        ; Only apply if level actually changed (reduces API calls)
        if (newLevel != lastAppliedLevel) {
            if (mode = "volume") {
                try SoundSetVolume(newLevel)
            } else {
                SetBrightnessLevel(newLevel)
            }
            lastAppliedLevel := newLevel
        }

        ; Build visual OSD bar (20 segments)
        bar := BuildOSDBar(newLevel)
        ToolTip(emoji " " label ": " newLevel "%`n" bar)

        Sleep(TRACK_INTERVAL)
    }

    ; -------------------------------------------------------------------------
    ; Phase 3: Gesture Complete
    ; -------------------------------------------------------------------------
    if dragStarted {
        bar := BuildOSDBar(lastAppliedLevel)
        ToolTip(emoji " " label " set: " lastAppliedLevel "%`n" bar)
    }
    SetTimer(() => ToolTip(), -OSD_TIMEOUT)
}

/**
 * Passes through an intercepted touch as a normal click.
 * Handles two cases:
 *   - Button still held (drag/scroll): sends LButton Down, natural Up follows
 *   - Button already released (tap): sends a complete click
 * @param {Integer} x - Original touch X position (screen coordinates)
 * @param {Integer} y - Original touch Y position (screen coordinates)
 */
PassThroughTouch(x, y) {
    if gIsTouchDown {
        ; Finger still held — it's a drag/scroll starting from the edge
        ; Send the suppressed LButton Down so the app can handle the drag
        SendInput("{LButton Down}")
        ; The physical LButton Up will pass through naturally when finger lifts
    } else {
        ; Finger already lifted — it was a quick tap
        ; Send a complete click at the original position
        Click(x, y)
    }
}

/**
 * Builds a visual bar string for the OSD tooltip.
 * @param {Integer} level - Current level percentage (0-100)
 * @returns {String} A bar like "████████████░░░░░░░░"
 */
BuildOSDBar(level) {
    filled := Round(level / 5)  ; 20 segments total
    empty := 20 - filled
    bar := ""
    loop filled
        bar .= "█"
    loop empty
        bar .= "░"
    return bar
}

; =============================================================================
; BRIGHTNESS FUNCTIONS
; =============================================================================

/**
 * Gets the current display brightness level.
 * Tries WMI first (laptop internal display), then DDC/CI (external monitor).
 * @returns {Integer} Current brightness percentage (0-100)
 */
GetCurrentBrightness() {
    ; Try WMI (laptop internal displays)
    try {
        wmi := ComObjGet("winmgmts:\\.\root\wmi")
        for monitor in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightness") {
            return monitor.CurrentBrightness
        }
    } catch {
        ; Ignore and fall back to DDC/CI
    }

    ; Try DDC/CI (external monitors via Dxva2.dll)
    try {
        ; MONITOR_DEFAULTTOPRIMARY = 1
        hMonitor := DllCall("user32\MonitorFromPoint", "Int64", 0, "UInt", 1, "Ptr")
        if !hMonitor
            return 50

        numPhysical := 0
        DllCall("dxva2\GetNumberOfPhysicalMonitorsFromHMONITOR"
            , "Ptr", hMonitor, "UInt*", &numPhysical)
        if !numPhysical
            return 50

        ; PHYSICAL_MONITOR struct: Ptr handle + 128 WCHAR description
        structSize := A_PtrSize + 256
        buf := Buffer(numPhysical * structSize, 0)
        DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR"
            , "Ptr", hMonitor, "UInt", numPhysical, "Ptr", buf)

        hPhysMon := NumGet(buf, 0, "Ptr")
        minB := 0, currB := 0, maxB := 0
        DllCall("dxva2\GetMonitorBrightness"
            , "Ptr", hPhysMon
            , "UInt*", &minB, "UInt*", &currB, "UInt*", &maxB)

        DllCall("dxva2\DestroyPhysicalMonitors", "UInt", numPhysical, "Ptr", buf)
        return maxB > 0 ? Round((currB / maxB) * 100) : currB
    } catch {
        ; Ignore and return default
    }

    return 50  ; Default fallback if both methods fail
}

/**
 * Sets display brightness to a specific percentage level.
 * Tries WMI first (laptop), then DDC/CI (external monitor).
 * @param {Integer} level - Target brightness percentage (0-100)
 */
SetBrightnessLevel(level) {
    level := Max(0, Min(100, level))

    ; Try WMI (laptop internal displays)
    try {
        wmi := ComObjGet("winmgmts:\\.\root\wmi")
        for method in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods") {
            method.WmiSetBrightness(0, level)
            return
        }
    } catch {
        ; Ignore and fall back to DDC/CI
    }

    ; Try DDC/CI (external monitors)
    try {
        hMonitor := DllCall("user32\MonitorFromPoint", "Int64", 0, "UInt", 1, "Ptr")
        if !hMonitor
            return

        numPhysical := 0
        DllCall("dxva2\GetNumberOfPhysicalMonitorsFromHMONITOR"
            , "Ptr", hMonitor, "UInt*", &numPhysical)
        if !numPhysical
            return

        structSize := A_PtrSize + 256
        buf := Buffer(numPhysical * structSize, 0)
        DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR"
            , "Ptr", hMonitor, "UInt", numPhysical, "Ptr", buf)

        hPhysMon := NumGet(buf, 0, "Ptr")

        ; Get min/max to map percentage to the monitor's actual range
        minB := 0, currB := 0, maxB := 0
        DllCall("dxva2\GetMonitorBrightness"
            , "Ptr", hPhysMon
            , "UInt*", &minB, "UInt*", &currB, "UInt*", &maxB)

        ; Map our 0-100% to the monitor's min-max range
        actualLevel := Round(minB + (level / 100) * (maxB - minB))
        DllCall("dxva2\SetMonitorBrightness"
            , "Ptr", hPhysMon, "UInt", actualLevel)

        DllCall("dxva2\DestroyPhysicalMonitors", "UInt", numPhysical, "Ptr", buf)
    } catch {
        ; Ignore
    }
}

; =============================================================================
; TRAY MENU FUNCTIONS
; =============================================================================

/**
 * Toggles edge gesture detection on/off from the tray menu.
 * Updates the menu label to show current state.
 * @param {String} itemName - Current menu item text
 * @param {Integer} itemPos - Menu item position
 * @param {Menu} myMenu - Reference to the tray menu
 */
ToggleEnabled(itemName, itemPos, myMenu) {
    global _gesturesEnabled
    _gesturesEnabled := !_gesturesEnabled
    myMenu.Rename(itemName, _gesturesEnabled
        ? "✅ Edge Gestures Enabled"
        : "❌ Edge Gestures Disabled")
    ToolTip(_gesturesEnabled ? "Edge gestures ON" : "Edge gestures OFF")
    SetTimer(() => ToolTip(), -OSD_TIMEOUT)
}

; =============================================================================
; STARTUP
; =============================================================================

ToolTip("Touch Edge Gestures ready"
    . "`nRight edge: 🔊 Volume"
    . "`nLeft edge:  ☀️ Brightness"
    . "`n"
    . "`nOne finger: touch edge → hold briefly → drag ↕"
    . "`nEdge zone: " EDGE_WIDTH "px from each side")
SetTimer(() => ToolTip(), -4000)
