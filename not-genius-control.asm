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
.cseg

.macro initialize_stack
       ldi R16, HIGH(RAMEND)
       out SPH, R16
       ldi R16, LOW(RAMEND)
       out SPL, R16
.endmacro

config_leds:

            ; !!! Ainda não acabado !!!!

            ; configura as portas em que os LEDs vão estar conectados

            ldi r16, (1 << PC2) | (1 << PC1) | ( 1 << PC0)
            ldi r19, 0x00  ; seta o estado inicial como desligado

            out DDRC, R16
            out PORTB, R19

            ret


config_buttons:

               ; Configura a porta D para receber os quatro botões

               ldi R16, (1 << PD3) | (1 << PD0) | (1 << PD2) | (1 << PD6)
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

                    ldi R18, 0x00 ; inicia contador p/ verificacao ds elementos
                    lds R19, N_RANDOM_SIG ; armazena o tamanho da array


                    ldi YL, LOW(user_sig_array)
                    ldi YH, HIGH(user_sig_array)

                    ret

turn_on_led:

            ; Clear counter/timer
            clr R16
            out TCNT0, R16

            ; Configure Clear OC0A on compare match AND CTC Mode
            ldi R16, (1 << COM0A1) | (0 << COM0A0) | (1 << WGM01) | (0 << WGM00)
            out TCCR0A, R16

            ; Configure prescaler to clk/1024
            ldi R16, (1 << CS02) | (0 << CS01) | (1 << CS00)
            out TCCR0B, R16

            ; Configure max value of counter
            ldi R16, 0xFF
            out OCR0A, R16

            ret


check_ng_limit:
               ; Subrotina para verificação do comprimento da entrada


               lds R16, N_RANDOM_SIG ; Carrega o tamanho atual em R16
               cpi R16, 0x10 ; Tamanho máximo = 10
               brne get_random ; Se N_RANDOM_SIG != 10 continua

               call reset  ; se igual reseta os valores


get_random:

           ; Subrotina para ler da parte do Leo e adicionar na
           ; array

           clr R16
           clr R17


           ; Lê o valor e adiciona na not_genius_array
           ; Aqui trocar para a leitura da parte do codigo do leo

           ldi R16, 0x01
           st X+, R16


           ; Lê o valor atual da quantidade de sinais e incrementa

           lds R17, N_RANDOM_SIG
           inc R17
           sts N_RANDOM_SIG, R17


           ret

send_to_user:

             ; Função para ligar o LED

             ; Retorna o último valor da array pro usário

             ret

read_from_user:

               ; Função de armazenamento dos valores do usuário

               ; Algortimo:

               ; - Armazena a entrada do usuário em uma lista de entradas
               ; - Se N_SIG_USER é menor que N_RANDOM_SIG espera mais entradas (talvez seja interessante ter um LED de espera)
               ; - Se já chegou ao ponto certo desliga a luz de espera e verifica se tá certo


; READ_PORTD: vai ser parecido com isso que preciso, só que teno quatro botoes

           ; define as mascaras dos pinos
           ldi R20, 0b00001000 ; a=3
           ldi R21, 0b00000001 ; b=0
           ldi R22, 0b00000100 ; c=2

           in R18, PIND  ; faz a leitura da porta D

           ; armazena a intersecção
           and R20, R18
           and R21, R18
           and R22, R18

           ; a: 3 -> 2, b: 0 -> 1, c: 2 -> 0

           lsr R20
           lsl R21
           lsr R22
           lsr R22

           ; combina valores no R23

           clr R23

           or R23, R20
           or R23, R21
           or R23, R22

           sts btn_value, R23 ; coloca na memoria o valor

           ret



check_sequence:

               ; Função que verifica a entrada do usuário

               call config_user_pointer

               cp R18, R19  ; i == N_RANDOM_SIG ? break : keep
               breq get_out

               ld R20, X  ; sinal do not genius
               ld R21, Y  ; sinal do usuario

               cp R20, R21  ; compara os valores
               brne reset  ;

               call check_sequence

               ret

               get_out:
                        ret

delay:

reset:

time_to_think: 

     ; talvez eu precise dessa flag pra deixar o codigo ignorando as entradas do usuario
     ; enquanto o jogo pensa um pouco

     lds R16, IGNORE_USER ; Carrega o tamanho atual em R16
     cpi R16, 0x00 ;
     breq get_random ; 

     ret 

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

     ; Inicia o processo
     NOT_GENIUS_GAME:
                     call get_random
                     call send_to_user
                     call read_from_user
                     call check_sequence

                     rjmp NOT_GENIUS_GAME


LOOP: rjmp LOOP

