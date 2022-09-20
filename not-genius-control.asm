.device ATmega328p

; Reset
.org 0x00
rjmp MAIN

; counter overflow
.org 0x001A
rjmp read_from_user

; Configura variaveis da memoria
.dseg
     .org SRAM_START

     IGNORE_USER: .byte 1  ; flag para ignorar entradas do usuário enquano o programa pensa

     N_RANDOM_SIG: .byte 1  ; quantidade de sinais já encaminhados
     not_genius_array: .byte 10  ; tamanho da array que conterá os sinais (o jogo acaba quando L > 100)

     N_SIG_USER: .byte 1  ; número de entradas que o usuário entrou
     user_sig_array: .byte 10  ; tamanho da array que conterá os sinais do usuário

     last_led_turned_on: .byte 1  ; variavel pra armazenar a mascara do último pino ligado
.cseg

; Initialize stack
.macro initialize_stack
       ldi R16, HIGH(RAMEND)
       out SPH, R16
       ldi R16, LOW(RAMEND)
       out SPL, R16
.endmacro

; Subrotinas para configuração
config_leds:

            ; configura as portas em que os LEDs vão estar conectados

            ldi r16, (1 << PC3) | (1 << PC2) | (1 << PC1) | ( 1 << PC0)
            clr R19  ; seta o estado inicial como desligado

            out DDRC, R16
            out PORTC, R19

            ret


config_buttons:

               ; Configura a porta D para receber os quatro botões

               ldi R16, (1 << PD0) | (1 << PD1) | (1 << PD2) | (1 << PD3)
               out DDRD, R16
               ret

config_ng_pointer:

             ldi XL, LOW(not_genius_array)
             ldi XH, HIGH(not_genius_array)

             ret

config_timer:

          ; Clear counter
          clr R16
          sts TCNT1L, R16
          sts TCNT1H, R16

          ; Configure Clock Selection
          ldi R16, (1 << CS12) | (0 << CS11) | (1 << CS10)
          sts TCCR1B, R16

          ; Configure CTC
          ldi R16, (1 << COM1A1) | (0 << COM1A0) | (1 << WGM12)
          sts TCCR1A, R16

          ; configure OCR1A
          ; utilizar isso pra mostrar para o usuario quando errou talvez
          ldi R16, 0x7B ;
          ldi R17, 0x06
          sts OCR1AL, R16
          sts OCR1AH, R16

          ; configure interruption
          ldi r16, (1 << TOIE1)
          sts TIMSK1, R16

          ret

config_user_pointer:

          ldi YL, LOW(user_sig_array)
          ldi YH, HIGH(user_sig_array)

          ret

; Subrotinas para controle dos LEDs
check_ng_limit:

          ; Subrotina para verificação do comprimento da entrada

          lds R16, N_RANDOM_SIG ; Carrega o tamanho atual em R16
          cpi R16, 0x10 ; Tamanho máximo = 10
          breq jmp_reset ; Se N_RANDOM_SIG != 10 continua
           
          call get_random

          ret

          jmp_reset:
               call reset  ; se igual reseta os valores

get_random:

          ; Subrotina para ler da parte do Leo e adicionar na
          ; array

          clr R16
          clr R17


          ; Lê o valor e adiciona na not_genius_array
          ; Aqui trocar para a leitura da parte do codigo do leo

          inc R25

          st X+, R25 

          ; Lê o valor atual da quantidade de sinais e incrementa

          lds R17, N_RANDOM_SIG
          inc R17
          sts N_RANDOM_SIG, R17


          ret

turn_on_led:

          ; Função para ligar o LED

          lds R23, last_led_turned_on
          out PORTC, R23

          ;call keep_led_on  ; delay pra manter o LED ligado

          clr R23
          out PORTC, R23 

          ret

loop_in_signals:
          ; i == size ? break : keep
          cp R18, R19
          breq get_out

          ; carrega o valor da array do jogo, coloca em uma variavel de memoria
          ld R20, X+ ; array[n]

          sts last_led_turned_on, R20  

          ; mantem o led acesso por um tempo
          call turn_on_led

          ; continua no loop até finalizar
          inc R18
          rjmp loop_in_signals

          ret


          get_out:
               ret

send_to_user:
          ldi R18, 0x00
          lds R19, N_RANDOM_SIG

          call config_ng_pointer

          call loop_in_signals

          ret

read_from_user:

     ; Função de armazenamento dos valores do usuário

     ; define as mascaras dos pinos dos botoes:
     ; em ordem 0, 1, 2 e 3 
          ; em ordem 0, 1, 2 e 3 
     ; em ordem 0, 1, 2 e 3 
          ; em ordem 0, 1, 2 e 3 
     ; em ordem 0, 1, 2 e 3 
     ldi R16, 0b00000001
     ldi R17, 0b00000010
     ldi R18, 0b00000100
     ldi R19, 0b00001000

     in R20, PIND  ; faz a leitura da porta D

     ; armazena a intersecção
     
     ; acho que não precisaria isso, mas vou manter pra gnt ter maior controle do que
     ; tá sendo encaminhado

     and R16, R20
     and R17, R20
     and R18, R20
     and R19, R20

     ; combina valores no R23

     clr R23

     or R23, R16
     or R23, R17
     or R23, R18
     or R23, R19

     st X+, R23  ; adiciona no fim da array not_genius_array



check_sequence:

               ; Função que verifica a entrada do usuário

               call config_user_pointer

               cp R18, R19  ; i == N_RANDOM_SIG ? break : keep
               breq jmp_pls

               ld R20, X  ; sinal do not genius
               ld R21, Y  ; sinal do usuario

               cp R20, R21  ; compara os valores
               brne reset  ;

               call check_sequence

               ret

               jmp_pls:
                        ret

keep_led_on:
     ; Delay utilizado para mostrar o LED ligado para o usuário

	; save R22, R23 and R24 to Stack
	push R22
	push R23
	push R24

	; max counter
	ldi R21, 0xA0

	; initialize delay counters
	LDI R22, 0x00
	LDI R23, 0x00
	LDI R24, 0x00

	; initializes first delay
	first_delay:
		inc R22
		; initializes second delay
		second_delay:
			inc R23
			; initializes third delay
			third_delay:
				inc R24
				cp R24, R21
				brne third_delay ; if third delay counter R24 is different from max counter R21 repeat
				ldi R24, 0x00 ; else reset third delay counter R24

			cp R23, R21
			brne second_delay ; if second delay counter R23 is different from max counter R21 repeat
			ldi R23, 0x00 ; else reset second delay counter R23

		cp R22, R21
		brne first_delay ; if first delay counter R22 is different from max counter R21 repeat
		ldi R22, 0x00 ; else reset second delay counter R22

	; retrieve R23 and R24 to Stack
	pop R24
	pop R23
	pop R22

	ret

delay:

     ; delay to user can see things 

reset:
     ; reset memory values

     ; reset number of random signals sent
     clr R16
     sts N_RANDOM_SIG, R16

     ; remove elements of array

; time_to_think: 

;      ; talvez eu precise dessa flag pra deixar o codigo ignorando as entradas do usuario
;      ; enquanto o jogo pensa um pouco

;      lds R16, IGNORE_USER ; Carrega o tamanho atual em R16
;      cpi R16, 0x00 ;
;      breq get_random ; 

;      ret 

MAIN:
     ; Realiza as configurações necessárias
     initialize_stack
     call config_buttons
     call config_leds
     call config_ng_pointer
     call config_timer
     call config_user_pointer

     ; Permite interrupções
     sei

     ; Inicia a flag para ignorar o usuário
     ser R16
     sts IGNORE_USER, R16

     ldi R25, 0x00


     clr R16
     sts N_RANDOM_SIG, R16

     sts N_SIG_USER, R16


     ; Inicia o processo
     NOT_GENIUS_GAME:
                    call check_ng_limit
                    call send_to_user

                    rjmp NOT_GENIUS_GAME




LOOP: rjmp LOOP

