; stahky
; by joedf - 2020.07.10
;
; inspried from Stacky (by Pawel Turlejski)
; https://github.com/pawelt/stacky
; https://web.archive.org/web/20130927190146/http://justafewlines.com/2013/04/stacky/

#NoTrayIcon
#SingleInstance, Force
#NoEnv
; uses PUM by Deo
#Include lib\PUM_API.ahk
#Include lib\PUM.ahk

APPNAME := "stahky"
STAHKY_EXT := APPNAME . ".lnk"
STAHKY_MAGIC_NUM := "5t4ky_1s_c0oL"

CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
MouseGetPos, mx, my

; auto-create *lnk pinnable shortcut file, when folder dragged-on-top of this app
if (A_ScriptDir == A_WorkingDir)
{
	FileGetAttrib,A_args1_fattr, % A_Args[1]
	if InStr(A_args1_fattr,"D") {
		makeStahkyFile(A_Args[1])
	}
}

PixelGetColor, TaskbarColor, 0, % A_ScreenHeight - 1
TaskbarSColor := lightenColor(TaskbarColor)

searchPath := (FileExist(A_Args[1]) ? A_Args[1] : A_WorkingDir) . "\*"
offsetX := 0
offsetY := 0
DPIScaleRatio := (A_ScreenDPI / 96)
icoSize := 24 * DPIScaleRatio
menuTextMargin := 85 * DPIScaleRatio
menuMarginX := 4 * DPIScaleRatio
menuMarginY := 4 * DPIScaleRatio
bgColor := TaskbarColor ;0x101010
sbgColor := TaskbarSColor ;0x272727
stextColor := 0xFFFFFF
textColor := 0xFFFFFF

; parameters of the PUM object, the manager of the menus
pumParams := {"SelMethod" : "fill"        ;item selection method, may be frame,fill
	,"selTColor"   : stextColor ;selection text color
	,"selBGColor"  : sbgColor   ;selection background color, -1 means invert current color
	,"oninit"      : "PUM_out"  ;function which will be called when any menu going to be opened
	,"onuninit"    : "PUM_out"  ;function which will be called when any menu going to be closing
	,"onselect"    : "PUM_out"  ;function which will be called when any item selected with mouse (hovered)
	,"onrbutton"   : "PUM_out"  ;function which will be called when any item right clicked
	,"onmbutton"   : "PUM_out"  ;function which will be called when any item clicked with middle mouse button
	,"onrun"       : "PUM_out"  ;function which will be called when any item clicked with left mouse button
	,"onshow"      : "PUM_out"  ;function which will be called before any menu shown using Show method
	,"onclose"     : "Pum_out"  ;function called just before quitting from Show method
	,mnemonicCMD : "select"}

;PUM_Menu parameters
menuParams1 := {"bgcolor" : bgColor    ;background color of the menu
            , "iconssize" : icoSize      ;size of icons in the menu
            , "tcolor"    : textColor    ;text color of the menu items
			, "textMargin" : menuTextMargin
			,"xmargin"   : menuMarginX
			,"ymargin"   : menuMarginY }

;create an instance of PUM object, it is best to have only one of such in the program
pm := new PUM( pumParams )

;creating popup menu, represented by PUM_Menu object with given parameters
menu := pm.CreateMenu( menuParams1 )

MenuItems := []
Loop, %searchPath%, 1
{
    fPath := A_LoopFileFullPath
	fExt := A_LoopFileExt
	SplitPath,fPath,,,,fNameNoExt
	
	; support filenames like .gitignore, LICENSE
	if (!fNameNoExt)
		fNameNoExt := "." . fExt
	
	OutIconChoice := ""
	if fExt in exe,dll
		OutIconChoice := fPath  . ":0"

	; support windows shortcut/link files *.lnk
	if fExt in lnk
	{
		FileGetShortcut, %fPath%, OutTarget,,,, OutIcon, OutIconNum
		SplitPath,OutTarget,,,OutTargetExt
		if OutTargetExt in exe,dll
			OutIconChoice := OutTarget  . ":0"
		if (OutIcon && OutIconNum)
			OutIconChoice := OutIcon  . ":" . OutIconNum
	}
	; support windows internet shortcut files *.url
	else if fExt in url
	{
		IniRead, OutIcon, %fPath%, InternetShortcut, IconFile
		IniRead, OutIconNum, %fPath%, InternetShortcut, IconIndex, 0
		if FileExist(OutIcon)
			OutIconChoice := OutIcon  . ":" . OutIconNum
	}
	
	; support basic folder
	if (InStr(A_LoopFileAttrib,"D"))
		OutIconChoice := "shell32.dll:4"
	
	; support associated filetypes
	else if (StrLen(OutIconChoice) < 4)
		OutIconChoice := getExtIcon(fExt)


	mItem := { "name": fNameNoExt
		,"path": fPath
		,"icon": OutIconChoice }

	MenuItems.push( mItem )
	menu.add( mItem )
}

SysGet m, MonitorWorkArea, 1
mpy := mBottom
menuWidth := menuTextMargin + icoSize + (2.5*menuMarginX)
mpx := mx - ( menuWidth//DPIScaleRatio )
item := menu.Show( mpx+offsetX, mpy+offsetY )

pm.Destroy()
ExitApp


makeStahkyFile(iPath) {
	global STAHKY_EXT
	global STAHKY_MAGIC_NUM

	Target := A_ScriptFullPath
	SplitPath,iPath,outFileName
	LinkFile := outFileName . "." . STAHKY_EXT
	FileCreateShortcut, %Target%, %LinkFile%, %iPath%, "%iPath%", ;Description, IconFile, ShortcutKey, IconNumber, RunState
	;FileAppend,`n`n[stahky]`nstahky_magic_number=%STAHKY_MAGIC_NUM%
	IniWrite,%STAHKY_MAGIC_NUM%,%LinkFile%,stahky,stahky_magic_number
	MsgBox, 64, New Stahky created, Pinnable shortcut created: %LinkFile%
}

isStahkyFile(fPath) {
	global STAHKY_MAGIC_NUM

	SplitPath,%fPath%,,,_ext
	if _ext in lnk
	{
		IniRead,_t,%fPath%,stahky,stahky_magic_number,0
		if (_t == STAHKY_MAGIC_NUM) {
			;MsgBox, 48, , STAHKY-LICIOUS!
			return true
		}
	}
	return false
}

lightenColor(cHex, L:=2.64) {
	R := L * (cHex>>16 & 0xFF)
	G := L * (cHex>>8 & 0xFF)
	B := L * (cHex & 0xFF)
	return R<<16 | G<<8 | B<<0
}

getExtIcon(Ext) { ; modified from AHK_User - https://www.autohotkey.com/boards/viewtopic.php?p=297834#p297834
	I1 := I2:= ""
	RegRead, from, HKEY_CLASSES_ROOT, .%Ext%
	RegRead, DefaultIcon, HKEY_CLASSES_ROOT, %from%\DefaultIcon
	StringReplace, DefaultIcon, DefaultIcon, `",,all
	StringReplace, DefaultIcon, DefaultIcon, `%SystemRoot`%, %A_WinDir%,all
	StringReplace, DefaultIcon, DefaultIcon, `%ProgramFiles`%, %A_ProgramFiles%,all
	StringReplace, DefaultIcon, DefaultIcon, `%windir`%, %A_WinDir%,all
	StringSplit, I, DefaultIcon, `,
	DefaultIcon := I1 ":" RegExReplace(I2, "[^\d]+")

	if (StrLen(DefaultIcon) < 4) {
		; default file icon, if all else fails
		DefaultIcon := "shell32.dll:0"
		
		;windows default to the OpenCommand if available
		RegRead, OpenCommand, HKEY_CLASSES_ROOT, %from%\shell\open\command
		if (OpenCommand) {
			OpenCommand := StrSplit(OpenCommand,"""","""`t`n`r")[2]
			DefaultIcon := OpenCommand . ":0"
		}
	}

	return DefaultIcon
}

PUM_out( msg, obj ) {

	if (msg == "onrun")
	{
		Run % obj.path
	}
}