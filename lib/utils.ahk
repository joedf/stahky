
MakeStahkyMenu( pMenu, searchPath )
{
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
				OutIconChoice := OutIcon  . ":" . (OutIconNum-1)
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

		pMenu.add( mItem )
	}
	
	return pMenu
}

makeStahkyFile(iPath) {
	global APPNAME
	global STAHKY_EXT
	global STAHKY_MAGIC_NUM

	Target := A_ScriptFullPath
	SplitPath,iPath,outFileName
	LinkFile := outFileName . "." . STAHKY_EXT
	FileCreateShortcut, %Target%, %LinkFile%, %iPath%, "%iPath%", ;Description, IconFile, ShortcutKey, IconNumber, RunState
	;FileAppend,`n`n[stahky]`nstahky_magic_number=%STAHKY_MAGIC_NUM%
	IniWrite,%STAHKY_MAGIC_NUM%,%LinkFile%,%APPNAME%,stahky_magic_number
	MsgBox, 64, New Stahky created, Pinnable shortcut created: %LinkFile%
}

isStahkyFile(fPath) {
	global APPNAME
	global STAHKY_MAGIC_NUM

	SplitPath,%fPath%,,,_ext
	if _ext in lnk
	{
		IniRead,_t,%fPath%,%APPNAME%,stahky_magic_number,0
		if (_t == STAHKY_MAGIC_NUM) {
			;MsgBox, 48, , STAHKY-LICIOUS!
			return true
		}
	}
	return false
}

updateConfigFile(SCFile) {
	global
	IniWrite, % offsetX, %SCFile%,%APPNAME%,offsetX
	IniWrite, % offsetY, %SCFile%,%APPNAME%,offsetY
	IniWrite, % icoSize, %SCFile%,%APPNAME%,iconSize
	IniWrite, % useDPIScaleRatio, %SCFile%,%APPNAME%,useDPIScaleRatio
	IniWrite, % menuTextMargin, %SCFile%,%APPNAME%,menuTextMargin
	IniWrite, % menuMarginX, %SCFile%,%APPNAME%,menuMarginX
	IniWrite, % menuMarginY, %SCFile%,%APPNAME%,menuMarginY
	IniWrite, % bgColor, %SCFile%,%APPNAME%,menuBGColor
	IniWrite, % sbgColor, %SCFile%,%APPNAME%,menuSelectedBGColor
	IniWrite, % stextColor, %SCFile%,%APPNAME%,menuSelectedTextColor
	IniWrite, % textColor, %SCFile%,%APPNAME%,menuTextColor
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