
MakeStahkyMenu( pMenu, searchPath, iPUM, pMenuParams, recursion_CurrentDepth := 0 )
{
	global APP_NAME
	global STAHKY_MAX_DEPTH
	global STAHKY_START_TIME
	global STAHKY_MAX_RUN_TIME

	global ShowOpenCurrentFolder
	global SortFoldersFirst

	if (ShowOpenCurrentFolder)
	{
		; If we have a folder and the show current folder option is enabled,
		; Show an "open: ..." folder option first. For more info see:
		; https://github.com/joedf/stahky/issues/20
		if (SubStr(searchPath, 1-2) == "\*")
		{
			currentDirItem := { "name": "Open this folder..."
				,"path": SubStr(searchPath, 1, 0-2)
				,"icon": "shell32.dll:4" }
			pMenu.Add(currentDirItem)
			pMenu.Add() ; add separator
		}
	}

	if (SortFoldersFirst)
	{
		; do folders first
		Loop, %searchPath%, 2
		{
			MakeStahkyMenu_subroutine( pMenu, A_LoopFileFullPath, iPUM, pMenuParams, recursion_CurrentDepth )
		}

		; do files second
		Loop, %searchPath%, 0
		{
			MakeStahkyMenu_subroutine( pMenu, A_LoopFileFullPath, iPUM, pMenuParams, recursion_CurrentDepth )
		}
	}
	else
	{
		; do normal order, alphabetically/natural order
		Loop, %searchPath%, 1
		{
			MakeStahkyMenu_subroutine( pMenu, A_LoopFileFullPath, iPUM, pMenuParams, recursion_CurrentDepth )
		}
	}

	return pMenu
}

MakeStahkyMenu_subroutine( pMenu, fPath, iPUM, pMenuParams, recursion_CurrentDepth := 0 )
{
	global APP_NAME
	global STAHKY_MAX_DEPTH
	global STAHKY_START_TIME
	global STAHKY_MAX_RUN_TIME

	; assume we get the full path in fPath

	; check if the menu creation is taking too long, avoid very large folders!
	runtime:=(A_TickCount - STAHKY_START_TIME)
	if (runtime > 2000) ; bug? doesn't work unless we have tooltip?
		ToolTip %APP_NAME% is loading... %runtime%
	if (runtime > STAHKY_MAX_RUN_TIME) {
		ToolTip

		MsgBox, 4112, ,
		(Ltrim Join`s
		Stahky has been running for too long! Please ensure to not include any folders that are too large.
		Consider including a shortcut to large folders in your stahky folder instead.
		`n`nLatest file:`n%fPath%`n`nExecution time: %runtime% ms`nThe program will now terminate.
		)
		ExitApp
	}

	FileGetAttrib, fileAttrib, % fPath
	if InStr(fileAttrib, "H") ; Skip any file that is H (Hidden)
		return pMenu ; Skip this file and move on to the next one.

	SplitPath,fPath,,,fExt,fNameNoExt

	; support filenames like .gitignore, LICENSE
	if (!fNameNoExt)
		fNameNoExt := "." . fExt

	; support filenames with `&`, so they don't become ALT+letter shortcut and hide the `&` character
	fNameNoExt := StrReplace(fNameNoExt,"&","&&")

	; automagically get a nice icon accordingly, if possible
	OutIconChoice := getItemIcon(fPath)

	; setup the menu item's metadata
	mItem := { "name": fNameNoExt
		,"path": fPath
		,"icon": OutIconChoice }

	; handle any submenus
	if fExt in lnk
	{
		; display stahkys as submenus
		if (OutTarget := isStahkyFile(fPath)) {

			; couldnt get from the stahky file config, so assume the target folder using the lnk's args
			if !FileExist(OutTarget) {
				FileGetShortcut,%fPath%,,,OutArgs
				OutTarget := Trim(OutArgs,""""`t)
			}

			; create and attach the stahky submenu, with a cap on recursion depth
			if (recursion_CurrentDepth < STAHKY_MAX_DEPTH)
			{
				; recurse into sub-stahky-liciousnous
				; Not using "%A_ThisFunc%", to support optional sorting from "MakeStahkyMenu" instead of "MakeStahkyMenu_subroutine"
				MakeStahkyMenu( mItem["submenu"] := iPUM.CreateMenu( pMenuParams )
					,OutTarget . "\*"
					,iPUM
					,pMenuParams
					,recursion_CurrentDepth+1  )
			} else {
				maxStahkyWarningMenu := (mItem["submenu"] := iPUM.CreateMenu( pMenuParams ))
				maxStahkyWarningMenu.Add({ "name": "Overwhelmingly Stahky-licious! (Max = " . STAHKY_MAX_DEPTH . ")"
					,"disabled": true
					,"icon": "shell32.dll:77" })
			}
		}
	}
	else if (InStr(fileAttrib,"D")) ; display on-shortcut folders as submenus
	{
		; recurse into folders
		; Not using "%A_ThisFunc%", to support optional sorting from "MakeStahkyMenu" instead of "MakeStahkyMenu_subroutine"
		MakeStahkyMenu( mItem["submenu"] := iPUM.CreateMenu( pMenuParams )
					,fPath . "\*"
					,iPUM
					,pMenuParams
					,recursion_CurrentDepth )
	}

	; push the menu item to the parent menu
	pMenu.add( mItem )

	return pMenu
}

makeStahkyFile(iPath, configFile:="") {
	global APP_NAME
	global STAHKY_EXT
	global G_STAHKY_ARG
	global G_STAHKY_ARG_CFG

	; assume we have a folder and get it's name
	SplitPath,iPath,outFolderName
	; create the shortcut in the same folder as Stahky itself
	LinkFile := A_ScriptDir . "\" . outFolderName . "." . STAHKY_EXT

	; check for optional config file param
	cfgParam := ""
	if (StrLen(configFile) > 0 and isSettingsFile(configFile)) {
		cfgFullPath := NormalizePath(configFile)
		; basically: /config "my/config/file/path/here.ini"
		cfgParam := G_STAHKY_ARG_CFG . " " . """" . cfgFullPath . """"
	}

	; Compiled vs script (using installed AHK) version shortcuts are different
	if (A_IsCompiled) {
		FileCreateShortcut, %A_ScriptFullPath%, %LinkFile%, %A_ScriptDir%, %G_STAHKY_ARG% "%iPath%" %cfgParam%
	} else {
		FileCreateShortcut, %A_AhkPath%, %LinkFile%, %A_ScriptDir%,"%A_ScriptFullPath%" %G_STAHKY_ARG% "%iPath%" %cfgParam%
	}

	MsgBox, 64, New Stahky created, A pinnable shortcut was created here: `n%LinkFile%
}

isStahkyFile(fPath) {
	global APP_NAME
	global G_STAHKY_ARG

	SplitPath,fPath,,,_ext
	if _ext in lnk
	{
		FileGetShortcut,%fPath%,,,outArgs
		args := StrSplit(outArgs,A_Space)
		for n, arg in args
		{
			if (arg == G_STAHKY_ARG) {
				;MsgBox, 48, , STAHKY-LICIOUS!
				/*
				Running as script example:
					"C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe" 
					"C:\Users\joedf\code\stahky\stahky.ahk"
					/stahky "C:\Users\joedf\code\stahky\~MY-LI~1"
					/config "C:\Users\joedf\code\stahky\~stahky3.ini"
				
				Running as compiled example:
					C:\Users\joedf\code\stahky\stahky.exe
					/stahky "C:\Users\joedf\code\stahky\~my-links"
					/config "C:\Users\joedf\code\stahky\stahky.ini"
				*/
				; okay to assume the path following the argument is wrapped in quotes
				; since we wrap all argument paths in quotes now...
				s1 := InStr(outArgs, " " . G_STAHKY_ARG . " """) + StrLen(G_STAHKY_ARG) + 3
				s2 := InStr(outArgs, """", false, s1)
				path := Trim(SubStr(outArgs,s1, s2-s1),"""")
				if FileExist(path)
					return path
				return true
			}
		}
	}
	return false
}

isSettingsFile(fPath) {
	global APP_NAME
	if FileExist(fPath)
	{
		SplitPath, fPath , , , fileExtension
		; check if we got an existing INI file
		if InStr(fileExtension, "ini")
		{
			IniRead, outSection, %fPath%, %APP_NAME%
			if StrLen(outSection) > 2
				return True
		}
	}
	return False
}

loadSettings(SCFile) {
	global
	; get taskbar colors
	TaskbarColor := getTaskbarColor()

	; calc default colors
	TaskbarSColor := lightenColor(TaskbarColor)
	TaskbarTColor := contrastBW(TaskbarSColor)

	; load vals
	IniRead, offsetX, %SCFile%,%APP_NAME%,offsetX,0
	IniRead, offsetY, %SCFile%,%APP_NAME%,offsetY,0
	IniRead, icoSize, %SCFile%,%APP_NAME%,iconSize,24
	IniRead, STAHKY_MAX_RUN_TIME, %SCFile%,%APP_NAME%,STAHKY_MAX_RUN_TIME,3500
	STAHKY_MAX_RUN_TIME := Max(1000,Min(STAHKY_MAX_RUN_TIME,10000)) ; minimum of 1s, maximum of 10s wait/run time
	IniRead, STAHKY_MAX_DEPTH, %SCFile%,%APP_NAME%,STAHKY_MAX_DEPTH,5
	IniRead, SortFoldersFirst, %SCFile%,%APP_NAME%,SortFoldersFirst,0
	IniRead, useDPIScaleRatio, %SCFile%,%APP_NAME%,useDPIScaleRatio,1
	IniRead, exitAfterFolderOpen, %SCFile%,%APP_NAME%,exitAfterFolderOpen,1
	IniRead, ShowOpenCurrentFolder, %SCFile%,%APP_NAME%,ShowOpenCurrentFolder,0
	IniRead, ShowAtMousePosition, %SCFile%,%APP_NAME%,ShowAtMousePosition,0
	IniRead, menuTextMargin, %SCFile%,%APP_NAME%,menuTextMargin,85
	IniRead, menuMarginX, %SCFile%,%APP_NAME%,menuMarginX,4
	IniRead, menuMarginY, %SCFile%,%APP_NAME%,menuMarginY,4
	IniRead, bgColor, %SCFile%,%APP_NAME%,menuBGColor, % TaskbarColor ;0x101010
	IniRead, sbgColor, %SCFile%,%APP_NAME%,menuSelectedBGColor, % TaskbarSColor ;0x272727
	IniRead, stextColor, %SCFile%,%APP_NAME%,menuSelectedTextColor, % TaskbarTColor ; B/W based on a luma/contrast formula
	IniRead, textColor, %SCFile%,%APP_NAME%,menuTextColor, % TaskbarTColor
	IniRead, PUM_flags, %SCFile%,%APP_NAME%,PUM_flags,hleft
	; font options
	IniRead, fontName, %SCFile%,%APP_NAME%,fontName,Segoe UI
	IniRead, fontSize, %SCFile%,%APP_NAME%,fontSize,9
	IniRead, fontWeight, %SCFile%,%APP_NAME%,fontWeight,400
	IniRead, fontItalic, %SCFile%,%APP_NAME%,fontItalic,0
	IniRead, fontStrike, %SCFile%,%APP_NAME%,fontStrike,0
	IniRead, fontUnderline, %SCFile%,%APP_NAME%,fontUnderline,0
}

saveSettings(SCFile) {
	global
	; save vals
	IniWrite, % offsetX, %SCFile%,%APP_NAME%,offsetX
	IniWrite, % offsetY, %SCFile%,%APP_NAME%,offsetY
	IniWrite, % icoSize, %SCFile%,%APP_NAME%,iconSize
	IniWrite, % STAHKY_MAX_RUN_TIME, %SCFile%,%APP_NAME%,STAHKY_MAX_RUN_TIME
	IniWrite, % STAHKY_MAX_DEPTH, %SCFile%,%APP_NAME%,STAHKY_MAX_DEPTH
	IniWrite, % SortFoldersFirst, %SCFile%,%APP_NAME%,SortFoldersFirst
	IniWrite, % useDPIScaleRatio, %SCFile%,%APP_NAME%,useDPIScaleRatio
	IniWrite, % ShowOpenCurrentFolder, %SCFile%,%APP_NAME%,ShowOpenCurrentFolder
	IniWrite, % ShowAtMousePosition, %SCFile%,%APP_NAME%,ShowAtMousePosition
	IniWrite, % exitAfterFolderOpen, %SCFile%,%APP_NAME%,exitAfterFolderOpen
	IniWrite, % menuTextMargin, %SCFile%,%APP_NAME%,menuTextMargin
	IniWrite, % menuMarginX, %SCFile%,%APP_NAME%,menuMarginX
	IniWrite, % menuMarginY, %SCFile%,%APP_NAME%,menuMarginY
	IniWrite, % bgColor, %SCFile%,%APP_NAME%,menuBGColor
	IniWrite, % sbgColor, %SCFile%,%APP_NAME%,menuSelectedBGColor
	IniWrite, % stextColor, %SCFile%,%APP_NAME%,menuSelectedTextColor
	IniWrite, % textColor, %SCFile%,%APP_NAME%,menuTextColor
	IniWrite, % PUM_flags, %SCFile%,%APP_NAME%,PUM_flags
	; font options
	IniWrite, % fontName, %SCFile%,%APP_NAME%,fontName
	IniWrite, % fontSize, %SCFile%,%APP_NAME%,fontSize
	IniWrite, % fontWeight, %SCFile%,%APP_NAME%,fontWeight
	IniWrite, % fontItalic, %SCFile%,%APP_NAME%,fontItalic
	IniWrite, % fontStrike, %SCFile%,%APP_NAME%,fontStrike
	IniWrite, % fontUnderline, %SCFile%,%APP_NAME%,fontUnderline
}

lightenColor(cHex, L:=2.64) {
	R := (L * (10+(cHex>>16 & 0xFF))) & 0xFF
	G := (L * (10+(cHex>>8 & 0xFF))) & 0xFF
	B := (L * (10+(cHex & 0xFF))) & 0xFF
	return Format("0x{:X}", (R<<16 | G<<8 | B<<0) )
}

contrastBW(c) { ; based on https://gamedev.stackexchange.com/a/38561/48591
	R := 0.2126 * (c>>16 & 0xFF) / 0xFF
	G := 0.7152 * (c>>8 & 0xFF) / 0xFF
	B := 0.0722 * (c & 0xFF) / 0xFF
	luma := R+G+B
	return (luma > 0.35) ? 0x000000 : 0xFFFFFF
}

getTaskbarColor() {
	; get task pos/size info
	WinGetPos tx, ty, tw, th, ahk_class Shell_TrayWnd

	; calc pixel position
	tPix_x := tx + tw - 2
	tPix_y := ty + th - 2

	; pick the color and return
	PixelGetColor, TaskbarColor, % tPix_x, % tPix_y, RGB
	return TaskbarColor
}

GetMonitorMouseIsIn() {
	; code from Maestr0
	; https://www.autohotkey.com/boards/viewtopic.php?p=235163#p235163

	; get the mouse coordinates first
	Coordmode, Mouse, Screen	; use Screen, so we can compare the coords with the sysget information`
	MouseGetPos, Mx, My

	SysGet, MonitorCount, 80	; monitorcount, so we know how many monitors there are, and the number of loops we need to do
	Loop, %MonitorCount%
	{
		SysGet, mon%A_Index%, Monitor, %A_Index%	; "Monitor" will get the total desktop space of the monitor, including taskbars

		if ( Mx >= mon%A_Index%left ) && ( Mx < mon%A_Index%right ) && ( My >= mon%A_Index%top ) && ( My < mon%A_Index%bottom )
		{
			ActiveMon := A_Index
			break
		}
	}
	return ActiveMon
}

getOptimalMenuPos(mx, my) {
	; based off of stacky's code, but is multi-monitor aware
	; https://github.com/joedf/stahky/issues/21#issuecomment-2722264863
	hMonitor := GetMonitorMouseIsIn()
	SysGet, rWorkArea, MonitorWorkArea, %hMonitor%

	pos_x := mx, pos_y := my
	if (pos_x < rWorkAreaLeft) {
		pos_x := rWorkAreaLeft - 1
	} else if (pos_x > rWorkAreaRight) {
		pos_x := rWorkAreaRight - 1
	}

	if (pos_y < rWorkAreaTop) {
		pos_y := rWorkAreaTop - 1
	} else if (pos_y > rWorkAreaBottom) {
		pos_y := rWorkAreaBottom - 1
	}
	
	; from testing, these flags don't seem to be needed
	; SysGet, menuDropAlign, % (SM_MENUDROPALIGNMENT := 40)
	; flags := menuDropAlign | (TPM_LEFTBUTTON := 0)
	
	return { x: pos_x, y: pos_y, flags: flags }
}

getItemIcon(fPath) {
	SplitPath,fPath,,,fExt
	FileGetAttrib,fAttr,%fPath%

	OutIconChoice := ""

	; support executable binaries
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
			OutIconChoice := OutIcon  . ":" . (OutIconNum-1)
		else {
			; Support shortcuts to folders with no custom icon set (default)
			FileGetAttrib,_attr,%OutTarget%
			if (InStr(_attr,"D")) {
				; display default icon instead of blank file icon
				OutIconChoice := "imageres.dll:4"
			}
		}
	}
	; support windows internet shortcut files *.url
	else if fExt in url
	{
		IniRead, OutIcon, %fPath%, InternetShortcut, IconFile
		IniRead, OutIconNum, %fPath%, InternetShortcut, IconIndex, 0
		if FileExist(OutIcon)
			OutIconChoice := OutIcon  . ":" . OutIconNum
	}

	; support folder icons
	if (InStr(fAttr,"D"))
	{
		OutIconChoice := "shell32.dll:4"

		; Customized may contain a hidden system file called desktop.ini
		_dini := fPath . "\desktop.ini"
		; https://msdn.microsoft.com/en-us/library/cc144102.aspx

		; case 1
		; [.ShellClassInfo]
		; IconResource=C:\WINDOWS\System32\SHELL32.dll,130
		IniRead,_ico,%_dini%,.ShellClassInfo,IconResource,0
		if (_ico) {
			lastComma := InStr(_ico,",",0,0)
			OutIconChoice := Substr(_ico,1,lastComma-1) . ":" . substr(_ico,lastComma+1)
		} else {
			; case 2
			; [.ShellClassInfo]
			; IconFile=C:\WINDOWS\System32\SHELL32.dll
			; IconIndex=130
			IniRead,_icoFile,%_dini%,.ShellClassInfo,IconFile,0
			IniRead,_icoIdx,%_dini%,.ShellClassInfo,IconIndex,0
			if (_icoFile)
				OutIconChoice := _icoFile . ":" . _icoIdx
		}
	}

	; support associated filetypes
	else if (StrLen(OutIconChoice) < 4)
		OutIconChoice := getExtIcon(fExt)

	return OutIconChoice
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
	DefaultIcon := I1 ":" RegExReplace(I2, "[^\d-]+") ;clean index number, but support negatives

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

NormalizePath(path) { ; from AHK v1.1.37.02 documentation
	cc := DllCall("GetFullPathName", "str", path, "uint", 0, "ptr", 0, "ptr", 0, "uint")
	VarSetCapacity(buf, cc*2)
	DllCall("GetFullPathName", "str", path, "uint", cc, "str", buf, "ptr", 0)
	return buf
}

FirstRun_Trigger() {
	global G_FirstRun_Trigger
	global APP_NAME
	global APP_VERSION
	global APP_REVISION

	; prevent program auto exiting if we are displaying this dialog
	G_FirstRun_Trigger := true

	Gui, AboutDialog:New, +LastFound +AlwaysOnTop +ToolWindow
	Gui, AboutDialog:Margin, 10, -7
	Gui, Color, white
	;@Ahk2Exe-IgnoreBegin
	Gui, Add, Picture, x12 y9 w48 h48, %A_ScriptDir%\res\app.ico
	;@Ahk2Exe-IgnoreEnd
	/*@Ahk2Exe-Keep
	Gui, Add, Picture, x12 y9 w48 h48 Icon1, %A_ScriptFullPath%
	*/
	Gui, Font, s20 bold, Segoe UI
	Gui, Add, Text, x72 y2, %APP_NAME%
	Gui, Font, s9 norm
	Gui, Add, Text, x+4 yp+15, v%APP_VERSION%
	Gui, Add, Text, x72 yp+18 R2, by joedf
	Gui, Add, Text, , Revision date: %APP_REVISION%
	Gui, Add, Text, R2, Released under the MIT License
	Gui, Add, Link, R2, Special thanks to <a href="https://www.autohotkey.com/board/topic/73599-ahk-l-pum-owner-drawn-object-based-popup-menu">Deo for PUM.ahk</a>
	Gui, Add, Text, , First time use?
	Gui, Add, Link, , <a href="https://github.com/joedf/stahky">https://github.com/joedf/stahky</a>
	Gui, AboutDialog:Margin, , 10
	Gui, Show, , About %APP_NAME%
	return

	AboutDialogGuiEscape:
	AboutDialogGuiClose:
	ExitApp
}
