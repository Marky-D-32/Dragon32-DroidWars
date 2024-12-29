        
	ORG $7530
        JMP   ASKSPD		;Ask User for speed of game			
	
        ;***********************
	;Setup for start of game
        ;***********************
SETUP   LDA   #$32   		;Reset Game parameters
        STA   $0137		;Right ship position	
        STA   $0138             ;Left ship position
        CLR   $0139             ;Number of Right Droids destroyed
        CLR   $013A             ;Number of left Droids destroyed
        LDX   #$0000
        STX   $013B             ;Right right bolt position
        STX   $013D             ;Left right bolt position
        CLR   $013F             ;Right right bolt direction
        CLR   $0140             ;Left right bolt direction
        CLR   $0141             ;Middle scroll bar count control
        LDX   #$0112            ;System timer 		
        STX   $0142             ;Middle scroll bar block height control
        
        LDA   #$80		;Clear Screen
        LDX   #$0600
CLSLP   STA   ,X+
        CMPX  #$1E00
        BCS   CLSLP
        LDA   #$0D		;Goto to SemiGraphics 24
        STA   $FF22
        STA   $FFC0
        STA   $FFC3
        STA   $FFC5
        STA   $FFC7
        
        ;***********
	;Draw Droids
        ;***********
        LDB   #$08		;8 Droids to draw		
        LDX   #$0760        	;Position on screen
DA2     LDY   #DROID		;Location of DROID graphic data
DA1     LDA   ,Y+		;Get graphic data
        STA   ,X		;Draw 1st half on left of screen
        STA   30,X		;Draw another on right of screen
        LDA   ,Y+		;Get 2nd half
        STA   1,X		;Draw 2nd half on left of screen
        STA   31,X		;Draw 2nd Half on right of screen
        LEAX  32,X		;go down to next row
        CMPY  #SHIPR		;finished drawing? **TODO - change to label 
        BCS   DA1		;No 
        LEAX  $0200,X		;Skip down to next DROID position
        DECB			;decrease DROID drawn count
        BNE   DA2		;draw next DROID

        ;*********************
	;Draw defense barriers
        ;*********************
        LDX   #$0600				
DEFLP   LDA   #$EF              ;Pink lines
        STA   2,X               ;Draw 2 lines, 3 across
        STA   3,X
        STA   4,X
        STA   28,X
        STA   29,X
        STA   27,X
        LDA   #$9F              ;Yellow lines
        STA   34,X              ;Draw 2 lines, 3 across
        STA   35,X
        STA   36,X
        STA   60,X
        STA   61,X
        STA   59,X
        LEAX  64,X              ;Increase line count
        CMPX  #$1E00            ;Finished?
        BCS   DEFLP             ;No
        
        ;**********************
	;Main game playing loop
        ;**********************
MAINLP	JSR   MSB	        ;Scroll middle bar	
        JSR   MSB		;Twice
        JSR   RSCTRL		;Check right joystick and draw ship			
        JSR   LSCTRL     	;Check left joystick and draw ship 	
        
        JSR   RSFI              ;Check right fire button and draw bolt  

	LDX   $0144		;Slow things up
DELAY   LEAX  -1,X
        BNE   DELAY

        LDA   $0139             ;Get right droid destroyed count			
        CMPA  #$08              ;All destroyed?
        BEQ   WINLP1             ;Yes 
 
        JSR   LSFI              ;Check left fire button and draw bolt
        
        LDA   $013A             ;Get left droid destroyed count
        CMPA  #$08              ;All destroyed?
        BEQ   WINLP3             ;Yes
        
        BRA   MAINLP            ;re-run main loop
 
        ;****************
        ;Some one has won
        ;****************
WINLP1  LDA   $0137             ;Get right ship position
        LDX   #$0616
        BRA   WINLP2

WINLP3  LDA   $0138             ;Get left ship position
        LDX   #$0608

WINLP2  LDB   #$20              ;Calculate position of ship
        MUL
        LEAX  D,X
        LDB   #$0F              ;Number of times to flash
WINLP4  LDA   #$9F              ;Hilight winning ship
        STA   ,X
        STA   1,X
        STA   $0100,X
        STA   $0101,X
        BSR   WINSND            ;Play winning sound
        LDA   #$80              ;Un-hilight winning ship
        STA   ,X
        STA   1,X
        STA   $0100,X
        STA   $0101,X
        BSR   WINSND            ;Play winning sound
        DECB
        BNE   WINLP4             ;Repeat ship hilighting
        
        BRA   AGASK             ;Ask to play another game
        
        ;******************
        ;Play winning sound
        ;******************
WINSND  PSHS  B
        LDA   #$3F   
        STA   $FF23
        CLR   $FF20
        LDA   #$FF
        COM   $FF20
        TFR   A,B
        DECB
        BNE   $7641
        DECA
        BNE   $763C
        LDA   #$37   
        STA   $FF23
        PULS  B,PC
	
        ;*************************************************************
	;Ask user another game? (note: still in semi graphics 24 mode)
        **************************************************************
AGASK   LDX   #$10E0		;Position to write text		
        LDY   #AGTXT		;Point to text to be displayed
AGLP1   LDA   ,Y+		;Get text character
        ANDA  #$BF		;Invert text colour
        STA   ,X+		;Write to screen
        STA   31,X
        STA   63,X
        STA   95,X
        STA   127,X
        STA   $009F,X
        STA   $00BF,X
        STA   $00DF,X
        STA   -33,X
        CMPY  #ASKSPD		;Finished writing text?
        BCS   AGLP1		;No
AGLP2   JSR   $BBE5		;Scan Keyboard			
        CMPA  #$59   		;Yes
        LBEQ  SETUP		;Start another game
        CMPA  #$4E   		;No
        BNE   AGLP2		;Not Y or N - try again
        RTS			;Exit Game
AGTXT	FCB   /     ANOTHER GAME (Y OR N) ?    /
	
        ;**************************
	;Ask user for speed of game
        ;**************************
ASKSPD  JSR   $BA77		;Clear screen and HOME cursor	
        LDX   #$0500		;position to write text
        STX   <$88
        LDX   #SPDTXT		;point to text to be displayed		
        JSR   $90E5		;Output text string
AS1     JSR   $BBE5		;Scan keyboard - result in A register
        CMPA  #$30   		;Zero
        BLS   AS1		;Less than zero - repeat		
        CMPA  #$3A    		;":" i.e. greater than "9"
        BCC   AS1		;Greater than 9 - repeat         
        PSHS  A			;Generate speed	
        LDB   #$3A   		
        SUBB  ,S+           
        LDA   #$FA          
        MUL                 
        STD   $0144		;Store result in $0144
        JMP   SETUP		;Return
SPDTXT  FCB   /  ENTER SPEED LEVEL (1 TO 9) ?/
	FCB   $00
        
        ;****************************
	;Middle Scrolling bar routine
        ;****************************
MSB	LDA   $0136		;Height of current block		
        BEQ   MSB1 		;Zero
        LDA   $0141
        BEQ   MSB2
        BSR   SMB		;Scroll bar down     
        LDA   #$95	
        STA   $060F     
        BRA   MSB3     
MSB2    BSR   SMB	
        LDA   #$80	
        STA   $060F     
        BRA   MSB3		
MSB1    JSR   NBHEI		;Get next block height??
        TST   $0141
        BNE   MSB4
        LDB   #$02
        MUL
        TFR   B,A
MSB4    STA   $0136
        COM   $0141
        BRA   MSB
MSB3    DEC   $0136
        RTS
        
        ;**********************
	;Scroll middle bar down
        ;**********************
SMB	LDX   #$1DEF		;Start at bottom of bar
        LDB   #$BF		;Number of rows to scroll
SMBLP1  LDA   -32,X		;Get line above
        STA   ,X		;draw it
        LEAX  -32,X		;Go up one line
        DECB			;reached top of Screen
        BNE   SMBLP1		;No - repeat
        RTS			;Return
	
        ;************************************************
	;Calculate height of next block in middle bar (?)
        ;************************************************
NBHEI   LDD   $0142			
        MUL                 
        LDX   $0142			
        LEAX  5,X			
        STX   $0142			
NBLP2   CMPB  #$07			
        BLS   NBLP1			
        SUBB  #$07			
        BRA   NBLP2			
NBLP1   ADDB  #$03			
        TFR   B,A			
        RTS
	
        ;******************
	;Right Ship control
        ;******************
RSCTRL  JSR   $BD52             ;Read ALL Joysticks			
        LDA   $015B		;Right Joystick - Y value	
        CMPA  #$35              ;Check if joystick in DOWN position
        BCC   RSDOWN            ;Yes - Move ship down
        CMPA  #$0A              ;Check of joystick in UP position
        BCC   RSDRW             ;No - Redraw ship
        TST   $0137             ;Have we moved upto top border
        BEQ   RSDRW             ;No - Redraw ship
        DEC   $0137             ;Decrease position of right ship
        BRA   RSDRW             ;Redraw ship     
RSDOWN  LDA   $0137             ;Get current ROW of right hand ship
        CMPA  #$B6              ;Bottom border
        BCC   RSDRW             ;Have we gone past bottom border?
        INC   $0137             ;No - Increase right ship position
RSDRW   LDX   #$0616            ;Draw Right ship on screen
        LDB   #$20              ;Calculate position
        LDA   $0137
        MUL
        LEAX  D,X               ;Update ship position
        LDY   #SHIPR            ;Point to Ship graphic
        LDB   #$09              ;Draw ship
RSDRW1  LDA   ,Y+
        STA   ,X
        LDA   ,Y+
        STA   1,X
        LEAX  32,X
        DECB
        BNE   RSDRW1
        RTS                     ;Return
	
        ;*****************
	;Left Ship control
        ;*****************
LSCTRL  JSR   $BD52             ;Read ALL Joysticks
        LDA   $015D		;Left Joystick - Y value	
        CMPA  #$35              ;Check if joystick in DOWN position
        BCC   LSDOWN            ;Yes - move ship down
        CMPA  #$0A              ;check if joystick in UP Position
        BCC   LSDRW             ;No - redraw ship
        TST   $0138             ;Have we move up to top border
        BEQ   LSDRW             ;No - redraw ship
        DEC   $0138             ;Decrease position of left ship
        BRA   LSDRW             ;Redraw ship
LSDOWN  LDA   $0138             ;get current row of left ship
        CMPA  #$B6              ;Bottom border
        BCC   LSDRW             ;Have we gone past bottom border?
        INC   $0138             ;No - increase left ship position
LSDRW   LDX   #$0608            ;Draw left ship on screen    
        LDB   #$20              ;Calculate psotion
        LDA   $0138
        MUL
        LEAX  D,X               ;Update ship position
        LDY   #SHIPL            ;Point to ship graphic
        LDB   #$09              ;Draw ship
LSDRW1  LDA   ,Y+
        STA   ,X
        LDA   ,Y+
        STA   1,X
        LEAX  32,X
        DECB
        BNE   LSDRW1
        RTS                     ;Return
	
        ;*******************************
        ; Right hand fire button pressed
        ;*******************************
RSFI    TST   $013F		;Is RH laser already been fired?
        BNE   RSFI1             ;Yes
        LDA   $FF00             ;Check RH fire button pressed			
        BITA  #$01
        BEQ   RSFI2             ;Yes
        RTS                     ;No - return to main control loop
	
RSFI2   LDA   #$FF		;Set direction of new right bolt (right to left)	
        STA   $013F             ;And store
        LDA   $0137             ;Calculate start position of right bolt
        LDB   #$20
        MUL
        LDX   #$0696            ;Start position of right bolt
        LEAX  D,X               ;Offset number of rows
        STX   $013B             ;Store position of right bolt

RSFI1   LDX   $013B             ;Get right bolt position
        LDA   #$80               
        STA   ,X                ;Erase right bolt from screen

        LDA   $013F             ;Get direction of right bolt             
        LEAX  A,X               ;Update position of right bolt
        TFR   X,D               ;Work out position
        ANDB  #$1F              
        CMPB  #$0F              ;CHECK: right bolt reached middle of screen ???
        BEQ   RBCHK             ;Go and check if hit middle barrier
        TSTB                    ;CHECK: right bolt reached left hand side of screen ???
        BEQ   RBRSET            ;Yes - Reset right bolt
        CMPB  #$1F              ;CHECK: right bolt reached right hand side of screen ???                            
        BEQ   RBRSET            ;Yes - Reset right bolt
        
        LDA   ,X                ;get graphic at bolt position
        CMPA  #$80              ;CHECK:  right bolt hit nothing?
        BEQ   RBDRAW            ;Yes - draw bolt on screen
        CMPA  #$EF              ;CHECK: right bolt hit defense barrier colour 1?
        BNE   RBHB1             ;No - next check
RBHB2   LDA   #$80              ;Bolt hit barrier
        STA   ,X                ;Make hole in barrier
        STA   32,X
        STA   -32,X
        JSR   BHITS             ;Make barrier hit sound 
        BRA   RBRSET            ;Reset right bolt
RBHB1   CMPA  #$9F              ;CHECK: right bolt hit defense barrier colour 2?              
        BEQ   RBHB2             ;Yes

        CMPA  #$D5              ;CHECK: right bolt hit a droid?
        BCS   RBDRAW            ;No - Draw bolt
        CMPA  #$E0              ;?????
        BCC   RBDRAW
        LDA   $013F             ;right bolt hit droid  ??
        INCA
        BEQ   RBHB3
        LEAX  1,X
RBHB3   LDA   #$80              ;Erase Droid that has been hit
        LEAX  $FF20,X
        LDB   #$0E
RBHB4   STA   ,X
        STA   -1,X
        LEAX  32,X
        DECB
        BNE   RBHB4
        LDA   #$3F              ;Make sound 
        STA   $FF23
        LDB   #$C8
        CLR   $FF20
RBHB5   COM   $FF20
        TFR   B,A
RBHB6   DECA
        BNE   RBHB6
        DECB
        BNE   RBHB5
        LDA   #$37   
        STA   $FF23

        LDA   $013F             ;Get direction of right bolt
        CMPA  #$FF              ;If right bolt going left
        BEQ   RBHB7
        INC   $013A             ;Increase Left Droid destroyed count
        BRA   RBRSET

RBHB7   INC   $0139             ;Increase Right Droid destroyed count
        BRA   RBRSET

RBDRAW  LDA   #$9A              ;Bolt Graphic
        STA   ,X                ;Draw on screen
        STX   $013B             ;Update position
        RTS

RBRSET  CLR   $013F			
        RTS

        ;*******************************
        ;Right Bolt CHecK if hit barrier
        ;*******************************
RBCHK   LDA   ,X                ;Load graphic at laser position			 
        CMPA  #$80              ;Have we hit nothing
        BEQ   RBCHKE            ;Yes - exit
        LDA   #$01              ;Hit barrier - change right bolt direction
        STA   $013F             ;Store bolt direction
        LDA   #$3F              ;Make Beep sound
        STA   $FF23
        LDB   #$0A
        CLR   $FF20
RBBP1   COM   $FF20
        LDA   #$64   
RBBP2   DECA
        BNE   RBBP2
        DECB
        BNE   RBBP1
        LDA   #$37   
        STA   $FF23
RBCHKE  STX   $013B             ;Store bolt position
        RTS                     ;Return

        ;*****************************
        ;Left hand fire button pressed
        ;*****************************
LSFI    TST   $0140             ;Has LH laser already been fired?			 
        BNE   LSFI1             ;Yes
        LDA   $FF00             ;Check LH fire button pressed
        BITA  #$02
        BEQ   LSFI2             ;Yes
        RTS                     ;No - return to main ship control loop

LSFI2   LDA   #$01              ;Set direction of left bolt (left to right)			
        STA   $0140             ;and store
        LDA   $0138             ;Claculate start psotion of left bolt
        LDB   #$20
        MUL
        LDX   #$0689            ;Set top most row psotion
        LEAX  D,X               ;Offset number of rows down
        STX   $013D             ;store position of lleft bolt
        
LSFI1   LDX   $013D             ;Get left bolt position
        LDA   #$80
        STA   ,X                ;Erase left bolt from screen
        LDA   $0140             ;Get direction of left bolt
        LEAX  A,X               ;Set new position of left bolt
        TFR   X,D               
        ANDB  #$1F              
        CMPB  #$0F              ;CHECK: left bolt reached middle of screen?
        BEQ   LBCHK             ;Go and check if hit middle barrier
        TSTB                    ;CHECK: left bolt reach left hand side of screen?
        BEQ   LBRSET            ;Yes - reset left bolt
        CMPB  #$1F              ;CHECK: left bolt reached right hand side of screen ?
        BEQ   LBRSET            ;Yes - left reset left bolt
        
        LDA   ,X                ;Get graphic at bolt position       
        CMPA  #$80              ;CHECK - left bolt hit nothing?
        BEQ   LBDRAW            ;Yes - draw bolt on screen
        CMPA  #$EF              ;CHECK: left bolt hit defense barrier colour 2?
        BNE   LBHB1             ;No - next check
LBHB2   LDA   #$80              ;Left bolt hit defense barrier     
        STA   ,X                ;Make hole in defense barrier
        STA   32,X              
        STA   -32,X
        JSR   BHITS             ;Make barrier hit shound
        BRA   LBRSET            ;Reset left bolt
LBHB1   CMPA  #$9F              ;CHECK: left bolt hit defense barrier colour 2?
        BEQ   LBHB2             ;Yes
        
        CMPA  #$D5              ;CHECK: left bolt hit a droid?
        BCS   LBDRAW            ;No - draw bolt
        CMPA  #$E0
        BCC   LBDRAW            ;No - draw bolt
        LDA   $0140             ;left bolt hit droid
        INCA
        BNE   LBHB3
        LEAX  -1,X
LBHB3   LDA   #$80              ;Erase droid that has been hit
        LEAX  $FF20,X
        LDB   #$0E
LBHB4   STA   ,X
        STA   1,X
        LEAX  32,X
        DECB
        BNE   LBHB4
        LDA   #$3F              ;Make sound  
        STA   $FF23
        LDB   #$C8
        CLR   $FF20
LBHB5   COM   $FF20
        TFR   B,A
LBHB6   DECA
        BNE   LBHB6
        DECB
        BNE   LBHB5
        LDA   #$37   
        STA   $FF23
        
        LDA   $0140             ;Get direction of left bolt
        CMPA  #$FF              ;Is going left ?
        BEQ   LBHB7
        INC   $013A             ;Increase left droid destroyed count
        BRA   LBRSET

LBHB7   INC   $0139             ;Increase right droid destroyed count
        BRA   LBRSET

LBDRAW  LDA   #$9A              ;Bolt graphic
        STA   ,X                ;Draw on screen
        STX   $013D             ;Update position
        RTS

LBRSET  CLR   $0140             ;Reset Left bolt indicator			
        RTS

        ;******************************
        ;Left bolt check if hit barrier
        ;******************************
LBCHK   LDA   ,X	        ;Load graphic at left bolt position
        CMPA  #$80              ;Have we hit nothing?
        BEQ   LBCHKE            ;Yes - Exit
        LDA   #$FF              ;Hit barrier - change left bolt direction
        STA   $0140             ;Store left bolt direction
        LDA   #$3F              ;Make beep sound
        STA   $FF23
        LDB   #$0A
        CLR   $FF20
LBBP1   COM   $FF20
        LDA   #$64                           
LBBP2   DECA
        BNE   LBBP2
        DECB
        BNE   LBBP1
        LDA   #$37   
        STA   $FF23
LBCHKE  STX   $013D             ;Store bolt position
        RTS                     ;Return

        ;**********************************
        ;Make sound of bolt hitting barrier
        ;**********************************
BHITS   PSHS  A,X
        LDA   #$3F   
        STA   $FF23
        LDX   #$84D0
        LDA   ,X+
        ORA   #$80
        STA   $FF20
        CMPX  #$8980
        BCS   $7992
        LDA   #$37   
        STA   $FF23
        PULS  A,X,PC
	
        ;*************
        ;Droid Graphic
        ;*************
DROID	FCB   $D5,$DA 		
        FCB   $DF,$DF	
	FCB   $DF,$DF       
	FCB   $DF,$DF       
	FCB   $DF,$DF       
	FCB   $D5,$DA       
	FCB   $DA,$D5
	
        ;******************
        ;Right ship graphic
        ;******************
SHIPR	FCB   $80,$80 	
	FCB   $80,$C5       
	FCB   $80,$CF
	FCB   $C5,$CF
	FCB   $CF,$CF
	FCB   $C5,$CF 
	FCB   $80,$CF 
	FCB   $80,$C5 
	FCB   $80,$80 
	
        ;*****************
        ;Left ship graphic
        ;*****************
SHIPL	FCB   $80,$80	
	FCB   $CA,$80 
	FCB   $CF,$80
	FCB   $CF,$CA
	FCB   $CF,$CF
	FCB   $CF,$CA
	FCB   $CF,$80
	FCB   $CA,$80
	FCB   $80,$80
   