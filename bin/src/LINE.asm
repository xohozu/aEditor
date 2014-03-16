__LINE_DRAW MACRO X1,Y1,X2,Y2,COLOR 
	LOCAL RIGHT,LEFT
	LOCAL RIGHT_UP,RIGHT_DOWN,LEFT_UP,LEFT_DOWN
	LOCAL RIGHT_UP_1,RIGHT_UP_2,RIGHT_UP_3
	LOCAL RIGHT_DOWN_1,RIGHT_DOWN_2,RIGHT_DOWN_3
	LOCAL LEFT_UP_1,LEFT_UP_2,LEFT_UP_3
	LOCAL LEFT_DOWN_1,LEFT_DOWN_2,LEFT_DOWN_3
	LOCAL FINISH
	
	__PUSH_REGS
	PUSH SI
	
	MOV AX,DATA
	MOV DS,AX
	LEA SI,GRAPH_BUF   ;保存图形覆盖部分
	
	MOV AX,X2
	SUB AX,X1          ;X2-X1
	MOV LINE_X2_X1,AX
	MOV AX,X1
	SUB AX,X2          ;X1-X2
	MOV LINE_X1_X2,AX
	MOV AX,Y2
	SUB AX,Y1          ;Y2-Y1
	MOV LINE_Y2_Y1,AX
	MOV AX,Y1
	SUB AX,Y2          ;Y1-Y2
	MOV LINE_Y1_Y2,AX
	MOV VAR1,0   ;初始化辅助变量VAR1,VAR2
	MOV VAR2,0 
	
	MOV AX,X1
	MOV BX,X2
	MOV CX,Y1
	MOV DX,Y2
	CMP AX,BX          ;判断水平方向
	;JA LEFT            ;AX>BX LEFT
	JBE RIGHT
	JMP LEFT
RIGHT:
	CMP CX,DX          ;判断垂直方向
	JA RIGHT_UP        ;
RIGHT_DOWN:
	MOV AH,0CH
	MOV AL,COLOR
	MOV BH,0
	MOV CX,X1
	MOV DX,Y1
RIGHT_DOWN_1:
	PUSH AX
	MOV AX,VAR1
	ADD AX,LINE_Y2_Y1
	MOV VAR1,AX
	CMP AX,LINE_X2_X1
	POP AX
	JBE RIGHT_DOWN_2
	PUSH AX
	MOV AX,VAR1
	SUB AX,LINE_X2_X1
	MOV VAR1,AX
	POP AX
	INC DX
RIGHT_DOWN_2:
	PUSH AX
	MOV AX,VAR2
	ADD AX,LINE_X2_X1
	MOV VAR2,AX
	CMP AX,LINE_Y2_Y1
	POP AX
	JBE RIGHT_DOWN_3
	PUSH AX
	MOV AX,VAR2
	SUB AX,LINE_Y2_Y1
	MOV VAR2,AX
	POP AX
	INC CX
RIGHT_DOWN_3:
	;先保存，后写
	PUSH AX
	MOV AH,0DH
	INT 10H
	MOV [SI],AL
	INC SI
	POP AX
	INT 10H
	CMP CX,X2
	JB RIGHT_DOWN_1
	JMP FINISH

RIGHT_UP:
	MOV AH,0CH
	MOV AL,COLOR
	MOV BH,0
	MOV CX,X1
	MOV DX,Y1
RIGHT_UP_1:
	PUSH AX
	MOV AX,VAR1
	ADD AX,LINE_Y1_Y2
	MOV VAR1,AX
	CMP AX,LINE_X2_X1
	POP AX
	JBE RIGHT_UP_2
	PUSH AX
	MOV AX,VAR1
	SUB AX,LINE_X2_X1
	MOV VAR1,AX
	POP AX
	DEC DX
RIGHT_UP_2:
	PUSH AX
	MOV AX,VAR2
	ADD AX,LINE_X2_X1
	MOV VAR2,AX
	CMP AX,LINE_Y1_Y2
	POP AX
	JBE RIGHT_UP_3
	PUSH AX
	MOV AX,VAR2
	SUB AX,LINE_Y1_Y2
	MOV VAR2,AX
	POP AX
	INC CX
RIGHT_UP_3:
	;先保存像素点(CX,DX),再写像素点(CX,DX)
	PUSH AX
	MOV AH,0DH
	INT 10H
	MOV [SI],AL
	INC SI
	POP AX
	INT 10H
	CMP CX,X2
	JB RIGHT_UP_1
	JMP FINISH

LEFT:
	MOV CX,Y1
	MOV DX,Y2
	CMP CX,DX
	JA LEFT_UP
LEFT_DOWN:
	MOV AH,0CH
	MOV AL,COLOR
	MOV BH,0
	MOV CX,X1
	MOV DX,Y1
LEFT_DOWN_1:
	PUSH AX
	MOV AX,VAR1
	ADD AX,LINE_Y2_Y1
	MOV VAR1,AX
	CMP AX,LINE_X1_X2
	POP AX
	JBE LEFT_DOWN_2
	PUSH AX
	MOV AX,VAR1
	SUB AX,LINE_X1_X2
	MOV VAR1,AX
	POP AX
	INC DX
LEFT_DOWN_2:
	PUSH AX
	MOV AX,VAR2
	ADD AX,LINE_X1_X2
	MOV VAR2,AX
	CMP AX,LINE_Y2_Y1
	POP AX
	JBE LEFT_DOWN_3
	PUSH AX
	MOV AX,VAR2
	SUB AX,LINE_Y2_Y1
	MOV VAR2,AX
	POP AX
	DEC CX
LEFT_DOWN_3:
	PUSH AX
	MOV AH,0DH
	INT 10H
	MOV [SI],AL
	INC SI
	POP AX
	INT 10H
	CMP CX,X2
	JA LEFT_DOWN_1
	JMP FINISH

LEFT_UP:
	MOV AH,0CH
	MOV AL,COLOR
	MOV BH,0
	MOV CX,X1
	MOV DX,Y1
LEFT_UP_1:
	PUSH AX
	MOV AX,VAR1
	ADD AX,LINE_Y1_Y2
	MOV VAR1,AX
	CMP AX,LINE_X1_X2
	POP AX
	JBE LEFT_UP_2
	PUSH AX
	MOV AX,VAR1
	SUB AX,LINE_X1_X2
	MOV VAR1,AX
	POP AX
	DEC DX
LEFT_UP_2:
	PUSH AX
	MOV AX,VAR2
	ADD AX,LINE_X1_X2
	MOV VAR2,AX
	CMP AX,LINE_Y1_Y2
	POP AX
	JBE LEFT_UP_3
	PUSH AX
	MOV AX,VAR2
	SUB AX,LINE_Y1_Y2
	MOV VAR2,AX
	POP AX
	DEC CX
LEFT_UP_3:
	PUSH AX
	MOV AH,0DH
	INT 10H
	MOV [SI],AL
	INC SI
	POP AX
	INT 10H
	CMP CX,X2
	JA LEFT_UP_1
FINISH:
	POP SI
	__POP_REGS
ENDM

__LINE_RESTORE MACRO X1,Y1,X2,Y2
	LOCAL RIGHT,LEFT
	LOCAL RIGHT_UP,RIGHT_DOWN,LEFT_UP,LEFT_DOWN
	LOCAL RIGHT_UP_1,RIGHT_UP_2,RIGHT_UP_3
	LOCAL RIGHT_DOWN_1,RIGHT_DOWN_2,RIGHT_DOWN_3
	LOCAL LEFT_UP_1,LEFT_UP_2,LEFT_UP_3
	LOCAL LEFT_DOWN_1,LEFT_DOWN_2,LEFT_DOWN_3
	LOCAL FINISH
	
	__PUSH_REGS
	PUSH SI
	
	MOV AX,DATA
	MOV DS,AX
	LEA SI,GRAPH_BUF  
	
	MOV AX,X2
	SUB AX,X1          ;X2-X1
	MOV LINE_X2_X1,AX
	MOV AX,X1
	SUB AX,X2          ;X1-X2
	MOV LINE_X1_X2,AX
	MOV AX,Y2
	SUB AX,Y1          ;Y2-Y1
	MOV LINE_Y2_Y1,AX
	MOV AX,Y1
	SUB AX,Y2          ;Y1-Y2
	MOV LINE_Y1_Y2,AX
	MOV VAR1,0   ;初始化辅助变量VAR1,VAR2
	MOV VAR2,0 
	
	MOV AX,X1
	MOV BX,X2
	MOV CX,Y1
	MOV DX,Y2
	CMP AX,BX          ;判断水平方向
	;JA LEFT            ;AX>BX LEFT
	JBE RIGHT
	JMP LEFT
RIGHT:
	CMP CX,DX          ;判断垂直方向
	JA RIGHT_UP        ;
RIGHT_DOWN:
	MOV AH,0CH
	MOV BH,0
	MOV CX,X1
	MOV DX,Y1
RIGHT_DOWN_1:
	PUSH AX
	MOV AX,VAR1
	ADD AX,LINE_Y2_Y1
	MOV VAR1,AX
	CMP AX,LINE_X2_X1
	POP AX
	JBE RIGHT_DOWN_2
	PUSH AX
	MOV AX,VAR1
	SUB AX,LINE_X2_X1
	MOV VAR1,AX
	POP AX
	INC DX
RIGHT_DOWN_2:
	PUSH AX
	MOV AX,VAR2
	ADD AX,LINE_X2_X1
	MOV VAR2,AX
	CMP AX,LINE_Y2_Y1
	POP AX
	JBE RIGHT_DOWN_3
	PUSH AX
	MOV AX,VAR2
	SUB AX,LINE_Y2_Y1
	MOV VAR2,AX
	POP AX
	INC CX
RIGHT_DOWN_3:
	MOV AL,[SI]
	INC SI
	INT 10H
	CMP CX,X2
	JB RIGHT_DOWN_1
	JMP FINISH

RIGHT_UP:
	MOV AH,0CH
	MOV BH,0
	MOV CX,X1
	MOV DX,Y1
RIGHT_UP_1:
	PUSH AX
	MOV AX,VAR1
	ADD AX,LINE_Y1_Y2
	MOV VAR1,AX
	CMP AX,LINE_X2_X1
	POP AX
	JBE RIGHT_UP_2
	PUSH AX
	MOV AX,VAR1
	SUB AX,LINE_X2_X1
	MOV VAR1,AX
	POP AX
	DEC DX
RIGHT_UP_2:
	PUSH AX
	MOV AX,VAR2
	ADD AX,LINE_X2_X1
	MOV VAR2,AX
	CMP AX,LINE_Y1_Y2
	POP AX
	JBE RIGHT_UP_3
	PUSH AX
	MOV AX,VAR2
	SUB AX,LINE_Y1_Y2
	MOV VAR2,AX
	POP AX
	INC CX
RIGHT_UP_3:
	MOV AL,[SI]
	INC SI
	INT 10H
	CMP CX,X2
	JB RIGHT_UP_1
	JMP FINISH

LEFT:
	MOV CX,Y1
	MOV DX,Y2
	CMP CX,DX
	JA LEFT_UP
LEFT_DOWN:
	MOV AH,0CH
	MOV BH,0
	MOV CX,X1
	MOV DX,Y1
LEFT_DOWN_1:
	PUSH AX
	MOV AX,VAR1
	ADD AX,LINE_Y2_Y1
	MOV VAR1,AX
	CMP AX,LINE_X1_X2
	POP AX
	JBE LEFT_DOWN_2
	PUSH AX
	MOV AX,VAR1
	SUB AX,LINE_X1_X2
	MOV VAR1,AX
	POP AX
	INC DX
LEFT_DOWN_2:
	PUSH AX
	MOV AX,VAR2
	ADD AX,LINE_X1_X2
	MOV VAR2,AX
	CMP AX,LINE_Y2_Y1
	POP AX
	JBE LEFT_DOWN_3
	PUSH AX
	MOV AX,VAR2
	SUB AX,LINE_Y2_Y1
	MOV VAR2,AX
	POP AX
	DEC CX
LEFT_DOWN_3:
	MOV AL,[SI]
	INC SI
	INT 10H
	CMP CX,X2
	JA LEFT_DOWN_1
	JMP FINISH

LEFT_UP:
	MOV AH,0CH
	MOV BH,0
	MOV CX,X1
	MOV DX,Y1
LEFT_UP_1:
	PUSH AX
	MOV AX,VAR1
	ADD AX,LINE_Y1_Y2
	MOV VAR1,AX
	CMP AX,LINE_X1_X2
	POP AX
	JBE LEFT_UP_2
	PUSH AX
	MOV AX,VAR1
	SUB AX,LINE_X1_X2
	MOV VAR1,AX
	POP AX
	DEC DX
LEFT_UP_2:
	PUSH AX
	MOV AX,VAR2
	ADD AX,LINE_X1_X2
	MOV VAR2,AX
	CMP AX,LINE_Y1_Y2
	POP AX
	JBE LEFT_UP_3
	PUSH AX
	MOV AX,VAR2
	SUB AX,LINE_Y1_Y2
	MOV VAR2,AX
	POP AX
	DEC CX
LEFT_UP_3:
	MOV AL,[SI]
	INC SI
	INT 10H
	CMP CX,X2
	JA LEFT_UP_1
FINISH:
	POP SI
	__POP_REGS
ENDM
