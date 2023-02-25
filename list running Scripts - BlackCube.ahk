; edited by BlackCube
; https://www.autohotkey.com/board/topic/38653-see-running-autohotkey-scripts-and-end-them/page-2
; http://www.autohotkey.com/board/topic/95550-how-to-get-a-list-of-autohotkey-scripts-running/
; http://www.xp-waste.com/post23929.html#p23929

DetectHiddenWindows, On
#SingleInstance Force

Gui, Destroy
Gui, New , HwndListRunningScripts, List running Scripts

Gui, -Resize -MaximizeBox
Gui, Add, ListView, w500 h200 vlvwList hwndhlvwList gListClick, PID|Name|Script Path|Working Set|Peak Working Set|Page File|Peak Page File

Gui, Add, Button, y+6 xp w247 h30 hwndhRefresh gRefresh, Refresh list
Gui, Add, Button, yp x+6 wp h30 hwndhEndProc gEndProc, End associated process

Gui, Show, Hide
RefreshList()
Gui, Show, w520
Return

GuiClose:
ExitApp

Refresh:
    RefreshList()
Return

ListClick:
    If (A_GuiEvent <> "DoubleClick")
        Return
EndProc:
    
    i := LV_GetNext()
    WinKill, % "ahk_id " AHKWindows%i%
    RefreshList()
    
Return

RefreshList() {
    Global
    
    LV_Delete()
    WinGet, AHKWindows, List, ahk_class AutoHotkey
    
    Loop %AHKWindows% {
        
        ;Get process ID
        WinGet, AHKWindows%A_Index%_PID, PID, % "ahk_id " AHKWindows%A_Index%
        GetProcessMemoryInfo(AHKWindows%A_Index%_PID)
        
        ;Get memory info
        LV_Add(0, AHKWindows%A_Index%_PID, GetScriptNameFromHwnd(AHKWindows%A_Index%), GetScriptPathFromHwnd(AHKWindows%A_Index%)
        , Round(GetProcessMemoryInfo(0,12) / 1024) " K", Round(GetProcessMemoryInfo(0,8) / 1024) " K"
        , Round(GetProcessMemoryInfo(0,32) / 1024) " K", Round(GetProcessMemoryInfo(0,36) / 1024) " K")
    }
    
    Loop 6
        LV_ModifyCol(A_Index, "AutoHdr")
    
    ;Get columns width
    iColWidth := 0
    Loop 6 {
        SendMessage, 4125, A_Index - 1, 0,, ahk_id %hlvwList%
        iColWidth += ErrorLevel
    }
	WinSet, Redraw ,, List running Scripts
}

GetScriptPathFromHwnd(hwnd) {
    WinGetTitle, win, ahk_id %hwnd%
    Return RegExMatch(win, ".*(?= - AutoHotkey v[0-9\.]+)", ret) ? ret : win
}

GetScriptNameFromHwnd(hwnd) {
    WinGetTitle, win, ahk_id %hwnd%
	RegExMatch(win, ".*\\(.*).ahk - AutoHotkey v[0-9\.]+", SubPart)
    Return %SubPart1%
}

GetProcessMemoryInfo(pid, info=-1) {
    Static uMemCounters := 0
    
    ;Check if we just want info from the struct
    If (info <> -1)
        Return NumGet(uMemCounters, info)
    Else {
        
        ;Open the process with PROCESS_QUERY_INFORMATION and PROCESS_VM_READ
        h := DllCall("OpenProcess", "UInt", 0x0410, "UInt", 0, "UInt", pid)
        
        ;Put info into struct
        If Not uMemCounters ;Check if it hasn't already been initialized
            VarSetCapacity(uMemCounters, 40)
        DllCall("Psapi.dll\GetProcessMemoryInfo", "UInt", h, "UInt", &uMemCounters, "UInt", 40)
        
        ;Done
        DllCall("CloseHandle", "UInt", h)
    }
}