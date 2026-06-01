; Core4 Demo by koppanyh
; Created Nov 2024
; Designed to interface with the SAO Adapter for Voja4:
; https://hackaday.io/project/198394-sao-adapter-for-voja4-badge



;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                        ;;
;;  Start of I2C Section  ;;
;;                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; IO0 is SCL
; IO1 is SDA

; Example usage:
;GOSUB i2c_start      ; Trigger START condition
;MOV R4, 0x3          ; Send 0x3C address in write mode
;MOV R3, 0xC
;MOV R0, 0
;GOSUB i2c_send_addr
;MOV R3, 0b1000       ; Send 'H' character
;MOV R4, 0b0100
;GOSUB i2c_send_byte
;MOV R3, 0b0101       ; Send 'e' character
;MOV R4, 0b0110
;GOSUB i2c_send_byte
;MOV R3, 0b1100       ; Send 'l' character
;MOV R4, 0b0110
;GOSUB i2c_send_byte
;MOV R3, 0b1100       ; Send 'l' character
;MOV R4, 0b0110
;GOSUB i2c_send_byte
;MOV R3, 0b1111       ; Send 'o' character
;MOV R4, 0b0110
;GOSUB i2c_send_byte
;MOV R3, 0b0001       ; Send '!' character
;MOV R4, 0b0010
;GOSUB i2c_send_byte
;GOSUB i2c_stop       ; Trigger STOP condition 

; Init
; Set up the IO port and select which registers to control it with, then jump
; to main routine.
; Params: none
; Returns: none
; Modifies registers: R0, PCH, PCM, PCL
init:
MOV R0, 0x0  ; use IO on zero page registers and enable IO port
MOV [0xF3], R0
GOTO main
; signature "koppanyh" (view in hex editor)
MOV PC, [0x6:0xB]
MOV PC, [0x6:0xF]
MOV PC, [0x7:0x0]
MOV PC, [0x7:0x0]
MOV PC, [0x6:0x1]
MOV PC, [0x6:0xE]
MOV PC, [0x7:0x9]
MOV PC, [0x6:0x8]

; I2C Stop
; Stop the I2C transmission. Also init the I2C bus the first time.
; Params: none
; Returns: none
; Modifies registers: R0, Out
i2c_stop:
MOV R0, Out
AND R0, 0b1110  ; scl = 0
MOV Out, R0
AND R0, 0b1101  ; sda = 0
MOV Out, R0
OR R0, 0b0001  ; scl = 1
MOV Out, R0
OR R0, 0b0010  ; sda = 1
MOV Out, R0
RET R0, 0

; I2C Start
; Start the I2C transmission.
; Params: none
; Returns: none
; Modifies registers: R0, Out
i2c_start:
MOV R0, Out
OR R0, 0b0001  ; scl = 1
MOV Out, R0
OR R0, 0b0010  ; sda = 1
MOV Out, R0
AND R0, 0b1101  ; sda = 0
MOV Out, R0
AND R0, 0b1110  ; scl = 0
MOV Out, R0
RET R0, 0

; I2C Send Nybble
; Send a single nybble on the I2C bus.
; Params:
;   R1: The nybble to send on the bus.
; Returns: none
; Modifies registers: R0, R1, R2, Out
i2c_send_nybble:
MOV R2, 4  ; set counter to 4
MOV R0, Out  ; copy Out's current state
; jump target: #0
AND R0, 0b1101  ; set virtual SDA to 0            <-+
BIT R1, 3  ; check nybble's high bit                |
SKIP Z, 1  ; set virtual SDA to 1 if it's not 0     |
OR R0, 0b0010  ;                                    |
MOV Out, R0  ; sda = virtual SDA                    |
ADD R1, R1  ; shift nybble left                     |
OR R0, 0b0001  ; scl = 1 (pulse the clock)          |
MOV Out, R0  ;                                      |
AND R0, 0b1110  ; scl = 0                           |
MOV Out, R0  ;                                      |
DSZ R2  ; dec counter and ret if 0                  |
JR -12  ; jump to #0, MAKE SURE THIS IS CORRECT!!! -+
RET R0, 0

; I2C Send Byte
; Send a single byte on the I2C bus.
; Params:
;   R3: The byte's low nybble to send on the bus.
;   R4: The byte's high nybble to send on the bus.
; Returns:
;   R0: The ack status on the bus (true is error).
; Modifies registers: R0, R1, R2, Out
i2c_send_byte:
MOV R1, R4  ; send high nybble
GOSUB i2c_send_nybble
MOV R1, R3  ; send low nybble
GOSUB i2c_send_nybble
MOV R0, Out
OR R0, 0b0010  ; sda = 1 (so the target can ack by pulling down)
MOV Out, R0
OR R0, 0b0001  ; scl = 1
MOV Out, R0
; TODO Implement clock stretching here
MOV R1, In  ; R1 = raw input containing ack status from sda
MOV R0, Out  ; scl = 0
AND R0, 0b1110
MOV Out, R0
BIT R1, 1  ; return (R1 & 0b0010) >> 1
SKIP Z, 1
RET R0, 1
RET R0, 0

; I2C Send Addr
; Send the address byte on the I2C bus.
; Params:
;   R0: Whether to read (1) or write (0).
;   R3: The low nybble of the address.
;   R4: The high nybble of the address.
; Returns:
;   R0: The ack status on the bus (true is error).
; Modifies registers: R0, R1, R2, R3, R4, Out
i2c_send_addr:
ADD R3, R3  ; addr <<= 1
ADC R4, R4
ADD R3, R0  ; addr |= readwritebit
GOSUB i2c_send_byte
CP R0, 0
SKIP Z, 1
RET R0, 1
RET R0, 0

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      ;;
;;  End of I2C Section  ;;
;;                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;



; Main
; Do the thing.
; Params: none
; Returns: none
; Registers: ?
main:
GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0xe
MOV R4, 0xa
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x2
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x4
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x1
MOV R4, 0xa
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0xa
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x3
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0xc
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x3
MOV R4, 0xd
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0xa
MOV R4, 0xd
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x2
MOV R4, 0x1
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x5
MOV R4, 0xd
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x9
MOV R4, 0xd
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x1
MOV R4, 0xf
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0xb
MOV R4, 0xd
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x3
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x1
MOV R4, 0x8
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0xf
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0xa
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x6
MOV R4, 0xa
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0xd
MOV R4, 0x8
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x1
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0xa
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x1
MOV R4, 0x2
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x2
MOV R4, 0x2
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x7
MOV R4, 0x0
GOSUB i2c_send_byte
GOSUB i2c_stop

GOSUB i2c_start
MOV R3, 0xc
MOV R4, 0x3
MOV R0, 0
GOSUB i2c_send_addr
MOV R3, 0x0
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x3
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x5
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x5
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x5
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x5
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x1
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x1
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x3
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x3
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x8
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0xe
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x6
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x3
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x1
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x3
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x3
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x3
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x1
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x8
MOV R4, 0x3
GOSUB i2c_send_byte
MOV R3, 0xc
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x4
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x7
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0xf
MOV R4, 0x4
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
MOV R3, 0x0
MOV R4, 0x0
GOSUB i2c_send_byte
GOSUB i2c_stop
RET R0, 0  ; throw error condition
