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

CoordMode, Pixel, Screen
PixelGetColor, TaskbarColor, 0, % A_ScreenHeight - 1
TaskbarSColor := lightenColor(TaskbarColor)

searchPath := A_ScriptDir . "\menu1\*"
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


Loop, %searchPath%, 1
{
    fPath := A_LoopFileFullPath
	SplitPath,fPath,,,,fNameNoExt
	
	OutTarget := fPath
	OutIconChoice := fPath  . ":0"

	if (A_LoopFileExt == "lnk") {
		FileGetShortcut, %fPath%, OutTarget,,,, OutIcon, OutIconNum
		OutIconChoice := OutTarget  . ":0"
		if (OutIcon && OutIconNum)
			OutIconChoice := OutIcon  . ":" . OutIconNum
	}
	
	if (InStr(A_LoopFileAttrib,"D"))
		OutIconChoice := "shell32.dll:4"
	
	mItem := { "name": fNameNoExt
		,"path": OutTarget
		,"icon": OutIconChoice }

	menu.add( mItem )
}


MouseGetPos, mx, my
SysGet m, MonitorWorkArea, 1
mpy := mBottom
menuWidth := menuTextMargin + icoSize + (2.5*menuMarginX)
mpx := mx - ( menuWidth//DPIScaleRatio )
item := menu.Show( mpx+offsetX, mpy+offsetY )

pm.Destroy()
ExitApp

lightenColor(cHex, L:=2.64) {
	R := L * (cHex>>16 & 0xFF)
	G := L * (cHex>>8 & 0xFF)
	B := L * (cHex & 0xFF)
	return R<<16 | G<<8 | B<<0
}

PUM_out( msg, obj ) {
	if (msg == "onrun")
		Run % obj.path
}