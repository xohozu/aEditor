INCLUDE MACRO.ASM

GLOBAL SEGMENT PUBLIC
    EXTRN MOUSE_BUF:BYTE
	EXTRN CUR_X:WORD, CUR_Y:WORD, PRE_X:WORD, PRE_Y:WORD
	EXTRN ON_LEFT_CLICK:WORD, ON_RIGHT_CLICK:WORD
GLOBAL ENDS

;公共函数
PUBLIC _SAVE_BLOCK     ;保存矩形块像素值到缓冲区
PUBLIC _RESTORE_BLOCK  ;将缓冲区像素值还原到矩形块
PUBLIC _DISPLAY_STRING ;在指定行列显示字符串
PUBLIC _WRITE_BLOCK_PIXEL ;以像素方式填充某一矩形块
CODE SEGMENT
	ASSUME CS:CODE,ES:GLOBAL

;以像素方式填充某一矩形块
;入口参数：矩形块左上角坐标(X,Y), 宽度WIDTH,高度HEIGHT, 填充属性ATTR(颜色)
;出口参数：无
PIXEL_X           EQU [BP+20]
PIXEL_Y           EQU [BP+18]
PIXEL_WIDTH       EQU [BP+16]
PIXEL_HEIGHT      EQU [BP+14]
PIXEL_ATTR        EQU [BP+12]

_WRITE_BLOCK_PIXEL PROC FAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH BP
	
	MOV BP,SP
	PUSH PIXEL_Y
	MOV CX,PIXEL_HEIGHT
WRITE_HEIGHT_LOOP:
	PUSH CX
	PUSH PIXEL_X
	MOV CX,PIXEL_WIDTH
WRITE_WIDTH_LOOP:
	__WRITE_PIXEL PIXEL_X,PIXEL_Y,PIXEL_ATTR
	INC WORD PTR PIXEL_X
	LOOP WRITE_WIDTH_LOOP
	POP PIXEL_X
	POP CX
	INC WORD PTR PIXEL_Y
	LOOP WRITE_HEIGHT_LOOP
	POP PIXEL_Y
	
	POP BP
	POP CX
	POP BX
	POP AX
	RET
_WRITE_BLOCK_PIXEL ENDP

;保存矩形块像素值到缓冲区
;入口参数：矩形块左上角坐标(X,Y), 宽度WIDTH,高度HEIGHT, 缓冲区偏移地址ADDRESS(在GLOBAL数据段)
;出口参数：无
BLOCK_X       EQU [BP+24]
BLOCK_Y       EQU [BP+22]
BLOCK_WIDTH   EQU [BP+20]
BLOCK_HEIGHT  EQU [BP+18]
BLOCK_ADDR    EQU [BP+16]

_SAVE_BLOCK PROC FAR
    PUSH AX
	PUSH BX
	PUSH CX
    PUSH SI
    PUSH ES
	PUSH BP
	
    MOV AX,GLOBAL
    MOV ES,AX
    MOV BP,SP
	
	MOV SI,BLOCK_ADDR
	PUSH BLOCK_Y            ;保护Y坐标
	MOV CX,BLOCK_HEIGHT
SAVE_HEIGHT_LOOP:
	PUSH CX
	PUSH BLOCK_X            ;保护X坐标
	MOV CX,BLOCK_WIDTH
SAVE_WIDTH_LOOP:
	__READ_PIXEL BLOCK_X,BLOCK_Y
	MOV ES:[SI],AL
	INC SI
	INC WORD PTR BLOCK_X
	LOOP SAVE_WIDTH_LOOP
	POP BLOCK_X
	POP CX
	INC WORD PTR BLOCK_Y
	LOOP SAVE_HEIGHT_LOOP
	POP BLOCK_Y
	
    POP BP
    POP ES
	POP SI
	POP CX
	POP BX
	POP AX
	RET
_SAVE_BLOCK ENDP

;将缓冲区像素值还原到矩形块
;入口参数：矩形块左上角坐标(X,Y), 宽度WIDTH,高度HEIGHT, 缓冲区偏移地址ADDRESS(在GLOBAL数据段)
;出口参数：无
_RESTORE_BLOCK PROC FAR
	PUSH AX
	PUSH BX
	PUSH CX
    PUSH SI
    PUSH ES
	PUSH BP
	
    MOV AX,GLOBAL
    MOV ES,AX
    MOV BP,SP
	
	MOV SI,BLOCK_ADDR
	PUSH BLOCK_Y            ;保护Y坐标
	MOV CX,BLOCK_HEIGHT
RESTORE_HEIGHT_LOOP:
	PUSH CX
	PUSH BLOCK_X            ;保护X坐标
	MOV CX,BLOCK_WIDTH
RESTORE_WIDTH_LOOP:
	MOV BL,ES:[SI]
	__WRITE_PIXEL BLOCK_X,BLOCK_Y,BL
	INC SI
	INC WORD PTR BLOCK_X
	LOOP RESTORE_WIDTH_LOOP
	POP BLOCK_X
	POP CX
	INC WORD PTR BLOCK_Y
	LOOP RESTORE_HEIGHT_LOOP
	POP BLOCK_Y
	
    POP BP
    POP ES
	POP SI
	POP CX
	POP BX
	POP AX
	RET
_RESTORE_BLOCK ENDP

;在指定行列显示字符串
;入口参数：显示起始位置坐标(行,列),需显示字符串地址(段:偏移地址),字符串长度,显示颜色
;出口参数：无
ROW        	 EQU   [BP+26]
COL       	 EQU   [BP+24]
STR_SEG 	 EQU   [BP+22]
STR_ADDR	 EQU   [BP+20]
STR_LEN      EQU   [BP+18]
STR_COLOR    EQU   [BP+16]

_DISPLAY_STRING PROC FAR
	__PUSH_REGS
	PUSH ES
	PUSH BP
	
	MOV BP,SP
	MOV BH,0
	MOV BL,STR_COLOR     ;;;;;;
	MOV DH,ROW
	MOV DL,COL
	MOV ES,STR_SEG
	MOV CX,STR_LEN
	MOV AX,STR_ADDR
	MOV BP,AX
	MOV AX,1300H
	INT 10H
	
	POP BP
	POP ES
	__POP_REGS
	RET
_DISPLAY_STRING ENDP

CODE ENDS
END
