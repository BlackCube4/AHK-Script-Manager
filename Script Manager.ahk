; edited by BlackCube
; https://www.autohotkey.com/board/topic/38653-see-running-autohotkey-scripts-and-end-them
; http://www.autohotkey.com/board/topic/95550-how-to-get-a-list-of-autohotkey-scripts-running/
; http://www.xp-waste.com/post23929.html#p23929

#Include supportScripts\GetClientSize.ahk

DetectHiddenWindows, On
#SingleInstance Force
Menu, tray, Icon , Script Manager.ico
CurrentIcon:="normal"
OnExit, ExitLabel

standardWidth := "435"
standardHeight := "202"
setini:=A_ScriptDir . "\settings.ini"
IniRead, lastX, settings.ini, guiSettings, lastX, %A_Space%
IniRead, lastY, settings.ini, guiSettings, lastY, %A_Space%
IniRead, lastWidth, settings.ini, guiSettings, lastWidth, %standardWidth%
IniRead, lastHeight, settings.ini, guiSettings, lastHeight, %standardHeight%

listWidth:=lastWidth-20
listHeight:=lastHeight-55

Gui, Destroy
Gui, New, +HwndguiID, Script Manager
Gui, Margin, 10, 10
Gui, +Resize +MinSize435x202

Gui, Add, ListView, x11 w%listWidth% h%listHeight% vlvwList hwndhlvwList gListClick, Name|Script Path|PID|Working Set|Peak Working Set|Page File|Peak Page File

Gui, Add, Button, x10 y+5 w90 h30 hwndhRefresh gRefresh, Refresh List
Gui, Add, Button, yp x+5 w60 hp hwndhEndProc gCloseScript, Close
Gui, Add, Button, yp x+5 wp hp hwndhEndProc gPause, Pause
Gui, Add, Button, yp x+5 wp hp hwndhEndProc gSuspend, Suspend
Gui, Add, Button, yp x+5 wp hp hwndhEndProc gEdit, Edit
Gui, Add, Button, yp x+5 wp hp hwndhEndProc gReload, Reload

if (lastX="" or lastY="")
	Gui, Show, % "w" . lastWidth . " h" . lastHeight
else
	Gui, Show, % "x" . lastX . " y" . lastY . " w" . lastWidth . " h" . lastHeight

RefreshList()
Return

GuiClose:
	WinGetPos, guiX, guiY, , , ahk_id %guiID%
	GetClientSize(guiID, guiW, guiH)
	IniWrite, %guiX%, %setini%, guiSettings, lastX
	IniWrite, %guiY%, %setini%, guiSettings, lastY
	IniWrite, %guiW%, %setini%, guiSettings, lastWidth
	IniWrite, %guiH%, %setini%, guiSettings, lastHeight
	ExitApp
return

ExitLabel:
	ExitApp
return

Refresh:
    RefreshList()
Return

ListClick:
    If (A_GuiEvent <> "DoubleClick")
        Return
	startingRow := LV_GetNext()
	LV_GetText(rowAhkID, startingRow, 3)
	Process, Close, %rowAhkID%
Return

CloseScript:
    startingRow:=0
	loop % LV_GetCount("Selected")
	{
		startingRow := LV_GetNext(startingRow)
		LV_GetText(rowAhkID, startingRow, 3)
		Process, Close, %rowAhkID%
	}
    RefreshList()
Return

Pause:
	startingRow:=0
	loop % LV_GetCount("Selected")
	{
		startingRow := LV_GetNext(startingRow)
		LV_GetText(rowPath, startingRow, 2)
		PostMessage, 0x111, 65306,,, % rowPath
		;PostMessage, 0x0111, 65403,,, % rowPath
	}
Return

Suspend:
	startingRow:=0
	loop % LV_GetCount("Selected")
	{
		startingRow := LV_GetNext(startingRow)
		LV_GetText(rowPath, startingRow, 2)
		PostMessage, 0x111, 65305,,, % rowPath
		;PostMessage, 0x0111, 65404,,, % rowPath
	}
Return

Edit:
	IniRead, defaultEditor, %setini%, defaultEditor, 1, %A_Space%
	if (defaultEditor="") {
		FileSelectFile defaultEditor, 3,, Select your editor, Programs (*.exe)
		if ErrorLevel
			return
		IniWrite, %defaultEditor%, %setini%, defaultEditor, 1
		RegWrite REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\Command,, %defaultEditor% "`%1"
	}
	startingRow:=0
	loop % LV_GetCount("Selected")
	{
		startingRow := LV_GetNext(startingRow)
		LV_GetText(rowName, startingRow, 1)
		LV_GetText(rowPath, startingRow, 2)
		type := SubStr(rowPath, -2 , 3)
		if (type = "exe") {
			msgbox, %rowName% is compiled and can't be edited.
			continue
		}
		Run, % """" . defaultEditor . """" . " " . """" . rowPath . """"
	}
return

Reload:
	startingRow:=0
	loop % LV_GetCount("Selected")
	{
		startingRow := LV_GetNext(startingRow)
		LV_GetText(rowPath, startingRow, 2)
		Run, "%A_AHKPath%" /restart "%rowPath%"
	}
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

	GuiControl, Move, lvwList, % ("w" initSize.Edit1.w + changedW) . (" h" initSize.Edit1.h + changedH)
	GuiControl, Move, Button1, % ("y" initSize.Button1.y + changedH)
	GuiControl, Move, Button2, % ("y" initSize.Button2.y + changedH)
	GuiControl, Move, Button3, % ("y" initSize.Button3.y + changedH)
	GuiControl, Move, Button4, % ("y" initSize.Button4.y + changedH)
	GuiControl, Move, Button5, % ("y" initSize.Button5.y + changedH)
	GuiControl, Move, Button6, % ("y" initSize.Button6.y + changedH)

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

	Loop 7
		LV_ModifyCol(A_Index, "AutoHdr")
	
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