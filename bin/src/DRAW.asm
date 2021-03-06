INCLUDE MACRO.ASM
INCLUDE LINE.ASM
INCLUDE CIRCLE.ASM

;
PUBLIC _DRAW

EXTRN _GET_MOUSE_STATE:FAR
EXTRN _RESTORE_BLOCK:FAR
EXTRN _SAVE_BLOCK:FAR
EXTRN _DRAW_MOUSE:FAR

GLOBAL SEGMENT PUBLIC
	EXTRN ON_LEFT_CLICK:WORD,ON_RIGHT_CLICK:WORD
	EXTRN MOUSE_BUF:BYTE
	EXTRN CUR_X:WORD,CUR_Y:WORD,PRE_X:WORD,PRE_Y:WORD
	EXTRN DRAW_X:WORD,DRAW_Y:WORD
	EXTRN DRAW_TYPE:BYTE,DRAW_COLOR:BYTE
GLOBAL ENDS

DATA SEGMENT 
	GRAPH_BUF DB 8192 DUP(?)
	START_X DW ?
	START_Y DW ?
	END_X   DW ?
	END_Y   DW ?
	LINE_Y2_Y1    DW ?    ;值为Y2-Y1  直线起始坐标为(X1,Y1),(X2,Y2)
	LINE_X2_X1    DW ?    ;值为X2-X1
	LINE_X1_X2    DW ?
	LINE_Y1_Y2    DW ?
	VAR1          DW ?    ;画线所需辅助变量
	VAR2          DW ?
	RADIUS        DW ?    ; 半径
	X_CENTER      DW ?    ; 圆心 
	Y_CENTER      DW ?
	PRE_RADIUS    DW ?
	PRE_X_CENTER  DW ?
	PRE_Y_CENTER  DW ?
DATA ENDS

CODE SEGMENT 
	ASSUME CS:CODE,ES:GLOBAL,DS:DATA
	
_DRAW PROC FAR
	PUSH AX
	PUSH DS
	PUSH ES
	MOV AX,GLOBAL
	MOV ES,AX
	MOV AX,DATA
	MOV DS,AX
	
	__DELAY 33144
	CMP ES:DRAW_X,00FFH     ;由显示坐标即可判断是否超出白板范围
	JZ OUT_OF_RANGE
	MOV AX,ES:CUR_X
	MOV START_X,AX
	MOV END_X,AX
	MOV AX,ES:CUR_Y
	MOV START_Y,AX
	MOV END_Y,AX
	
	CMP ES:DRAW_TYPE,0
	JZ DRAW_LINE
	CMP ES:DRAW_TYPE,1
	JZ DRAW_POLYLINE
	CMP ES:DRAW_TYPE,2
	JZ DRAW_CIRCLE
	
DRAW_LINE:	
	CALL _DRAW_LINE
	JMP DRAW_FINISH
DRAW_POLYLINE:
	CALL _DRAW_POLYLINE
	JMP DRAW_FINISH
DRAW_CIRCLE:
	CALL _DRAW_CIRCLE
	JMP DRAW_FINISH
	
OUT_OF_RANGE:
DRAW_FINISH:

	POP ES
	POP DS
	POP AX
	RET
_DRAW ENDP

_DRAW_CIRCLE PROC NEAR
	PUSH AX
	PUSH DS
	PUSH ES
	MOV AX,DATA
	MOV DS,AX
	MOV AX,GLOBAL
	MOV ES,AX
	
	CALL _GET_CIRCLE_CENTER_AND_RADIUS
DRAW_CIRCLE_LOOP:
	CALL _GET_MOUSE_STATE
	CMP ES:ON_LEFT_CLICK,1     ;左键不放
	JZ DRAW_CIRCLE_IS_COOR_CHANGED
	JMP DRAW_LINE_FINISH
	
DRAW_CIRCLE_IS_COOR_CHANGED:
	MOV AX,ES:CUR_X
	CMP AX,END_X
	JNZ DRAW_CIRCLE_IS_IN_RANGE
	MOV AX,ES:CUR_Y
	CMP AX,END_Y
	JZ DRAW_CIRCLE_LOOP        ;坐标未改变
DRAW_CIRCLE_IS_IN_RANGE:
	CMP ES:CUR_X,8
	JB DRAW_CIRCLE_OUT_OF_RANGE
	CMP ES:CUR_X,536
	JAE DRAW_CIRCLE_OUT_OF_RANGE
	CMP ES:CUR_Y,32
	JB DRAW_CIRCLE_OUT_OF_RANGE
	CMP ES:CUR_Y,464
	JAE DRAW_CIRCLE_OUT_OF_RANGE
	JMP DRAW_CIRCLE_GO_ON
	
DRAW_CIRCLE_OUT_OF_RANGE:
	JMP DRAW_CIRCLE_FINISH
	
DRAW_CIRCLE_GO_ON:
	MOV AX,RADIUS           ;保存上次圆心和半径
	MOV PRE_RADIUS,AX
	MOV AX,X_CENTER
	MOV PRE_X_CENTER,AX
	MOV AX,Y_CENTER
	MOV PRE_Y_CENTER,AX
	
	MOV AX,ES:CUR_X
	MOV END_X,AX
	MOV AX,ES:CUR_Y
	MOV END_Y,AX
	
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	__CIRCLE_RESTORE PRE_X_CENTER,PRE_Y_CENTER,PRE_RADIUS
	
	CALL _GET_CIRCLE_CENTER_AND_RADIUS
	__CIRCLE_DRAW X_CENTER,Y_CENTER,RADIUS,ES:DRAW_COLOR
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
	JMP DRAW_CIRCLE_LOOP
	
DRAW_CIRCLE_FINISH:
	POP ES
	POP DS
	POP AX
	RET
_DRAW_CIRCLE ENDP

;利用START_X,START_Y,END_X,END_Y  求圆心坐标和半径
_GET_CIRCLE_CENTER_AND_RADIUS PROC NEAR
	__PUSH_REGS
	PUSH DS
	PUSH ES
	
	MOV AX,DATA
	MOV DS,AX
	MOV AX,GLOBAL
	MOV ES,AX
	
	MOV AX,START_X
	MOV BX,START_Y
	MOV CX,END_X
	MOV DX,END_Y
	CMP AX,CX
	JB RIGHT
LEFT:
	PUSH AX
	SUB AX,CX
	MOV CX,AX
	POP AX
	CMP BX,DX
	JB LEFT_DOWN
LEFT_UP:
	PUSH BX
	SUB BX,DX
	MOV DX,BX
	POP BX
	CMP CX,DX
	JB LEFT_UP_CX_LESS_DX
LEFT_UP_DX_LESS_CX:
	SHR DX,1
	SUB AX,DX
	SUB BX,DX
	MOV RADIUS,DX
	JMP GET_CIRCLE_CENTER_AND_RADIUS_FINISH
LEFT_UP_CX_LESS_DX:
	SHR CX,1
	SUB AX,CX
	SUB BX,CX
	MOV RADIUS,CX
	JMP GET_CIRCLE_CENTER_AND_RADIUS_FINISH
	
LEFT_DOWN:
	SUB DX,BX
	CMP CX,DX
	JB LEFT_DOWN_CX_LESS_DX
LEFT_DOWN_DX_LESS_CX:
	SHR DX,1
	SUB AX,DX
	ADD BX,DX
	MOV RADIUS,DX
	JMP GET_CIRCLE_CENTER_AND_RADIUS_FINISH
LEFT_DOWN_CX_LESS_DX:
	SHR DX,1
	SUB AX,CX
	ADD BX,CX
	MOV RADIUS,DX
	JMP GET_CIRCLE_CENTER_AND_RADIUS_FINISH
	
RIGHT:
	SUB CX,AX
	CMP BX,DX
	JB RIGHT_DOWN
RIGHT_UP:
	PUSH BX
	SUB BX,DX
	MOV DX,BX
	POP BX
	CMP CX,DX            ;判断高度和宽度的大小，取小值
	JB RIGHT_UP_CX_LESS_DX
RIGHT_UP_DX_LESS_CX:
	SHR DX,1
	ADD AX,DX
	SUB BX,DX
	MOV RADIUS,DX
	JMP GET_CIRCLE_CENTER_AND_RADIUS_FINISH
RIGHT_UP_CX_LESS_DX:
	SHR CX,1
	ADD AX,CX
	SUB BX,CX
	MOV RADIUS,CX
	JMP GET_CIRCLE_CENTER_AND_RADIUS_FINISH
	
RIGHT_DOWN:
	SUB DX,BX
	CMP CX,DX
	JB RIGHT_DOWN_CX_LESS_DX
RIGHT_DOWN_DX_LESS_CX:
	SHR DX,1
	ADD AX,DX
	ADD BX,DX
	MOV RADIUS,DX
	JMP GET_CIRCLE_CENTER_AND_RADIUS_FINISH
RIGHT_DOWN_CX_LESS_DX:
	SHR CX,1
	ADD AX,CX
	ADD BX,CX
	MOV RADIUS,CX
	
GET_CIRCLE_CENTER_AND_RADIUS_FINISH:
	MOV X_CENTER,AX
	MOV Y_CENTER,BX

	POP ES
	POP DS
	__POP_REGS
	RET
_GET_CIRCLE_CENTER_AND_RADIUS ENDP


_DRAW_POLYLINE PROC NEAR
	PUSH AX
	PUSH DS
	PUSH ES
	MOV AX,GLOBAL
	MOV ES,AX
	MOV AX,DATA
	MOV DS,AX
	
DRAW_POLYLINE_LOOP:
	CALL _GET_MOUSE_STATE               ;循环获取鼠标状
	CMP ES:ON_RIGHT_CLICK,1   
	JNZ DRAW_POLYLINE_IS_LEFT_CLICKED
	JMP DRAW_POLYLINE_FINISH            ;点击右键则退出画多边形
	
DRAW_POLYLINE_IS_LEFT_CLICKED:
	CMP ES:ON_LEFT_CLICK,1
	JNZ DRAW_POLYLINE_IS_COOR_CHANGED
	MOV AX,END_X
	MOV START_X,AX
	MOV AX,END_Y
	MOV START_Y,AX
	
DRAW_POLYLINE_IS_COOR_CHANGED:
	MOV AX,ES:CUR_X
	CMP AX,END_X
	JNZ DRAW_POLYLINE_IS_IN_RANGE
	MOV AX,ES:CUR_Y
	CMP AX,END_Y
	JZ DRAW_POLYLINE_LOOP
	
DRAW_POLYLINE_IS_IN_RANGE:
	CMP ES:CUR_X,8
	JB DRAW_POLYLINE_OUT_OF_RANGE
	CMP ES:CUR_X,536
	JAE DRAW_POLYLINE_OUT_OF_RANGE
	CMP ES:CUR_Y,32
	JB DRAW_POLYLINE_OUT_OF_RANGE
	CMP ES:CUR_Y,464
	JAE DRAW_POLYLINE_OUT_OF_RANGE
	JMP DRAW_POLYLINE_GO_ON

DRAW_POLYLINE_OUT_OF_RANGE:
	JMP DRAW_POLYLINE_FINISH
	
DRAW_POLYLINE_GO_ON:
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	__LINE_RESTORE START_X,START_Y,END_X,END_Y
	MOV AX,ES:CUR_X
	MOV END_X,AX
	MOV AX,ES:CUR_Y
	MOV END_Y,AX
	__LINE_DRAW START_X,START_Y,END_X,END_Y,ES:DRAW_COLOR
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
	JMP DRAW_POLYLINE_LOOP
	
DRAW_POLYLINE_FINISH:
	__DELAY 33144
	MOV ES:ON_RIGHT_CLICK,0
	POP ES
	POP DS
	POP AX
	RET
_DRAW_POLYLINE ENDP


_DRAW_LINE PROC NEAR
	PUSH AX
	PUSH DS
	PUSH ES
	MOV AX,GLOBAL
	MOV ES,AX
	MOV AX,DATA
	MOV DS,AX
	
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	__LINE_DRAW START_X,START_Y,END_X,END_Y,ES:DRAW_COLOR
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
DRAW_LINE_LOOP:            
	;__DELAY 33144
	CALL _GET_MOUSE_STATE                 ;循环获取鼠标状态
	CMP ES:ON_LEFT_CLICK,1                ;只要鼠标左键不放就循环画
	JZ DRAW_LINE_IS_COOR_CHANGED
	JMP DRAW_LINE_FINISH
	
DRAW_LINE_IS_COOR_CHANGED:                ;判断坐标是否改变
	MOV AX,ES:CUR_X
	CMP AX,END_X;ES:PRE_X
	JNZ DRAW_LINE_IS_IN_RANGE
	MOV AX,ES:CUR_Y
	CMP AX,END_Y;ES:PRE_Y
	JZ DRAW_LINE_LOOP
	
DRAW_LINE_IS_IN_RANGE:                   ;判断是否在白板内
	CMP ES:CUR_X,8
	JB DRAW_LINE_OUT_OF_RANGE
	CMP ES:CUR_X,536
	JAE DRAW_LINE_OUT_OF_RANGE
	CMP ES:CUR_Y,32
	JB DRAW_LINE_OUT_OF_RANGE
	CMP ES:CUR_Y,464
	JAE DRAW_LINE_OUT_OF_RANGE
	JMP DRAW_LINE_GO_ON                  ;未超出范围
	
DRAW_LINE_OUT_OF_RANGE:                  ;超出白板范围则推出
	JMP DRAW_LINE_FINISH
	
DRAW_LINE_GO_ON:
	__RESTORE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	__LINE_RESTORE START_X,START_Y,END_X,END_Y
	MOV AX,ES:CUR_X
	MOV END_X,AX
	MOV AX,ES:CUR_Y
	MOV END_Y,AX
	__LINE_DRAW START_X,START_Y,END_X,END_Y,ES:DRAW_COLOR
	__SAVE_BLOCK ES:CUR_X,ES:CUR_Y,12,19,ES:MOUSE_BUF
	CALL _DRAW_MOUSE
	JMP DRAW_LINE_LOOP
	
DRAW_LINE_FINISH:
	POP ES
	POP DS
	POP AX
	RET
_DRAW_LINE ENDP
	
CODE ENDS
END

