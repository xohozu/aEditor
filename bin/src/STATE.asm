INCLUDE MACRO.ASM

EXTRN _DISPLAY_STRING:FAR
EXTRN _SAVE_BLOCK:FAR
EXTRN _RESTORE_BLOCK:FAR
EXTRN _WRITE_BLOCK_PIXEL:FAR

GLOBAL SEGMENT PUBLIC
    EXTRN MOUSE_BUF:BYTE,BUF:BYTE
	EXTRN CUR_X:WORD, CUR_Y:WORD, PRE_X:WORD, PRE_Y:WORD
	EXTRN ON_LEFT_CLICK:WORD, ON_RIGHT_CLICK:WORD
	EXTRN FILE_CLICK:BYTE,GRAPH_CLICK:BYTE,COLOR_CLICK:BYTE,HELP_CLICK:BYTE
	EXTRN DRAW_X:WORD
	EXTRN SELECTED:BYTE
GLOBAL ENDS

;
EXTRN _DISPLAY_COOR:FAR
EXTRN _DRAW_MOUSE:FAR

EXTRN _PRINT_FILE_OPTION:FAR 
EXTRN _FILE_NEW:FAR
EXTRN _FILE_OPEN:FAR
EXTRN _FILE_SAVE:FAR
EXTRN _FILE_QUIT:FAR

EXTRN _PRINT_GRAPH_OPTION:FAR
EXTRN _SET_LINE:FAR
EXTRN _SET_POLYLINE:FAR
EXTRN _SET_CIRCLE:FAR
EXTRN _SET_ARC:FAR
EXTRN _SET_ELLIPSE:FAR

EXTRN _PRINT_COLOR_OPTION:FAR
EXTRN _SET_RED:FAR
EXTRN _SET_GREEN:FAR
EXTRN _SET_BLUE:FAR

EXTRN _PRINT_HELP_OPTION:FAR

EXTRN _DRAW:FAR
EXTRN _SELECT:FAR
EXTRN _MOVE:FAR
EXTRN _DELETE:FAR

PUBLIC _GET_MOUSE_STATE      ;获取鼠标状态信息(坐标及按键)
PUBLIC _GET_ACTION           ;获取鼠标位置响应

DATA SEGMENT
	S_FILE   DB 'FILE'
	S_GRAPH  DB 'GRAPH'
	S_COLOR  DB 'COLOR'
	S_HELP   DB 'HELP'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,ES:GLOBAL,DS:DATA
;获取鼠标状态信息(坐标及按键)
;入口参数：无   出口参数：CUR_X,CUR_Y,PRE_X,PRE_Y,ON_LEFT_CLICK
_GET_MOUSE_STATE PROC FAR
	__PUSH_REGS
	PUSH ES
	
	MOV AX,GLOBAL
	MOV ES,AX
	MOV AX,03H
	INT 33H
	MOV AX,01H
	AND AX,BX
	MOV ES:ON_LEFT_CLICK,AX      ;获取鼠标左键按键
	MOV AX,02H
	AND AX,BX        
	SHR AX,1
	MOV ES:ON_RIGHT_CLICK,AX     ;获取鼠标右键按键
	CMP CX,ES:CUR_X
	JNE COOR_CHANGED          ;鼠标坐标改变
	CMP DX,ES:CUR_Y
	JE  QUIT
COOR_CHANGED:
	MOV AX,ES:CUR_X           ;保存旧坐标
	MOV ES:PRE_X,AX
	MOV AX,ES:CUR_Y
	MOV ES:PRE_Y,AX
	MOV ES:CUR_X,CX           ;保存新坐标     
	MOV ES:CUR_Y,DX
	
	CALL _DISPLAY_COOR
	
	__RESTORE_BLOCK ES:PRE_X,ES:PRE_Y,12,19,ES:MOUSE_BUF
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
QUIT:
	POP ES
	__POP_REGS
	RET
_GET_MOUSE_STATE ENDP

;获取鼠标位置响应
_GET_ACTION PROC FAR
	PUSH AX
	PUSH ES
	
	MOV AX,GLOBAL
	MOV ES,AX
	
	CMP ES:ON_LEFT_CLICK,1   
	JZ IS_FILE_SELECTED         ;按下左键
	JMP NOT_LEFT_CLICK       ;未按下左键
	
	;按下左键，则先检查FILE,GRAPH,COLOR,HELP菜单项是否已点击
IS_FILE_SELECTED:
	;__DELAY 33144
	CMP ES:FILE_CLICK,1       
	JNZ IS_GRAPH_SELECTED       ;FILE下拉菜单未出现,则检查GRAPH
	
	;FILE下拉菜单出现，则检查其子项目
IS_FILE_NEW_CLICK:
	CMP ES:CUR_X,72          ;CUR_X < 72则肯定未选中任何菜单
	JB IS_GRAPH_SELECTED
	CMP ES:CUR_X,120         ;CUR_X >= 120则肯定未选中 文件下拉菜单
	JAE IS_GRAPH_SELECTED
	CMP ES:CUR_Y,32
	JB IS_FILE_OPEN_CLICK
	CMP ES:CUR_Y,48
	JAE IS_FILE_OPEN_CLICK
	;选中NEW
	CALL _FILE_NEW
	JMP GET_STATE_FINISH
	
IS_FILE_OPEN_CLICK:
	CMP ES:CUR_Y,48
	JB IS_FILE_SAVE_CLICK
	CMP ES:CUR_Y,64
	JAE IS_FILE_SAVE_CLICK
	;选中OPEN
	CALL _FILE_OPEN
	JMP GET_STATE_FINISH
	
IS_FILE_SAVE_CLICK:
	CMP ES:CUR_Y,64
	JB IS_FILE_QUIT_CLICK
	CMP ES:CUR_Y,80
	JAE IS_FILE_QUIT_CLICK
	;选中SAVE
	CALL _FILE_SAVE
	JMP GET_STATE_FINISH
	
IS_FILE_QUIT_CLICK:
	CMP ES:CUR_Y,80
	JB IS_GRAPH_SELECTED
	CMP ES:CUR_Y,96
	JAE IS_GRAPH_SELECTED
	;选中QUIT
	CALL _FILE_QUIT
	JMP GET_STATE_FINISH
	
IS_GRAPH_SELECTED:
	CMP ES:GRAPH_CLICK,1
	JZ IS_GRAPH_LINE_CLICK
	JMP IS_COLOR_SELECTED
	;JNZ IS_COLOR_SELECTED      ;GRAPH下拉菜单未出现，则检查COLOR
	
	;GRAPH下拉菜单出现，则检查其子项目
IS_GRAPH_LINE_CLICK:
	CMP ES:CUR_X,152
	;JB IS_COLOR_SELECTED
	JAE NEXT1
	JMP IS_COLOR_SELECTED
NEXT1:
	CMP ES:CUR_X,232
	JAE IS_COLOR_SELECTED
	CMP ES:CUR_Y,32
	JB IS_GRAPH_POLYLINE_CLICK
	CMP ES:CUR_Y,48
	JAE IS_GRAPH_POLYLINE_CLICK
	;
	CALL _SET_LINE
	JMP GET_STATE_FINISH
	
IS_GRAPH_POLYLINE_CLICK:
	CMP ES:CUR_Y,48
	JB IS_GRAPH_CIRCLE_CLICK
	CMP ES:CUR_Y,64
	JAE IS_GRAPH_CIRCLE_CLICK
	;
	CALL _SET_POLYLINE
	JMP GET_STATE_FINISH
	
IS_GRAPH_CIRCLE_CLICK:
	CMP ES:CUR_Y,64
	JB IS_GRAPH_ARC_CLICK
	CMP ES:CUR_Y,80
	JAE IS_GRAPH_ARC_CLICK
	;
	CALL _SET_CIRCLE
	JMP GET_STATE_FINISH
	
IS_GRAPH_ARC_CLICK:
	CMP ES:CUR_Y,80
	JB IS_GRAPH_ELLIPSE_CLICK
	CMP ES:CUR_Y,96
	JAE IS_GRAPH_ELLIPSE_CLICK
	;
	CALL _SET_ARC
	JMP GET_STATE_FINISH
	
IS_GRAPH_ELLIPSE_CLICK:
	CMP ES:CUR_Y,96
	JB IS_COLOR_SELECTED
	CMP ES:CUR_Y,112
	JAE IS_COLOR_SELECTED
	;
	CALL _SET_ELLIPSE
	JMP GET_STATE_FINISH
	
IS_COLOR_SELECTED:
	CMP ES:COLOR_CLICK,1
	JNZ IS_HELP_SELECTED
	
	;COLOR
IS_RED_CLICK:
	CMP ES:CUR_X,232
	JB IS_HELP_SELECTED
	CMP ES:CUR_X,288
	JAE IS_HELP_SELECTED
	CMP ES:CUR_Y,32
	JB IS_GREEN_CLICK
	CMP ES:CUR_Y,48
	JAE IS_GREEN_CLICK
	;
	CALL _SET_RED
	JMP GET_STATE_FINISH
	
IS_GREEN_CLICK:
	CMP ES:CUR_Y,48
	JB IS_BLUE_CLICK
	CMP ES:CUR_Y,64
	JAE IS_BLUE_CLICK
	;
	CALL _SET_GREEN
	JMP GET_STATE_FINISH
	
IS_BLUE_CLICK:
	CMP ES:CUR_Y,64
	JB IS_HELP_SELECTED
	CMP ES:CUR_Y,80
	JAE IS_HELP_SELECTED
	;
	CALL _SET_BLUE
	JMP GET_STATE_FINISH
	
IS_HELP_SELECTED:
	CMP ES:HELP_CLICK,1
	JNZ IS_FILE_CLICKED

IS_ABOUT_CLICK:
	CMP ES:CUR_X,312
	JB IS_FILE_CLICKED
	CMP ES:CUR_X,368
	JAE IS_FILE_CLICKED
	CMP ES:CUR_Y,32
	JB IS_FILE_CLICKED
	CMP ES:CUR_Y,48
	JAE IS_FILE_CLICKED
	;;;;;未实现ABOUT
	;CALL
	JMP GET_STATE_FINISH
	
IS_FILE_CLICKED:
	CMP ES:CUR_X,80
	JAE FILE_NEXT1
	JMP IS_GRAPH_CLICKED
FILE_NEXT1:
	CMP ES:CUR_X,112
	JB FILE_NEXT2
	JMP IS_GRAPH_CLICKED
FILE_NEXT2:
	CMP ES:CUR_Y,16
	JAE FILE_NEXT3
	JMP IS_GRAPH_CLICKED
FILE_NEXT3:
	CMP ES:CUR_Y,32
	JB FILE_NEXT4
	JMP IS_GRAPH_CLICKED
FILE_NEXT4:
	
	;FILE CLICKED
	__DELAY 33144  ;0.5SECS
	PUSH AX
	MOV AL,0
	OR AL,HELP_CLICK
	OR AL,GRAPH_CLICK
	OR AL,COLOR_CLICK
	CMP AL,1
	POP AX
	JNZ FILE_NEXT5
	JMP GET_STATE_FINISH
	
FILE_NEXT5:
	CMP ES:FILE_CLICK,1       ;下拉菜单是否已经打开，如果打开此次点击则取消
	JZ FILE_NEXT6
	JMP OPEN_FILE_SUBMENU
	;JNZ OPEN_FILE_SUBMENU
FILE_NEXT6:
	;CLOSE FILE SUBMENU
	MOV ES:FILE_CLICK,0       ;文件下拉菜单关闭
	MOV ES:ON_LEFT_CLICK,0    ;消除左键按键记录
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF ;隐藏鼠标即还原鼠标覆盖部分
	__RESTORE_BLOCK 72,32,48,64,ES:BUF                   ;还原文件子菜单覆盖部分
	__DISPLAY_STRING 1,10,DATA,S_FILE, 4,09H
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF    ;保存鼠标将覆盖部分
	CALL _DRAW_MOUSE
	JMP GET_STATE_FINISH
	
OPEN_FILE_SUBMENU:	
	MOV ES:FILE_CLICK,1       ;文件下拉菜单打开
	MOV ES:ON_LEFT_CLICK,0    ;消除左键按键记录
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	__SAVE_BLOCK 72,32,48,64,ES:BUF                      ;保存文件子菜单将覆盖部分
	CALL _PRINT_FILE_OPTION                              ;打印文件子菜单
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
	JMP GET_STATE_FINISH
	
IS_GRAPH_CLICKED:
	CMP ES:CUR_X,160
	JAE GRAPH_NEXT1
	JMP IS_COLOR_CLICKED
GRAPH_NEXT1:
	CMP ES:CUR_X,200
	JB GRAPH_NEXT2
	JMP IS_COLOR_CLICKED
GRAPH_NEXT2:
	CMP ES:CUR_Y,16
	JAE GRAPH_NEXT3
	JMP IS_COLOR_CLICKED
GRAPH_NEXT3:
	CMP ES:CUR_Y,32
	JB GRAPH_NEXT4
	JMP IS_COLOR_CLICKED
GRAPH_NEXT4:
	;GRAPH CLICKED
	__DELAY 33144
	PUSH AX
	MOV AL,0
	OR AL,FILE_CLICK
	OR AL,HELP_CLICK
	OR AL,COLOR_CLICK
	CMP AL,1
	POP AX
	JNZ GRAPH_NEXT5
	JMP GET_STATE_FINISH
	
GRAPH_NEXT5:
	CMP ES:GRAPH_CLICK,1
	JZ GRAPH_NEXT6
	JMP OPEN_GRAPH_SUBMENU
	;JNZ OPEN_GRAPH_SUBMENU
GRAPH_NEXT6:
	;CLOSE GRAPH SUBMENU
	MOV ES:GRAPH_CLICK,0       
	MOV ES:ON_LEFT_CLICK,0    ;消除左键按键记录
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF ;隐藏鼠标即还原鼠标覆盖部分
	__RESTORE_BLOCK 152,32,80,80,ES:BUF                ;还原图形子菜单覆盖部分
	__DISPLAY_STRING 1,20,DATA,S_GRAPH,5,09H
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF    ;保存鼠标将覆盖部分
	CALL _DRAW_MOUSE
	JMP GET_STATE_FINISH
OPEN_GRAPH_SUBMENU:
	MOV ES:GRAPH_CLICK,1
	MOV ES:ON_LEFT_CLICK,0
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF ;隐藏鼠标即还原鼠标覆盖部分
	__SAVE_BLOCK 152,32,80,80,ES:BUF                
	CALL _PRINT_GRAPH_OPTION
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF    ;保存鼠标将覆盖部分
	CALL _DRAW_MOUSE
	JMP GET_STATE_FINISH
	
IS_COLOR_CLICKED:
	CMP ES:CUR_X,240
	JAE COLOR_NEXT1
	JMP IS_HELP_CLICKED
COLOR_NEXT1:
	CMP ES:CUR_X,280
	JB COLOR_NEXT2
	JMP IS_HELP_CLICKED
COLOR_NEXT2:
	CMP ES:CUR_Y,16
	JAE COLOR_NEXT3
	JMP IS_HELP_CLICKED
COLOR_NEXT3:
	CMP ES:CUR_Y,32
	JB COLOR_NEXT4
	JMP IS_HELP_CLICKED
COLOR_NEXT4:
	;COLOR CLICKED
	__DELAY 33144
	PUSH AX
	MOV AL,0
	OR AL,FILE_CLICK
	OR AL,GRAPH_CLICK
	OR AL,HELP_CLICK
	CMP AL,1
	POP AX
	JNZ COLOR_NEXT5
	JMP GET_STATE_FINISH
	
COLOR_NEXT5:
	CMP ES:COLOR_CLICK,1
	JZ COLOR_NEXT6
	JMP OPEN_COLOR_SUBMENU
	;JNZ OPEN_COLOR_SUBMENU
COLOR_NEXT6:
	;CLOSE COLOR SUBMENU
	MOV ES:COLOR_CLICK,0
	MOV ES:ON_LEFT_CLICK,0
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	__RESTORE_BLOCK 232,32,56,48,ES:BUF
	__DISPLAY_STRING 1,30,DATA,S_COLOR,5,09H
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
	JMP GET_STATE_FINISH
OPEN_COLOR_SUBMENU:
	MOV ES:COLOR_CLICK,1
	MOV ES:ON_LEFT_CLICK,0
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	__SAVE_BLOCK 232,32,56,48,ES:BUF
	CALL _PRINT_COLOR_OPTION
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
	JMP GET_STATE_FINISH
	
IS_HELP_CLICKED:
	CMP ES:CUR_X,320
	JAE HELP_NEXT1
	JMP NOT_SELECT_ANY_MENU
HELP_NEXT1:
	CMP ES:CUR_X,352
	JB HELP_NEXT2
	JMP NOT_SELECT_ANY_MENU
HELP_NEXT2:
	CMP ES:CUR_Y,16
	JAE HELP_NEXT3
	JMP NOT_SELECT_ANY_MENU
HELP_NEXT3:
	CMP ES:CUR_Y,32
	JB HELP_NEXT4
	JMP NOT_SELECT_ANY_MENU
HELP_NEXT4:
	;HELP CLICKED
	__DELAY 33144
	PUSH AX
	MOV AL,0
	OR AL,FILE_CLICK
	OR AL,GRAPH_CLICK
	OR AL,COLOR_CLICK
	CMP AL,1
	POP AX
	JNZ HELP_NEXT5
	JMP GET_STATE_FINISH
	
HELP_NEXT5:
	CMP ES:HELP_CLICK,1
	JZ HELP_NEXT6
	JMP OPEN_HELP_SUBMENU
	;JNZ OPEN_HELP_SUBMENU
HELP_NEXT6:
	;CLOSE COLOR SUBMENU
	MOV ES:HELP_CLICK,0
	MOV ES:ON_LEFT_CLICK,0
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	__RESTORE_BLOCK 312,32,56,16,ES:BUF
	__DISPLAY_STRING 1,40,DATA,S_HELP, 4,09H
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
	JMP GET_STATE_FINISH
OPEN_HELP_SUBMENU:
	MOV ES:HELP_CLICK,1
	MOV ES:ON_LEFT_CLICK,0
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	__SAVE_BLOCK 312,32,56,16,ES:BUF
	CALL _PRINT_HELP_OPTION
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
	JMP GET_STATE_FINISH

NOT_SELECT_ANY_MENU:         ;未选中FILE,GRAPH,COLOR,HELP
	CMP ES:SELECTED,1        ;判断是否已经出现选择框
	JNZ GO_TO_DRAW
	;MOV ES:SELECTED,0
	CALL _MOVE
	__DELAY 33144
	JMP GET_STATE_FINISH
GO_TO_DRAW:
	CALL _DRAW
	JMP GET_STATE_FINISH
NOT_LEFT_CLICK:
	CMP ES:DRAW_X,00FFH      ;是否在白板内
	JZ GET_STATE_FINISH
	CMP ES:SELECTED,1
	JZ SELECT_IS_DELETE      ;已有选择框是否按删除键
	CMP ES:ON_RIGHT_CLICK,1  ;测试是否按下右键
	JNZ GET_STATE_FINISH     
	CALL _SELECT
	JMP GET_STATE_FINISH
SELECT_IS_DELETE:
	CALL _DELETE
GET_STATE_FINISH:

	POP ES
	POP AX
	RET
_GET_ACTION ENDP


CODE ENDS
END
