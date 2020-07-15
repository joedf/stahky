; stahky
; by joedf - 2020.07.10
;
; inspried from Stacky (by Pawel Turlejski)
; https://github.com/pawelt/stacky
; https://web.archive.org/web/20130927190146/http://justafewlines.com/2013/04/stacky/


; https://www.autohotkey.com/docs/misc/Performance.htm
#NoEnv
SetBatchLines -1
ListLines Off

#NoTrayIcon
#SingleInstance, Force

#Include lib\utils.ahk

; uses PUM by Deo
#Include lib\PUM_API.ahk
#Include lib\PUM.ahk

APP_NAME := "stahky"
APP_VERSION := "0.1.0.5"
APP_REVISION := "2020/07/15"

;@Ahk2Exe-SetName stahky
;@Ahk2Exe-SetVersion 0.1.0.5
;@Ahk2Exe-SetDescription A take on stacky in AutoHotkey (AHK) for Windows 10
;@Ahk2Exe-SetCopyright (c) 2020 joedf@ahkscript.org
;@Ahk2Exe-SetCompanyName joedf.ahkscript.org
;@Ahk2Exe-SetMainIcon res\app.ico

; Trick to use mpress and throw no error if not available
;@Ahk2Exe-PostExec cmd /c mpress.exe "%A_WorkFileName%" &rem, 0


STAHKY_EXT := APP_NAME . ".lnk"
G_STAHKY_ARG := "/stahky"
StahkyConfigFile := A_ScriptDir "\" APP_NAME ".ini"

; AutoHotkey behavioural settings needed
GroupAdd APP_Self_WinGroup, ahk_id %A_ScriptHwnd%
GroupAdd APP_Self_WinGroup, % "ahk_pid " DllCall("GetCurrentProcessId")
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
MouseGetPos, mx, my

; Smart auto-create *lnk pinnable shortcut file, when folder dragged-on-top of this app
if ( (A_Args[1] != G_STAHKY_ARG) && (FileExist(A_Args[1])) )
{
	FileGetAttrib,_t, % A_Args[1]
	if InStr(_t,"D") {
		makeStahkyFile(A_Args[1])
		; we're done here! don't execute the rest of the program ... arrrgg >_<
		ExitApp
	}
}

; check for first run, if we want to show the intro dialog
G_FirstRun_Trigger := false
if !FileExist(StahkyConfigFile)
	FirstRun_Trigger()

; get search path
searchPath := A_WorkingDir . "\*"
; use the Stahky file's path if available
if ( (A_Args[1] == G_STAHKY_ARG) && (FileExist(A_Args[2])) )
{
	FileGetAttrib,_t, % A_Args[2]
	if InStr(_t,"D") {
		searchPath := A_Args[2] . "\*"
	} else {
		; warn user and exit if it's not a folder .... wut -,-
		MsgBox, 48, %APP_NAME% - Error: Invalid stahky config, Error: Could not launch stahky as the following target folder was not found:`n%outTarget%
		ExitApp
	}
}

; get automatic colors
PixelGetColor, TaskbarColor, % A_ScreenWidth - 2, % A_ScreenHeight - 2, RGB
TaskbarSColor := lightenColor(TaskbarColor)
TaskbarTColor := contrastBW(TaskbarSColor)

; get/update settings
loadSettings(StahkyConfigFile)
saveSettings(StahkyConfigFile)

; update value for High DPI display
DPIScaleRatio := 1
if (useDPIScaleRatio) {
	DPIScaleRatio := (A_ScreenDPI / 96)
	icoSize *= DPIScaleRatio
	menuTextMargin *= DPIScaleRatio
	menuMarginX *= DPIScaleRatio
	menuMarginY *= DPIScaleRatio
}

; parameters of the PUM object, the manager of the menus
pumParams := {"SelMethod" : "fill" ;item selection method, may be frame,fill
	,"selTColor"   : stextColor    ;selection text color
	,"selBGColor"  : sbgColor      ;selection background color, -1 means invert current color
	,"oninit"      : "PUM_out"     ;function which will be called when any menu going to be opened
	,"onuninit"    : "PUM_out"     ;function which will be called when any menu going to be closing
	,"onselect"    : "PUM_out"     ;function which will be called when any item selected with mouse (hovered)
	,"onrbutton"   : "PUM_out"     ;function which will be called when any item right clicked
	,"onmbutton"   : "PUM_out"     ;function which will be called when any item clicked with middle mouse button
	,"onrun"       : "PUM_out"     ;function which will be called when any item clicked with left mouse button
	,"onshow"      : "PUM_out"     ;function which will be called before any menu shown using Show method
	,"onclose"     : "Pum_out"     ;function called just before quitting from Show method
	,mnemonicCMD   : "select"}

; PUM_Menu parameters
menuParams := {"bgcolor" : bgColor ;background color of the menu
	, "iconssize" : icoSize        ;size of icons in the menu
	, "tcolor"    : textColor      ;text color of the menu items
	, "textMargin": menuTextMargin
	, "xmargin"   : menuMarginX
	, "ymargin"   : menuMarginY }

; create an instance of PUM object, it is best to have only one of such in the program
pm := new PUM( pumParams )
; creating popup menu, represented by PUM_Menu object with given parameters
menu := pm.CreateMenu( menuParams )

; Log start time to prevent runs from taking too long with no visual feedback
STAHKY_START_TIME := A_TickCount

; Populate Stahkys!
MakeStahkyMenu(menu, searchPath, pm, menuParams )

; Calculate postion of the menu near the Taskbar
SysGet m, MonitorWorkArea, 1
mpy := mBottom
menuWidth := menuTextMargin + icoSize + (2.5*menuMarginX)
mpx := mx - ( menuWidth//DPIScaleRatio )

; Display the PUM menu
item := menu.Show( mpx+offsetX, mpy+offsetY )

; Destroy everything PUM on program end
pm.Destroy()

; First Run triggered - don't auto-exit
if (!G_FirstRun_Trigger)
	ExitApp
return


; PUM's right-click / rbutton handler is not reliable
; do some extra handling here
; https://autohotkey.com/board/topic/94970-ifwinactive-reference-running-autohotkey-window/#entry598885
;
; No need for #If since the app only runs if we have a menu or a window shown
;#IfWinExist ahk_group APP_Self_WinGroup
+#a::
~$*RButton::
	FirstRun_Trigger()
return
;#IfWinExist


; handle attached PUM events and actions 
PUM_out( msg, obj ) {

	; run item normally
	if (msg == "onrun")
	{
		rPath := obj.path
		
		; try a normal run/launch
		Run, %rPath%,,UseErrorLevel
		
		; if it fails, assume a shortcut and try again
		if (ErrorLevel) {
			try {
				FileGetShortcut,%rPath%,outTarget,outWrkDir,outArgs
				Run, "%outTarget%" %outArgs%, %outWrkDir%, UseErrorLevel
				
				; Try again if it failed, possibly ProgramFiles x86 vs x64: https://github.com/joedf/stahky/issues/2
				if (ErrorLevel)
				{
					EnvGet, pf64, ProgramW6432
					_outTarget64 := StrReplace(outTarget, A_ProgramFiles, pf64, , 1)
					Run, "%_outTarget64%" %outArgs%, %outWrkDir%
				}
			}
			catch ; run failed, alert user
			{
				MsgBox, 48,, Error: Could not launch the following (please verify it exists):`n%outTarget%
			}
		}
	}
	
	; On MButton, open the folder if we have a stahky
	if (msg == "onmbutton") {
		
		; open the stahky's folder
		if (_p:=isStahkyFile(obj.path)) {
			if FileExist(_p)
				Run % _p
		}
		else ; open the current menu's or submenu's parent folder
		{
			SplitPath, % obj.path,,_p
			Run, % _p
		}
	}
	
	; On RButton, open the about/firsttime use dialog
	if (msg == "onrbutton") {
		FirstRun_Trigger()
	}
}
