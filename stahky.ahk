; stahky
; by joedf - 2020.07.10
;
; inspried from Stacky (by Pawel Turlejski)
; https://github.com/pawelt/stacky
; https://web.archive.org/web/20130927190146/http://justafewlines.com/2013/04/stacky/

#NoTrayIcon
#SingleInstance, Force
#NoEnv

#Include lib\utils.ahk

; uses PUM by Deo
#Include lib\PUM_API.ahk
#Include lib\PUM.ahk

APPNAME := "stahky"
STAHKY_EXT := APPNAME . ".lnk"
STAHKY_MAGIC_NUM := "5t4ky_1s_c0oL"
StahkyConfigFile := A_ScriptDir "\" APPNAME ".ini"

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
IniRead, offsetX, %StahkyConfigFile%,%APPNAME%,offsetX,0
IniRead, offsetY, %StahkyConfigFile%,%APPNAME%,offsetY,0
IniRead, icoSize, %StahkyConfigFile%,%APPNAME%,iconSize,24
IniRead, useDPIScaleRatio, %StahkyConfigFile%,%APPNAME%,useDPIScaleRatio,1
IniRead, menuTextMargin, %StahkyConfigFile%,%APPNAME%,menuTextMargin,85
IniRead, menuMarginX, %StahkyConfigFile%,%APPNAME%,menuMarginX,4
IniRead, menuMarginY, %StahkyConfigFile%,%APPNAME%,menuMarginY,4
IniRead, bgColor, %StahkyConfigFile%,%APPNAME%,menuBGColor, % TaskbarColor ;0x101010
IniRead, sbgColor, %StahkyConfigFile%,%APPNAME%,menuSelectedBGColor, % TaskbarSColor ;0x272727
IniRead, stextColor, %StahkyConfigFile%,%APPNAME%,menuSelectedTextColor,0xFFFFFF
IniRead, textColor, %StahkyConfigFile%,%APPNAME%,menuTextColor,0xFFFFFF
updateConfigFile(StahkyConfigFile)

DPIScaleRatio := 1
if (useDPIScaleRatio) {
	DPIScaleRatio := (A_ScreenDPI / 96)
	icoSize *= DPIScaleRatio
	menuTextMargin *= DPIScaleRatio
	menuMarginX *= DPIScaleRatio
	menuMarginY *= DPIScaleRatio
}

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

MakeStahkyMenu(menu, searchPath)

SysGet m, MonitorWorkArea, 1
mpy := mBottom
menuWidth := menuTextMargin + icoSize + (2.5*menuMarginX)
mpx := mx - ( menuWidth//DPIScaleRatio )
item := menu.Show( mpx+offsetX, mpy+offsetY )

pm.Destroy()
ExitApp


PUM_out( msg, obj ) {

	if (msg == "onrun")
	{
		Run % obj.path
	}
}