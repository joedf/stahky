; stahky
; by joedf - 2020.07.10
;
; inspried from Stacky (by Pawel Turlejski)
; https://github.com/pawelt/stacky
; https://web.archive.org/web/20130927190146/http://justafewlines.com/2013/04/stacky/


#NoEnv
; uses PUM by Deo
#Include lib\PUM_API.ahk
#Include lib\PUM.ahk

DPIScaleRatio := (A_ScreenDPI / 96)
icoSize := 24 * DPIScaleRatio
menuTextMargin := 85 * DPIScaleRatio
menuMarginX := 4 * DPIScaleRatio
menuMarginY := 4 * DPIScaleRatio

; parameters of the PUM object, the manager of the menus
pumParams := {"SelMethod" : "fill"        ;item selection method, may be frame,fill
	;,"selTColor"   : -1        ;selection text color
	,"selBGColor"  : 0x272727       ;selection background color, -1 means invert current color
	,"oninit"      : "PUM_out"  ;function which will be called when any menu going to be opened
	,"onuninit"    : "PUM_out"  ;function which will be called when any menu going to be closing
	,"onselect"    : "PUM_out"  ;function which will be called when any item selected with mouse (hovered)
	,"onrbutton"   : "PUM_out"  ;function which will be called when any item right clicked
	,"onmbutton"   : "PUM_out"  ;function which will be called when any item clicked with middle mouse button
	,"onrun"       : "PUM_out"  ;function which will be called when any item clicked with left mouse button
	,"onshow"      : "PUM_out"      ;function which will be called before any menu shown using Show method
	,"onclose"     : "Pum_out"     ;function called just before quitting from Show method
	,mnemonicCMD : "select"}
                
;PUM_Menu parameters
menuParams1 := {"bgcolor" : 0x101010    ;background color of the menu
            , "iconssize" : icoSize     ;size of icons in the menu
            , "tcolor"    : 0xFFFFFF    ;text color of the menu items
			, "textMargin" : menuTextMargin
			,"xmargin"   : menuMarginX
			,"ymargin"   : menuMarginY }

;create an instance of PUM object, it is best to have only one of such in the program
pm := new PUM( pumParams )

;creating popup menu, represented by PUM_Menu object with given parameters
menu := pm.CreateMenu( menuParams1 )



menu_1 := []
Loop, %A_ScriptDir%\menu1\*, 1
    menu_1.push(A_LoopFileFullPath)

lastMenuItem:=0

for k, LinkFile in menu_1
{
	SplitPath,LinkFile,,,OutExtension,fNameNoExt
	
	if (OutExtension == "lnk")
		FileGetShortcut, %LinkFile%, OutTarget, OutDir, OutArgs, OutDescription, OutIcon, OutIconNum, OutRunState
	else
		OutTarget := LinkFile
	
	lastMenuItem := menu.add( { "name" : fNameNoExt, "icon" : OutTarget . ":0"  } )
}


MouseGetPos, mx, my
SysGet m, MonitorWorkArea, 1
mpy := mBottom
menuWidth := menuTextMargin + icoSize + (2.5*menuMarginX)
mpx := mx - ( menuWidth//DPIScaleRatio )
item := menu.Show( mpx, mpy )


ExitApp
return


PUM_out( msg, obj )
{
 /*
  if ( msg = "onselect" )
  {
    rect := obj.GetRECT()
    CoordMode, ToolTip, Screen
    tooltip,% "Selected: " obj.name,% rect.right,% rect.top
  }
  if ( msg ~= "oninit|onuninit|onshow|onclose" )
    tooltip % "menu " msg ": " obj.handle
  if ( msg = "onrbutton" )
    tooltip % "Right clicked: " obj.name
  if ( msg = "onmbutton" )
    tooltip % "Middle clicked: " obj.name
  if ( msg = "onrun" )
    tooltip % "Item runned: " obj.name
*/
}