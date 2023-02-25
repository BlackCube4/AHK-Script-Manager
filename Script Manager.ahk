; edited by BlackCube
; https://www.autohotkey.com/board/topic/38653-see-running-autohotkey-scripts-and-end-them
; http://www.autohotkey.com/board/topic/95550-how-to-get-a-list-of-autohotkey-scripts-running/
; http://www.xp-waste.com/post23929.html#p23929

DetectHiddenWindows, On
#SingleInstance Force
Menu, tray, Icon , Script Manager.ico

Gui, Destroy
Gui, New , , Script Manager
Gui, Margin, 10, 10
Gui, +Resize +MinSize435x202

Gui, Add, ListView, x11 w413 vlvwList hwndhlvwList gListClick, Name|Script Path|PID|Working Set|Peak Working Set|Page File|Peak Page File

Gui, Add, Button, x10 y+5 w90 h30 hwndhRefresh gRefresh, Refresh List
Gui, Add, Button, yp x+5 w60 hp hwndhEndProc gEndProc, Close
Gui, Add, Button, yp x+5 wp hp hwndhEndProc gPause, Pause
Gui, Add, Button, yp x+5 wp hp hwndhEndProc gSuspend, Suspend
Gui, Add, Button, yp x+5 wp hp hwndhEndProc gEdit, Edit
Gui, Add, Button, yp x+5 wp hp hwndhEndProc gReload, Reload

;Gui, Show, w434 h202 Hide

Gui, Show, ;w434 h202
RefreshList()
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

Pause:
	i := LV_GetNext()
	;PostMessage, 0x111, 65306,,, % GetScriptPathFromHwnd(AHKWindows%i%)
	PostMessage, 0x0111, 65403,,, % GetScriptPathFromHwnd(AHKWindows%i%)
Return

Suspend:
	i := LV_GetNext()
	;PostMessage, 0x111, 65305,,, % GetScriptPathFromHwnd(AHKWindows%i%)
	PostMessage, 0x0111, 65404,,, % GetScriptPathFromHwnd(AHKWindows%i%)
Return

Edit:
	i := LV_GetNext()
    Run, % "notepad.exe " . GetScriptPathFromHwnd(AHKWindows%i%)
return

Reload:
	i := LV_GetNext()
    Run, % GetScriptPathFromHwnd(AHKWindows%i%)
return

GuiSize:
	if !initSize {
		GuiControlGet, c1, Pos, lvwList
		GuiControlGet, c2, Pos, Button1
		GuiControlGet, c3, Pos, Button2
		GuiControlGet, c4, Pos, Button3
		GuiControlGet, c5, Pos, Button4
		GuiControlGet, c6, Pos, Button5
		GuiControlGet, c7, Pos, Button6
		initSize := { "gui"    : {w:A_GuiWidth, h:A_GuiHeight}
		            , "Edit1"  : {x:c1X, y:c1Y, w:c1W, h:c1H}
		            , "Button1": {x:c2X, y:c2Y, w:c2W, h:c2H}
		            , "Button2": {x:c3X, y:c3Y, w:c3W, h:c3H}
					, "Button3": {x:c4X, y:c4Y, w:c4W, h:c4H}
					, "Button4": {x:c5X, y:c5Y, w:c5W, h:c5H}
					, "Button5": {x:c6X, y:c6Y, w:c6W, h:c6H}
					, "Button6": {x:c7X, y:c7Y, w:c7W, h:c7H} }
		lastGuiW := A_GuiWidth
		lastGuiH := A_GuiHeight
		return
	}

	if (A_EventInfo = 1)  ; The window has been minimized.
	|| (A_GuiWidth = lastGuiW && A_GuiHeight = lastGuiH) { ; The window has been restored (from minimized state)
		return
	}

	changedW := A_GuiWidth  - initSize.gui.w
	changedH := A_GuiHeight - initSize.gui.h

	GuiControl, Move, lvwList, % ("w" initSize.Edit1.w   + changedW) . (" h" initSize.Edit1.h   + changedH)
	GuiControl, Move, Button1  , % ("y" initSize.Button1.y + changedH)
	GuiControl, Move, Button2  , % ("y" initSize.Button2.y + changedH)
	GuiControl, Move, Button3  , % ("y" initSize.Button3.y + changedH)
	GuiControl, Move, Button4  , % ("y" initSize.Button4.y + changedH)
	GuiControl, Move, Button5  , % ("y" initSize.Button5.y + changedH)
	GuiControl, Move, Button6  , % ("y" initSize.Button6.y + changedH)

	lastGuiW := A_GuiWidth
	lastGuiH := A_GuiHeight
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
        LV_Add(0, GetScriptNameFromHwnd(AHKWindows%A_Index%)
		, GetScriptPathFromHwnd(AHKWindows%A_Index%)
		, AHKWindows%A_Index%_PID
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
	GuiControl, +ReDraw, lvwList
}

GetScriptPathFromHwnd(hwnd) {
    WinGetTitle, win, ahk_id %hwnd%
    Return RegExMatch(win, ".*(?= - AutoHotkey v[0-9\.]+)", ret) ? ret : win
}

GetScriptNameFromHwnd(hwnd) {
    WinGetTitle, win, ahk_id %hwnd%
	if !RegExMatch(win, ".*\\(.*).ahk - AutoHotkey v[0-9\.]+", SubPart)
		RegExMatch(win, ".*\\(.*).{4}", SubPart)
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