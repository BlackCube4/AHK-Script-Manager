; edited by BlackCube
; https://www.autohotkey.com/board/topic/38653-see-running-autohotkey-scripts-and-end-them/page-2
; http://www.autohotkey.com/board/topic/95550-how-to-get-a-list-of-autohotkey-scripts-running/
; http://www.xp-waste.com/post23929.html#p23929

; Image Buttons by AHK-just-me
; https://github.com/AHK-just-me/Class_ImageButton
; https://www.autohotkey.com/boards/viewtopic.php?t=1103
; /board/topic/75064-function-createimagebutton-ahk-l/

DetectHiddenWindows, On
#SingleInstance Force
#Include Image Buttons/Class_ImageButton.ahk
#Include Image Buttons/UseGDIP.ahk

Gui, Destroy
Gui, New , HwndListRunningScripts, List running Scripts
DllCall("dwmapi\DwmSetWindowAttribute", "ptr", ListRunningScripts, "int", "20", "int*", true, "int", 4)
GuiColor := "0x191919"
GuiElementsColor := "0x333333"
GuiElementsBorderColor := "0x454545"
GuiElementsRadius := 5
Gui, Margin, 10, 10
Gui, Font, s10 cffffff q4, ;Segoe UI
Gui, Color, %GuiColor%, %GuiElementsColor%
ImageButton.SetGuiColor(GuiColor)

;Options for Buttons
Opt1 := [0, GuiElementsColor, , "White", GuiElementsRadius, , GuiElementsBorderColor, 1]
Opt2 := [0, 0x414141]
	
Gui, -Resize -MaximizeBox
Gui, Add, Progress, w500 h200 Background%GuiElementsBorderColor% vBackground, 0
Gui, Add, ListView, x+-499 y+-199 w498 h198 vlvwList hwndhlvwList gListClick -E0x200 -Border, PID|Name|Script Path|Working Set|Peak Working Set|Page File|Peak Page File
GuiControl, Disable, Background
DllCall("uxtheme\SetWindowTheme", "ptr", hlvwList, "str", "DarkMode_Explorer", "ptr", 0)

Gui, Add, Button, y+6 w247 h30 hwndhRefresh gRefresh, Refresh list
ImageButton.Create(hRefresh, Opt1, Opt2, , , Opt1)
Gui, Add, Button, x+6 w247 h30 hwndhEndProc gEndProc, End associated process
ImageButton.Create(hEndProc, Opt1, Opt2, , , Opt1)

Gui, Show, Hide
RefreshList()
Gui, Show,
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