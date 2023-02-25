; written by Wicked
; http://www.xp-waste.com/post23929.html#p23929
; https://www.autohotkey.com/board/topic/95550-how-to-get-a-list-of-autohotkey-scripts-running/

_Process:=Object()

Gui, 1: Margin, 5, 5
Gui, 1: Add, ListView, w310 h200 AltSubmit NoSortHdr vListView, Name|PID
Gui, 1: Add, Button, x+-310 y+5 w100 h25, Search
Gui, 1: Add, Button, x+5 y+-25 w100 h25, Reload
Gui, 1: Add, Button, x+5 y+-25 w100 h25, Close


ButtonSearch:
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
				  ,Extract_Script_Path_From_CommandLine(Process.CommandLine),Process.ProcessId]
            LV_Add("", _Process[_Processes,1],Process.ProcessId)
        }
    }
    GuiControl, +ReDraw, ListView
return


ButtonReload:
    If !LV_GetNext(0)
        Return
    _ScriptDIR:=_Process[LV_GetNext(0),2]
    Run, "%A_AHKPath%" /restart "%_ScriptDIR%"
    Sleep (500)
    GoSub, ButtonSearch
Return

ButtonClose:
    If !LV_GetNext(0)
        Return
    Process,Close, % _Process[LV_GetNext(0),3]
    Sleep (500)
    GoSub, ButtonSearch
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