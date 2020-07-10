; stahky
; by joedf - 2020.07.10
;
; inspried from Stacky (by Pawel Turlejski)
; https://github.com/pawelt/stacky
; https://web.archive.org/web/20130927190146/http://justafewlines.com/2013/04/stacky/

menu_1 := []
Loop, %A_ScriptDir%\menu1\*, 1
    menu_1.push(A_LoopFileFullPath)


for k, LinkFile in menu_1
{
	SplitPath,LinkFile,,,,fNameNoExt
	Menu, menu_1, Add, %fNameNoExt%, donothing
	
	FileGetShortcut, %LinkFile%, OutTarget, OutDir, OutArgs, OutDescription, OutIcon, OutIconNum, OutRunState
	Menu, menu_1, Icon, %fNameNoExt%, %OutTarget%,,48
}





; based on https://autohotkey.com/board/topic/74704-change-menu-background-color-with-setmenuinfo/
hMyMenu := GetMenuHandle("menu_1")
/*
struct tagMENUINFO {
  DWORD     cbSize;
  DWORD     fMask;
  DWORD     dwStyle;
  UINT      cyMax;
  HBRUSH    hbrBack;
  DWORD     dwContextHelpID;
  ULONG_PTR dwMenuData;
}
*/

Menu_SetBG(0x5555ff,sMENUINFO)
ret := DllCall("SetMenuInfo", "Ptr", hMyMenu, "Ptr", &sMENUINFO)	

; https://autohotkey.com/board/topic/65469-ahk-l-x64-dllcall-returns-error-invalid-parameter/
Menu_SetBG(pColor,Byref sMENUINFO)
{
	fMask 	:= 0x10 | 0x2 ; MIM_STYLE | MIM_BACKGROUND
	dwStyle := 0x80000000 ; The left blank part gets removed.
	hbrBack := DllCall("CreateSolidBrush", "uint", pColor)
	struct_size := 16+3*A_PtrSize
	VarSetCapacity(sMENUINFO, struct_size, 0)
	NumPut(struct_size, sMENUINFO, 0,"UInt")
	NumPut(fMask, 		sMENUINFO, 4,"UInt")
	NumPut(dwStyle, 		sMENUINFO, 8,"UInt")
	NumPut(hbrBack, 	sMENUINFO,16,"Ptr")
	return
}




;Menu, menu_1, Color, 101010
Menu, menu_1, Show 

ExitApp
return

GetMenuHandle(menu_name)
{
	;borrowed mostly from Menu Icons v2.21 by Lexikos
	;http://www.autohotkey.com/forum/topic21991.html
	
    static h_menuDummy, GMD := "GuiMenuDummy"
	static Ptr := (A_PtrSize = 8) ? "ptr" : "uint"
    If !h_menuDummy
    {
        Menu, menuDummy, Add
        Menu, menuDummy, DeleteAll

        Gui, %GMD%: Menu, menuDummy
        Gui, %GMD%:+LastFound
        h_menuDummy := DllCall("GetMenu", ptr, WinExist(), ptr)
        Gui, %GMD%:Menu
        Gui, %GMD%:Destroy        
        if !h_menuDummy
            return 0
    }

    Menu, menuDummy, Add, :%menu_name%
    h_menu := DllCall( "GetSubMenu", ptr, h_menuDummy, "int", 0 , ptr)
    DllCall( "RemoveMenu", ptr, h_menuDummy, "uint", 0, "uint", 0x400 )
    Menu, menuDummy, Delete, :%menu_name%
    
    return h_menu
}

donothing:
return