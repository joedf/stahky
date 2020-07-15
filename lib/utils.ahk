
MakeStahkyMenu( pMenu, searchPath, iPUM, pMenuParams, recursion_CurrentDepth := 0 )
{
	global APP_NAME
	global STAHKY_MAX_DEPTH
	
	Loop, %searchPath%, 1
	{
		if A_LoopFileAttrib contains H ; Skip any file that is H (Hidden)
			continue  ; Skip this file and move on to the next one.
		
		fPath := A_LoopFileFullPath
		fExt := A_LoopFileExt
		SplitPath,fPath,,,,fNameNoExt
		
		; support filenames like .gitignore, LICENSE
		if (!fNameNoExt)
			fNameNoExt := "." . fExt
		
		; automagically get a nice icon accordingly, if possible
		OutIconChoice := getItemIcon(fPath)

		; setup the menu item's metadata
		mItem := { "name": fNameNoExt
			,"path": fPath
			,"icon": OutIconChoice }
		
		; handle any submenus
		if fExt in lnk
		{
			; display stachkys as submenus
			if (OutTarget := isStahkyFile(fPath)) {
				
				; couldnt get from the stachky file config, so assume the target folder using the lnk's args
				if !FileExist(OutTarget) {
					FileGetShortcut,%fPath%,,,OutArgs
					OutTarget := Trim(OutArgs,""""`t)
				}
				
				; create and attach the stahky submenu, with a cap on recursion depth
				if (recursion_CurrentDepth < STAHKY_MAX_DEPTH)
				{
					; recurse into sub-stachky-liciousnous
					%A_ThisFunc%( mItem["submenu"] := iPUM.CreateMenu( pMenuParams )
						,OutTarget . "\*"
						,iPUM
						,pMenuParams
						,recursion_CurrentDepth+1  )
				} else {
					maxStahkyWarningMenu := (mItem["submenu"] := iPUM.CreateMenu( pMenuParams ))
					maxStahkyWarningMenu.Add({ "name": "Overwhelmingly Stahky-licious! (Max = " . STAHKY_MAX_DEPTH . ")"
						,"disabled": true
						,"icon": A_ScriptFullPath })
				}
			}
		}
		else if (InStr(A_LoopFileAttrib,"D")) ; display on-shortcut folders as submenus
		{
			; recurse into folders
			%A_ThisFunc%( mItem["submenu"] := iPUM.CreateMenu( pMenuParams )
						,fPath . "\*"
						,iPUM
						,pMenuParams
						,recursion_CurrentDepth )
		}
		
		; push the menu item to the parent menu
		pMenu.add( mItem )
	}
	
	return pMenu
}

makeStahkyFile(iPath) {
	global APP_NAME
	global STAHKY_EXT
	
	; assume we have a folder and get it's name
	SplitPath,iPath,outFolderName
	; create the shortcut in the same folder as Stahky itself
	LinkFile := A_ScriptDir . "\" . outFolderName . "." . STAHKY_EXT
	FileCreateShortcut, %A_ScriptFullPath%, %LinkFile%, %iPath%, /stahky "%iPath%", ;Description, IconFile, ShortcutKey, IconNumber, RunState
	MsgBox, 64, New Stahky created, A pinnable shortcut was created here: `n%LinkFile%
}

isStahkyFile(fPath) {
	global APP_NAME
	global G_STAHKY_ARG

	SplitPath,fPath,,,_ext
	if _ext in lnk
	{
		FileGetShortcut,%fPath%,,,outArgs
		_a := StrSplit(outArgs,A_Space)
		if (_a[1] == G_STAHKY_ARG) {
			;MsgBox, 48, , STAHKY-LICIOUS!
			_ap := Trim(SubStr(outArgs,Strlen(G_STAHKY_ARG)+1)," """)
			if FileExist(_ap)
				return _ap
			return true
		}
	}
	return false
}

loadSettings(SCFile) {
	global
	IniRead, offsetX, %SCFile%,%APP_NAME%,offsetX,0
	IniRead, offsetY, %SCFile%,%APP_NAME%,offsetY,0
	IniRead, icoSize, %SCFile%,%APP_NAME%,iconSize,24
	IniRead, STAHKY_MAX_DEPTH, %SCFile%,%APP_NAME%,STAHKY_MAX_DEPTH,5
	IniRead, useDPIScaleRatio, %SCFile%,%APP_NAME%,useDPIScaleRatio,1
	IniRead, menuTextMargin, %SCFile%,%APP_NAME%,menuTextMargin,85
	IniRead, menuMarginX, %SCFile%,%APP_NAME%,menuMarginX,4
	IniRead, menuMarginY, %SCFile%,%APP_NAME%,menuMarginY,4
	IniRead, bgColor, %SCFile%,%APP_NAME%,menuBGColor, % TaskbarColor ;0x101010
	IniRead, sbgColor, %SCFile%,%APP_NAME%,menuSelectedBGColor, % TaskbarSColor ;0x272727
	IniRead, stextColor, %SCFile%,%APP_NAME%,menuSelectedTextColor,0xFFFFFF
	IniRead, textColor, %SCFile%,%APP_NAME%,menuTextColor,0xFFFFFF
}

saveSettings(SCFile) {
	global
	IniWrite, % offsetX, %SCFile%,%APP_NAME%,offsetX
	IniWrite, % offsetY, %SCFile%,%APP_NAME%,offsetY
	IniWrite, % icoSize, %SCFile%,%APP_NAME%,iconSize
	IniWrite, % STAHKY_MAX_DEPTH, %SCFile%,%APP_NAME%,STAHKY_MAX_DEPTH
	IniWrite, % useDPIScaleRatio, %SCFile%,%APP_NAME%,useDPIScaleRatio
	IniWrite, % menuTextMargin, %SCFile%,%APP_NAME%,menuTextMargin
	IniWrite, % menuMarginX, %SCFile%,%APP_NAME%,menuMarginX
	IniWrite, % menuMarginY, %SCFile%,%APP_NAME%,menuMarginY
	IniWrite, % bgColor, %SCFile%,%APP_NAME%,menuBGColor
	IniWrite, % sbgColor, %SCFile%,%APP_NAME%,menuSelectedBGColor
	IniWrite, % stextColor, %SCFile%,%APP_NAME%,menuSelectedTextColor
	IniWrite, % textColor, %SCFile%,%APP_NAME%,menuTextColor
}

lightenColor(cHex, L:=2.64) {
	R := L * (cHex>>16 & 0xFF)
	G := L * (cHex>>8 & 0xFF)
	B := L * (cHex & 0xFF)
	return Format("0x{:X}", (R<<16 | G<<8 | B<<0) )
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
	Gui, Add, Link, R2, Special thanks to <a href="https://autohotkey.com/board/topic/73599-ahk-l-pum-owner-drawn-object-based-popup-menu">Deo for PUM.ahk</a>
	Gui, Add, Text, , First time use?
	Gui, Add, Link, , <a href="https://github.com/joedf/stahky">https://github.com/joedf/stahky</a>
	Gui, AboutDialog:Margin, , 10
	Gui, Show, , About %APP_NAME%
	return
	
	AboutDialogGuiEscape:
	AboutDialogGuiClose:
	ExitApp
}
