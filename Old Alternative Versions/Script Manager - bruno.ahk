; edited by bruno
; https://www.autohotkey.com/board/topic/38653-see-running-autohotkey-scripts-and-end-them/page-2
; http://www.autohotkey.com/board/topic/95550-how-to-get-a-list-of-autohotkey-scripts-running/
; http://www.xp-waste.com/post23929.html#p23929
; https://www.autohotkey.com/board/topic/4105-control-anchoring-v4-for-resizing-windows/page-6

#SingleInstance Force
#NoEnv

_Process:=Object()

Gui, 1: Margin, 5, 5
Gui, 1: Add, ListView, w277 h250 AltSubmit NoSortHdr vListView gListView, Name|PID
;Gui, 1: Add, ListView, w277 h250 AltSubmit NoSortHdr vListView, Name|PID
Gui, 1: Add, Button, x+-277 y+5 w50 h20, Refresh
Gui, 1: Add, Button, x+0 y+-20 w50 h20, Reload
Gui, 1: Add, Button, x+0 y+-20 w50 h20, Close
Gui, 1: Add, Button, x+0 y+-20 w50 h20, Save
Gui, 1: Add, Button, x+0 y+-20 w50 h20, Edit
Gui, 1: Add, Button, x+-250 y+0 w50 h20, Pause
Gui, 1: Add, Button, x+0 y+-20 w50 h20, Suspend
Menu, MyContextMenu, Add, Refresh, ButtonRefresh
Menu, MyContextMenu, Add, Reload, ButtonReload
Menu, MyContextMenu, Add, Close, ButtonClose
Menu, MyContextMenu, Add, Save, ButtonSave
Menu, MyContextMenu, Add, Edit, ButtonEdit
Menu, MyContextMenu, Add, Pause, ButtonPause
Menu, MyContextMenu, Add, Suspend, ButtonSuspend
LV_ModifyCol()

ButtonRefresh:
  Gui, 1: Show
    LV_Delete()
    _Processes:=0
    _Process.Remove(0,_Process.MaxIndex())
    GuiControl, -ReDraw, ListView
    For Process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='AutoHotkey.exe'")
    {
        If(Process.ExecutablePath==A_AHKPath)
        {
            _Processes++
            _Process[_Processes]:=[Extract_Script_Name_From_CommandLine(Process.CommandLine)
                  ,Extract_Script_Path_From_CommandLine(Process.CommandLine),Process.ProcessID]
            LV_Add("",_Process[_Processes,1],Process.ProcessID)
        }
    }
    LV_ModifyCol()
    GuiControl, +ReDraw, ListView
Return

ButtonSave:
t := ""
Loop % LV_GetCount()
{
    LV_GetText(OutputVar1,A_Index,1)
    LV_GetText(OutputVar2,A_Index,2)
    t .= OutputVar1 A_Space OutputVar2 "`n"
}
/*
MsgBox % "Would you like to save this file to Clipboard? `n`n" t
IfMsgBox, Yes
Clipboard := t
; FileAppend, %t%, Running_Scripts.txt
*/
;MsgBox, "Would you like to save this file to Clipboard? `n`n" t
MsgBox, 262212, `n`n" t, Would you like to save this file to Clipboard? ; 262208+4
IfMsgBox, Yes, GoTo MN
IfMsgBox, No, Return
MN:
Clipboard := t
; FileAppend, %t%, Running_Scripts.txt
Return
/*
ButtonReload:
  If !LV_GetNext(0)
        Return
    _ScriptDIR:=_Process[LV_GetNext(0),2]
    Run, "%A_AHKPath%" /restart "%_ScriptDIR%"
    Sleep (500)
    GoSub, ButtonRefresh
Return
*/
ButtonReload:
  If !LV_GetNext(0)
        Return
RowNumber = 0 ; This causes the first loop iteration to start the search at the top of the list
Loop
{
    RowNumber := LV_GetNext(RowNumber) ; Resume the search at the row after that found by the previous iteration
    If NOT RowNumber
        Break
    ;LV_GetText(Text, RowNumber)
    ;MsgBox, The next selected row is #%RowNumber%, whose first field is "%Text%".
    _ScriptDIR:=_Process[LV_GetNext(RowNumber-1),2]
    Run, "%A_AHKPath%" /restart "%_ScriptDIR%"
    Sleep (500)
}
GoSub, ButtonRefresh
Return
/*
ButtonEdit:
  If !LV_GetNext(0)
        Return
    _ScriptDIR:=_Process[LV_GetNext(0),2]
    ;Run, "%A_AHKPath%" /restart "%_ScriptDIR%"
;MsgBox % _ScriptDIR
Run, Notepad.exe %_ScriptDIR%
Return
*/
ButtonEdit:
  If !LV_GetNext(0)
        Return
RowNumber = 0
Loop
{
    RowNumber := LV_GetNext(RowNumber)
    If NOT RowNumber
        Break
    _ScriptDIR:=_Process[LV_GetNext(RowNumber-1),2]
    Run, Notepad.exe %_ScriptDIR%
    Sleep (500)
}
Return
/*
ButtonClose:
  If !LV_GetNext(0)
        Return
    Process, Close, % _Process[LV_GetNext(0),3]
    Sleep (500)
    GoSub, ButtonRefresh
Return
*/
ButtonClose:
  If !LV_GetNext(0)
        Return
RowNumber = 0
Loop
{
    RowNumber := LV_GetNext(RowNumber)
    If NOT RowNumber
        Break
    Process, Close, % _Process[LV_GetNext(RowNumber-1),3]
    Sleep (500)
}
GoSub, ButtonRefresh
Return

ButtonPause:
WM_COMMAND := 0x111
CMD_RELOAD := 65400
CMD_EDIT := 65401
CMD_PAUSE := 65403
CMD_SUSPEND := 65404
DetectHiddenWindows, On
  If !LV_GetNext(0)
        Return
RowNumber = 0
Loop
{
    RowNumber := LV_GetNext(RowNumber)
    If NOT RowNumber
        Break
;MsgBox % _Process[LV_GetNext(RowNumber-1),3]
GoSub, CMDP
    Sleep (500)
}
Return
CMDP:
Process, Exist
this_pid := _Process[LV_GetNext(RowNumber-1),3]
control_id := WinExist("ahk_class AutoHotkey ahk_pid " this_pid)
WinGet, id, list, ahk_class AutoHotkey
Loop, %id%
{
	this_id := id%A_Index%
    If (this_id = control_id)
	{
		PostMessage, WM_COMMAND, CMD_PAUSE,,, ahk_id %this_id%
		;PostMessage, WM_COMMAND, CMD_SUSPEND,,, ahk_id %this_id%
	}
}
Return

ButtonSuspend:
WM_COMMAND := 0x111
CMD_RELOAD := 65400
CMD_EDIT := 65401
CMD_PAUSE := 65403
CMD_SUSPEND := 65404
DetectHiddenWindows, On
  If !LV_GetNext(0)
        Return
RowNumber = 0
Loop
{
    RowNumber := LV_GetNext(RowNumber)
    If NOT RowNumber
        Break
;MsgBox % _Process[LV_GetNext(RowNumber-1),3]
GoSub, CMDS
    Sleep (500)
}
Return
CMDS:
Process, Exist
this_pid := _Process[LV_GetNext(RowNumber-1),3]
control_id := WinExist("ahk_class AutoHotkey ahk_pid " this_pid)
WinGet, id, list, ahk_class AutoHotkey
Loop, %id%
{
	this_id := id%A_Index%
    If (this_id = control_id)
	{
		;PostMessage, WM_COMMAND, CMD_PAUSE,,, ahk_id %this_id%
		PostMessage, WM_COMMAND, CMD_SUSPEND,,, ahk_id %this_id%
	}
}
Return

ListView:
If A_GuiEvent = DoubleClick
GoSub, ButtonEdit
Return

GuiContextMenu: ; Launched in response to a right-click:
If A_GuiControl <> ListView ; Display the menu only for clicks inside the ListView
Return
; Show the menu at the provided coordinates, A_GuiX and A_GuiY:
Menu, MyContextMenu, Show
Return

GuiControl,, Refresh,
GuiControl,, Reload,
GuiControl,, Close,
GuiControl,, Save,
GuiControl,, Edit,
GuiControl,, Pause,
GuiControl,, Suspend,
Return

Extract_Script_Name_From_CommandLine(P) {
    StringSplit,R,P,"
    SplitPath,R4,F
    Return F
}

Extract_Script_Path_From_CommandLine(P) {
    StringSplit,R,P,"
    Return R4
}

^Esc::ExitApp