; -------------------------------- ;
; Cassiano Bertol Leal - 00103937  ;
; Trabalho de Arq 1 - Intel 2009/2 ;
; Prof. Weber                      ;
; -------------------------------- ;

        assume cs:codigo,ds:dados,es:dados,ss:pilha

white_on_brown EQU 6Fh
white_on_black EQU 0Fh
blue_on_brown  EQU 61h
blue_on_black  EQU 01h
black_on_brown EQU 60h
brown_on_black EQU 06h
grey_on_blue   EQU 17h
white_on_blue  EQU 1Fh
grey_on_black  EQU 07h
white_on_cyan  EQU 3Fh

CR            EQU 0DH ; constante - carriage return;
LF            EQU 0AH ; constante - line feed;
BKSPC         EQU 08H ; constante - backspace
ESCAPE        EQU 1Bh

ASCII_A       EQU 041h
ASCII_1       EQU 031h

QUEEN         EQU 0DBh ;'R'
ATTSQUARE     EQU 0B0h ;':'

dados segment
blank db ' '

l_par dw ':','$'
r_par dw 'I','$'

t_top   db 4 dup(4 dup(0DFh,blue_on_brown ),4 dup(0DFh,blue_on_black ))
t_sqrs1 db 4 dup(4 dup(' ', white_on_brown),4 dup(' ', white_on_black))
t_sqrs2 db 4 dup(4 dup(' ', white_on_black),4 dup(' ', white_on_brown))
t_line1 db 4 dup(4 dup(0DFh,brown_on_black),4 dup(0DFh,black_on_brown))
t_line2 db 4 dup(4 dup(0DFh,black_on_brown),4 dup(0DFh,brown_on_black))
t_bottm db 4 dup(4 dup(0DCh,blue_on_black ),4 dup(0DCh,blue_on_brown ))
o_tabl  dw 32

t_letters db 'abcdefgh'
t_numbers db '87654321'

m_title db '-=( JOGO DAS RAINHAS )=-'
o_title dw $-m_title
m_autor db 'AUTOR: Cassiano Bertol Leal - 103937'
o_autor dw $-m_autor
m_part  db '= Partida =','$'
m_jog   db 'Jogador','$'
m_comp  db 'Computador','$'
m_plhld db ' - ','$'
m_comd  db '[----------( Comandos )----------]','$'
m_comd1 db 'A1,A2,..,H8: Posicionar Rainha','$'
m_comd2 db 'N: Iniciar novo jogo','$'
m_comd3 db 'R: Carregar jogo','$'
m_comd4 db 'S: Salvar jogo','$'
m_mostr db 'M: Mostrar casas ocupadas','$'
m_ocult db 'M: Ocultar casas ocupadas','$'
m_comd6 db 'T: Terminar o programa','$'
m_entr  db 'Entrada: ','$'
m_msgs  db 'Mensagens:','$'

m_take_input db 'Entre com um comando ou jogada.','$'

m_invcomd db 'Comando ou coordenada invalida...','$'

m_sqplayed db 'Casa ja possui rainha!!','$'
m_attacked db 'Casa atacada por outra rainha!!','$'

m_human_wins db 'Venceste a partida! Parabens!','$'
m_comp_wins  db 'Eu venci! Tente Novamente!','$'

m_end_game db 'Fim de papo. Obrigado por jogar!','$'

m_comp_play db 'Eu joguei em ','$'

counter1 db ?

input     db 8 dup(0)
          db '.TXT',0
inputtype db 1 dup(?)
command   db 2 dup(?)
          db '...','$'
line      db 0
column    db 0
linecol   db 0
filename  db 13 dup(?)

table_showing db 0

filehandler       dw 0
filesize          dw 0
m_filename_save   db 'Entre arquivo a ser salvo.','$'
m_filename_load   db 'Entre arquivo a ser carregado.','$'
m_path_not_found  db 'Caminho nao encontrado...','$'
m_file_not_found  db 'Arquivo nao encontrado...','$'
m_file_exists     db 'Arquivo ja existe. Sobrescrever?','$'
m_access_denied   db 'Acesso negado...','$'
m_file_save_error db 'Erro ao salvar o arquivo...','$'
m_file_load_error db 'Erro ao carregar o arquivo...','$'
m_file_saved      db 'Arquivo salvo!','$'
m_game_loaded     db 'Jogo carregado!','$'

playtable db 64 dup(5)

playround db 0

savegame  db 28 dup('.')
loadgame  db 28 dup('.')

video_segment dw 0B800h

dados ends

pilha   segment stack
        dw      128 dup(?)
pilha   ends

codigo  segment
main:   mov  ax,dados
        mov  ds,ax
        mov  es,ax

        mov   table_showing,0

__prepare_new_game:
        call _initialise_game
        call _initialise_savegame
        call _toggle_show_table
        call _toggle_show_table

__new_input:
        call _clear_entrada_msg
        call _test_for_free_square
        jc   __computer_wins
        lea  dx,m_take_input
        call _write_message
        call _position_cursor_on_entrada
        call _take_input
        jc   __new_input

        call _validate_input
        jc   __invalid_input
        cmp  dx,01h    ; valid play
        je   __human_played
        cmp  dx,03h
        je   __restart_game
        cmp  dx,04h
        je   __main_load_game
        cmp  dx,05h
        je   __main_save_game
        cmp  dx,06h
        je   __main_show_table
        cmp  dx,07h
        je   __fim

        __invalid_input:
                call _invalid_command
                jmp  __new_input
        __human_played:
                call _human_played
                jc   __new_input
                jmp  __computer_plays
        __restart_game:
                jmp  __prepare_new_game
        __main_load_game:
                call _load_game
                jmp  __new_input
        __main_save_game:
                call _save_game
                jmp  __new_input
        __main_show_table:
                call _toggle_show_table
                call _print_occupied_squares
                jmp  __new_input

__computer_plays:
        call _test_for_free_square
        jc   __human_wins
        call _computer_play
        inc  playround
        cmp  playround,8
        je   __computer_wins
        call __new_input

        __human_wins:
        lea  dx,m_human_wins
        call _write_message
;        mov  table_showing,0
;        call _show_table
        call _print_occupied_squares
        call _espera_tecla
        call _clear_entrada_msg
        jmp  __prepare_new_game

        __computer_wins:
        lea  dx,m_comp_wins
        call _write_message
;        mov  table_showing,0
;        call _show_table
        call _print_occupied_squares
        call _espera_tecla
        call _clear_entrada_msg
        jmp  __prepare_new_game

__fim:  ; retorno ao DOS com codigo de retorno 0 no AL (fim normal)
        lea  dx,m_end_game
        call _write_message
        call _espera_tecla
        call _clear_screen
        mov  ax,4c00h           ; funcao retornar ao DOS no AH
        int  21h                ; chamada do DOS

_computer_play proc
        call _convert_offset_to_play
        call _populate_command
        call _convert_input_to_play
        call _save_play
        call _print_computer_play
        call _espera_tecla

        cmp  table_showing,0
        je   __continue_computer_played
        call _print_occupied_squares

        __continue_computer_played:
        call _print_play

        ret
_computer_play endp

_print_computer_play proc
        lea  dx,m_comp_play
        call _write_message
        lea  dx,command
        mov ah,9               ; funcao exibir mensagem no AH
        int 21h                ; chamada do DOS
        ret
_print_computer_play endp

_toggle_show_table proc
        cmp  table_showing,0
        je   __table_is_not_showing

        call _print_table
        mov  table_showing,0
        mov  dh,15
        mov  dl,46
        call __prepare_cursor
        lea  dx,m_mostr
        call _write
        ret

        __table_is_not_showing:
        mov  table_showing,1
        mov  dh,15
        mov  dl,46
        call __prepare_cursor
        lea  dx,m_ocult
        call _write

        ret
_toggle_show_table endp

_print_occupied_squares proc
        cmp table_showing,0
        jne __print_occupied_squares
        ret

        __print_occupied_squares:
        push es
        mov  es,[video_segment]
        lea  si,playtable
        mov  di,2*(80*20+7)      ; linha 20, coluna 7

        mov  cx,8         ; 8 linhas

        __print_table_loop:
        push cx
        mov  cx,8        ; 8 casas na linha

        __print_line_loop:
                ;mov  ah,white_on_brown
                lodsb
                stosb
                inc di
                stosb
                add  di,5
                loop __print_line_loop

        sub  di,(32+(80*2))*2
        pop  cx
        loop __print_table_loop

        pop es
        ret
_print_occupied_squares endp

_populate_command proc
        lea di,command
        mov al,dl
        add al,'A'
        stosb
        mov al,dh
        add al,'1'
        stosb
        mov line,dh
        mov column,dl
        ret
_populate_command endp

_test_for_free_square proc
        ;; carry = 0 - ha casa livre
        ;;             dx <- offset da casa
        ;; carry = 1 - nao ha casa livre
        mov   al,00h
        lea   di,playtable
        add   di,7*8 ;posiciona ponteiro na linha 8 (superior)
        mov   cx,8
        __test_line:
                push  cx
                mov   cx,8
                repne scasb
                je    __found_sqare
                __line_full:
                sub   di,16
                pop   cx
                loop  __test_line
                jmp   __no_free_squares

        __found_sqare:
        dec di
        sub di,offset playtable
        mov dx,di
        pop cx
        clc
        ret

        __no_free_squares:
                stc
                ret
_test_for_free_square endp

_human_played proc
        ;; Sets the carry flag
        ;;    0 -> valid play; computer plays
        ;;    1 -> invalid play: human plays again
        call _convert_input_to_play
        lea  di,playtable
        mov  bl,linecol
        xor  bh,bh
        cmp  byte ptr [bx+di],00h
        jne  __square_taken
        call _save_play
        call _print_play
        inc  playround

        cmp  table_showing,0
        je   __continue_human_played
        call _print_occupied_squares

        __continue_human_played:
        clc                       ; clears carry flag
        ret

        __square_taken:
                cmp  byte ptr [bx+di],ATTSQUARE
                je   __square_under_attack
                lea dx,m_sqplayed
                jmp __write_square_taken
                __square_under_attack:
                        lea dx,m_attacked
                __write_square_taken:
                        call _write_message
                        call _espera_tecla
                        call _clear_entrada_msg
                stc ; sets the carry flag
                ret
_human_played endp


_clear_table proc
        lea  di,playtable
        mov  ax,00h
        mov  cx,32
        __loop_clear_table:
        stosw
        loop __loop_clear_table
        ret
_clear_table endp

_print_play proc
        push ax
        push di
        push es
        mov  es,[video_segment]

        cmp  playround,0
        jne  __play2
        mov di,52*2
        add di,(80*2)*5
        jmp __print
        __play2:
        cmp  playround,1
        jne  __play3
        mov di,67*2
        add di,(80*2)*5
        jmp __print
        __play3:
        cmp  playround,2
        jne  __play4
        mov di,52*2
        add di,(80*2)*6
        jmp __print
        __play4:
        cmp  playround,3
        jne  __play5
        mov di,67*2
        add di,(80*2)*6
        jmp __print
        __play5:
        cmp  playround,4
        jne  __play6
        mov di,52*2
        add di,(80*2)*7
        jmp __print
        __play6:
        cmp  playround,5
        jne  __play7
        mov di,67*2
        add di,(80*2)*7
        jmp __print
        __play7:
        cmp  playround,6
        jne  __play8
        mov di,52*2
        add di,(80*2)*8
        jmp __print
        __play8:
        mov di,67*2
        add di,(80*2)*8

        __print:
        mov al,column
        add al,'A'
        mov ah,white_on_blue
        stosw

        add di,2
        mov al,line
        add al,'1'
        stosw

        pop es
        pop di
        pop ax
        ret
_print_play endp

_ask_for_filename proc
        ; retorna em 'dx' o offset do filename
        ; recebe em 'dx' o ponteiro da mensagem a ser escrita
        ; seta o carry se user pressionou ESC
        call _write_message                ; pede pelo nome
        call _position_cursor_on_entrada   ; do arquivo
        call _take_input                   ;
        jnc  __filename_given
        stc
        ret

        __filename_given:
        lea si,input                       ;

        mov   al,' '
        mov   cx,8
        lea   di,input
        __convert_spaces:
        repne scasb
        jne   __spaces_converted
        mov   byte ptr [di-1],'_'
        jmp   __convert_spaces
        __spaces_converted:

        mov cx,13                          ; move nome do arquivo
        lea di,filename                    ; para variavel filename
        rep movsb                          ;

        lea di,filename                    ;
        mov cx,13                          ;
        mov al,00h                         ; concatena filename
        repne scasb                        ; com o sufixo
        jne __filename_ok                  ; .TXT
        mov filehandler,di                 ;
        dec filehandler                    ;
        repe scasb                         ;
        dec di                             ;
        mov si,di                          ;
        mov di,filehandler                 ;
        inc cx                             ;
        rep movsb                          ;

        __filename_ok:
        lea dx,filename

        clc
        ret
_ask_for_filename endp

_load_game proc
        __begin_load_game:
        lea dx,m_filename_load             ;
        call _ask_for_filename
        jnc  __filename_entered
        stc
        ret

        __filename_entered:
        mov ah,03dh                        ; abre arquivo existente
        mov al,00h                         ; modo leitura
        int 21h                            ;
        jnc __file_opened                  ;
        cmp ax,05h                         ;
        je  __load_access_denied           ;
        cmp ax,02h                         ;
        je  __load_file_not_found          ;
        cmp ax,03h                         ;
        je  __load_path_not_found          ;
        jmp __file_load_error              ;

        __file_opened:                     ;
        mov  filehandler,ax                ; arquivo aberto
        call _initialise_loadgame          ; prepara 'loadgame'
        call _initialise_savegame          ; prepara 'savegame'

        mov ah,03Fh                        ;
        mov bx,filehandler                 ;
        mov cx,28                          ;
        lea dx,loadgame                    ; carrega dados
        int 21h                            ; do arquivo
        jnc __game_loaded                  ;
        cmp ax,05h                         ;
        je  __load_access_denied           ;
        jmp __file_load_error              ;

        __game_loaded:                     ;
        mov  filesize,ax                   ; tamanho do arquivo em 'filesize'
                                           ;
        mov  ah,03Eh                       ; dados carregados na
        mov  bx,filehandler                ; variavel 'loadgame';
        jc   __file_load_error             ; fecha arquivo

        call _initialise_loaded_game       ; converte 'loadgame' em um jogo
        call _print_occupied_squares

        lea  dx,m_game_loaded              ; jogo carregado
        call _write_message                ;
        call _espera_tecla                 ;
        call _clear_entrada_msg
        ret                                ;

        __load_file_not_found:
        lea dx,m_file_not_found            ;
        call _write_message                ; arquivo nao
        call _espera_tecla                 ; encontrado
        call _clear_entrada_msg            ;
        jmp  __begin_load_game             ;

        __load_access_denied:
        lea dx,m_access_denied             ; erro de acesso
        call _write_message                ; negado ao
        call _espera_tecla                 ; arquivo
        call _clear_entrada_msg
        ret                                ;

        __load_path_not_found:
        lea dx,m_path_not_found            ;
        call _write_message                ; caminho nao
        call _espera_tecla                 ; encontrado
        call _clear_entrada_msg            ;
        ret                                ;

        __file_load_error:
        lea dx,m_file_load_error           ; excecao no carregamento
        call _write_message                ; do arquivo
        call _espera_tecla                 ;
        call _clear_entrada_msg
        ret                                ;
_load_game endp

_initialise_game proc
        call _print_left_side
        call _print_right_side
        call _clear_table

        mov   playround,0
        ret
_initialise_game endp

_initialise_savegame proc
        mov   al,00h
        mov   cx,28
        lea   di,savegame
        __clear_savegame:
        stosb
        loop  __clear_savegame
        ret
_initialise_savegame endp

_initialise_loadgame proc
        mov   al,00h
        mov   cx,28
        lea   di,loadgame
        __clear_loadgame:
        stosb
        loop  __clear_loadgame
        ret
_initialise_loadgame endp

_initialise_loaded_game proc
        call  _initialise_game
        call _toggle_show_table
        call _toggle_show_table

        mov   cx,filesize
        lea   di,loadgame

        __find_plays:
        mov   al,CR
        repne scasb
        je    __found_plays
        ret

        __found_plays:
        push di
        push cx
        mov  cx,2
        sub  di,6
        mov  si,di

        __load_play:
        push cx
        mov  cx,2
        lea  di,command
        rep  movsb
        push si
        call _convert_input_to_play
        call _save_play
        call _print_play
        pop  si
        inc  si
        inc  playround
        pop  cx
        loop __load_play

        pop  cx
        pop  di
        jmp  __find_plays

_initialise_loaded_game endp

_save_game proc
        call _clear_entrada_msg            ;
        lea dx,m_filename_save             ;
        call _ask_for_filename
        jnc  __save_filename_given
        stc
        ret

        __save_filename_given:
        mov ah,03Dh
        mov al,0
        int 21h
        jnc __file_exists

        mov ah,03Eh
        mov bx,ax
        int 21h

        __save_the_game:
        mov ah,03Ch                         ;
        mov cx,0                            ;
        int 21h                             ;
        jnc __file_created                  ; cria ou trunca
        cmp ax,03                           ; arquivo
        je  __save_path_not_found           ;
        cmp ax,05                           ;
        jne __file_save_error               ;
        jmp __save_access_denied            ;

        __file_created:                     ; arquivo aberto
        mov filehandler,ax                  ;

        lea   di,savegame                   ; calcula o tamanho
        mov   al,00h                        ; do arquivo
        mov   cx,28                         ; a ser salvo
        repne scasb                         ;
        dec   di                            ;
        sub   di,offset savegame            ;
        mov   cx,di                         ; tamanho de arquivo em 'cx'

        mov ah,040h                         ;
        lea dx,savegame                     ;
        mov bx,filehandler                  ; escreve no
        int 21h                             ; arquivo
        jnc __close_file                    ;
        cmp ax,05                           ;
        jne __file_save_error               ;
        jmp __save_access_denied            ;

        __close_file:                       ;
        mov ah,03Eh                         ;
        mov bx,filehandler                  ; fecha o arquivo
        int 21h                             ; salvo
        jc  __file_save_error               ;
        lea dx,m_file_saved                 ;
        call _write_and_wait
        ret                                 ;

        __save_path_not_found:              ;
        lea dx,m_path_not_found             ; caminho nao
        call _write_and_wait                ; encontrado
        ret                                 ;

        __save_access_denied:               ;
        lea dx,m_access_denied              ; erro de acesso
        call _write_and_wait                ; negado ao
        ret                                 ; arquivo

        __file_save_error:                  ;
        lea  dx,m_file_save_error            ; excecao no salvamento
        call _write_and_wait
        ret                                 ; do arquivo

        __file_exists:
        push dx
        lea  dx,m_file_exists
        call _write_message                ; pede pelo nome
        call _position_cursor_on_entrada   ; do arquivo
        call _take_input                   ;
        jnc  __overwrite
        stc
        pop  dx
        ret

        __overwrite:
        lea  si,input
        cmp  byte ptr [si+1],00h  ;; extra characters given
        jne  __file_exists
        cmp  byte ptr [si],'S'
        je   __do_overwrite
        cmp  byte ptr [si],'N'
        je   __do_not_overwrite
        __do_overwrite:
                pop dx
                jmp __save_the_game
        __do_not_overwrite:
                pop dx
                ret
_save_game endp

_write_and_wait proc
        call _write_message                 ;
        call _espera_tecla                  ;
        call _clear_entrada_msg            ;
        ret
_write_and_wait endp

_convert_input_to_play proc
        push  ax
        lea   si,command   ; carrega inicio do vetor comando em si
        mov   ax,00000h    ; zera ax
        lodsb              ; carrega ASCII da coluna em al
        sub   al,'A'       ; transforma em indice (0-7)
        mov   column,al    ; salva coluna em 'column'
        lodsb              ; carrega linha em al
        sub   al,'1'       ; indexa linha (0-7)
        mov   line,al      ; salva indice da linha em 'line'
        shl   al,3         ; transforma al em offset da linha
        add   al,column    ; transforma al em offset da CASA
        mov   linecol,al
        pop   ax
        ret
_convert_input_to_play endp

_convert_offset_to_play proc
        ;; takes an offset in dx and converts to play
        ;; dl <- index of column
        ;; dh <- index of line
        shl   dx,5
        shr   dl,5
        ret
_convert_offset_to_play endp

_save_play proc
        push  ax
        push  bx
        lea   si,command   ; carrega inicio do vetor comando em si
        lea   di,playtable ; idem para playtable em di
        mov   al,linecol

        mov   bl,al        ;  bl <- al
        xor   bh,bh        ; zera bh, transformando bx em offset da casa

        mov   byte ptr [bx+di],QUEEN ; carrega QUEEN ('R') na posicao jogada

        mov  cx,8
        mov  bl,line ; carrega indice da linha em bl
        shl  bl,3    ; transforma bl em offset da linha
        xor  bh,bh   ; zera bh
        __fill_line_loop:
                cmp   byte ptr [bx+di],00h ; testa se casa esta ocupada ou atacada
                jne   __continue_fill_line ; se sim, pula para proxima casa
                mov   byte ptr [bx+di],ATTSQUARE ; se nao, popula com ATTSQUARE ('.')
                __continue_fill_line:
                inc   bx                   ;
                loop  __fill_line_loop     ; continua o loop ate preencher toda a linha

        mov cx,8
        mov bl,column    ; carrega em bx
        xor bh,bh        ; o offset da coluna
        __fill_column_loop:
                cmp  byte ptr [bx+di],00h   ; testa casa ocupada ou atacada
                jne  __continue_fill_column ; caso positivo, pula
                mov  byte ptr [bx+di],ATTSQUARE   ; caso negativo, marca como atacada
                __continue_fill_column:
                add  bx,8                   ; pula para a proxima linha
                loop __fill_column_loop     ; e repete ate o final do tabuleiro

        mov cx,8
        mov dl,column
        xor dh,dh
        mov al,line
        xor ah,ah
        cmp ax,0
        je  __reached_played_line
        __fill_diags_loop1:
                mov bx,dx
                sub bx,ax
                jl  __next_square_on_line1
                cmp byte ptr [bx+di],00h
                jne __next_square_on_line1
                mov byte ptr [bx+di],ATTSQUARE
                __next_square_on_line1:
                mov bx,dx
                add bx,ax
                cmp bx,7
                jg  __continue_fill_diags1
                cmp byte ptr [bx+di],00h
                jne __continue_fill_diags1
                mov byte ptr [bx+di],ATTSQUARE
                __continue_fill_diags1:
                add  di,8
                dec  ax
                jnz  __fill_diags_loop1_loop
                loop __reached_played_line
                __fill_diags_loop1_loop:
                loop __fill_diags_loop1

        __reached_played_line:
        mov  ax,1
        add  di,8
        loop __fill_diags_loop2
        jmp  __done_filling
                __fill_diags_loop2:
                mov bx,dx
                sub bx,ax
                jl  __next_square_on_line2
                cmp byte ptr [bx+di],00h
                jne __next_square_on_line2
                mov byte ptr [bx+di],ATTSQUARE
                __next_square_on_line2:
                mov bx,dx
                add bx,ax
                cmp bx,7
                jg  __continue_fill_diags2
                cmp byte ptr [bx+di],00h
                jne __continue_fill_diags2
                mov byte ptr [bx+di],ATTSQUARE
                __continue_fill_diags2:
                add di,8
                inc ax
                loop __fill_diags_loop2


        __done_filling:
        lea   di,savegame
        mov   al,00h
        mov   cx,28
        repne scasb
        dec   di
        mov   al,column
        add   al,'A'
        stosb
        mov   al,line
        add   al,'1'
        stosb
        mov   dl,playround
        cmp   dl,7
        je    __done_save
        shr   dl,1
        jnc   __even_play
        mov   al,CR
        stosb
        mov   al,LF
        stosb
        jmp   __done_save
        __even_play:
        mov   al,'-'
        stosb

        __done_save:
        pop bx
        pop ax
        ret
_save_play endp

_validate_input proc
        ;; Carry = 1 -> input invalido
        ;; Carry = 0 -> input valido
        ;; retorna codigo de erro em 'dx'
        ;;    01h = jogada valida
        ;;    03h-07h = codigo de comando
        lea  si,input
        cmp  byte ptr [si],'A'
        jb   __invalid_command
        cmp byte ptr [si],'H'
        jbe __validate_line
        jmp __validate_command  ; comando enviado

        __validate_line:
                lea   di,command
                lodsb
                stosb
                cmp   byte ptr [si],'1'
                jb    __invalid_command
                cmp   byte ptr [si],'8'
                ja    __invalid_command
                lodsb
                stosb
                lodsb                      ; verifica se foram
                cmp   al,00h               ; digitados apenas 2
                jne   __invalid_command    ; caracteres
                mov   dx,01h   ; jogada
                clc            ; valida
                ret

        __validate_command:
                lea   si,input
                lodsb
                cmp   byte ptr [si],00h
                jne   __invalid_command
                cmp   al,'N'
                je    __new_game
                cmp   al,'R'
                je    __load_game
                cmp   al,'S'
                je    __save_game
                cmp   al,'M'
                je    __fill_table
                cmp   al,'T'
                je    __end_game
                __invalid_command:
                        stc
                        ret
                __new_game:
                        mov dx,03h
                        ret
                __load_game:
                        mov dx,04h
                        ret
                __save_game:
                        mov dx,05h
                        ret
                __fill_table:
                        mov dx,06h
                        ret
                __end_game:
                        mov dx,07h
                        ret
_validate_input endp

_invalid_command proc
        lea  dx,m_invcomd
        call _write_message
        call _espera_tecla
        call _clear_entrada_msg
        mov  dx,00h
        ret
_invalid_command endp

_write_message proc
        push dx
        mov  dh,22          ; linha
        mov  dl,44          ; coluna
        mov  bh,0           ; página
        mov  ah,2           ; posiciona cursor
        int  10h
        pop  dx
        call _write
        ret
_write_message endp

_take_input proc
        lea  di,input
        mov  cx,8
        mov  al,00h
        __clear_input_loop:
        stosb
        loop __clear_input_loop

        lea  di,input
        mov  cx,8                 ; ler 8 caracteres
__read_next:
        push cx                   ; int 21h altera cx ...
        mov  ah,1
        int  21h                  ; le um caractere do teclado
        pop  cx

        ;; testa se foi enter ou bkspc
        cmp  al,CR
        jne  __not_enter
        cmp  cx,8
        je   __escape
        call _clear_entrada_msg
        ret
        __not_enter:
        cmp al,BKSPC              ; verifica se foi um backspace
        je  __backspace

        cmp al,ESCAPE
        je  __escape

        call __capitalise         ; converte para maiusculas

        stosb                     ;
        loop __read_next
        call _clear_entrada_msg
        clc
        ret

__backspace:
        mov  ah,2
        mov  dl,' '                ; escreve espaco sobre caractere anterior
        int  21h
        inc  cx
        cmp  cx,8
        jg   __first_char

        mov  ah,2
        mov  dl,BKSPC              ; recua cursor para posicao do espaco
        int  21h
        dec  di                    ; elimina digito do buffer
        mov  byte ptr [di],00h     ; limpa posicao no buffer
        jmp  __read_next

        __first_char:
        dec  cx                    ; acerta quantidade de digitos lidos
        jmp  __read_next

__escape:
        stc
        ret
_take_input endp

__capitalise proc
        cmp al,'a'
        jb  __capitalise_continue
        cmp al,'z'
        ja  __capitalise_continue
        sub al, 20h
        __capitalise_continue:
        ret
__capitalise endp

_print_text proc
        push  es
        mov   es,[video_segment]
        cld                     ;limpa direcao
        __print_text_loop:
        lodsb                   ;carrega primeiro caractere
        stosw                   ;carrega caractere e seua atributos na memoria de video
        loop  __print_text_loop;repete ate terminar topo
        pop   es
        ret
_print_text endp

_initialise_screen proc
        push es
        mov  es,[video_segment]
        mov  di,0            ; will begin writing at offset 0
        mov  cx,2000         ; will write 2000 chars (80 * 25 = 2000 --- the whole screen)
        mov  al,blank      ; loads our blank char into ax
        mov  ah,grey_on_blue
        cld                     ;limpa direcao
        __initialise_screen_loop:
        stosw                   ;carrega caractere e seua atributos na memoria de video
        loop  __initialise_screen_loop;repete ate terminar topo
        pop es
        ret
_initialise_screen endp

_print_table proc
        push es
        mov  es,[video_segment]
        mov  di,12           ;inicia na coluna 6
        add  di,(80*2)*5     ;linha 5
        lea  si,t_top        ;prepara para imprimir topo do tabuleiro
        mov  cx,o_tabl       ;  que contem <o_tabl> caracteres
        cld                     ;limpa direcao
        __print_top_loop:
        lodsw                   ;carrega primeiro caractere
        stosw                   ;carrega caractere e seua atributos na memoria de video
        loop  __print_top_loop;repete ate terminar topo

        mov  counter1,8      ;conta numero de linhas com casas para imprimir

        __table_loop:
        add  di,2*(80-32)
        lea  si,t_sqrs1
        mov  cx,o_tabl
        cld                     ;limpa direcao
        __print_squares1_loop:
        lodsw                   ;carrega primeiro caractere
        stosw                   ;carrega caractere e seua atributos na memoria de video
        loop  __print_squares1_loop;repete ate terminar topo

        add  di,2*(80-32)
        lea  si,t_line1
        mov  cx,o_tabl
        cld                     ;limpa direcao
        __print_lines1_loop:
        lodsw                   ;carrega primeiro caractere
        stosw                   ;carrega caractere e seua atributos na memoria de video
        loop  __print_lines1_loop;repete ate terminar topo

        dec counter1

        add  di,2*(80-32)
        lea  si,t_sqrs2
        mov  cx,o_tabl
        cld                     ;limpa direcao
        __print_squares2_loop:
        lodsw                   ;carrega primeiro caractere
        stosw                   ;carrega caractere e seua atributos na memoria de video
        loop  __print_squares2_loop;repete ate terminar topo

        dec counter1
        jz __print_bottm

        add  di,2*(80-32)
        lea  si,t_line2
        mov  cx,o_tabl
        cld                     ;limpa direcao
        __print_lines2_loop:
        lodsw                   ;carrega primeiro caractere
        stosw                   ;carrega caractere e seua atributos na memoria de video
        loop  __print_lines2_loop;repete ate terminar topo

        jmp __table_loop

        __print_bottm:
        add  di,2*(80-32)
        lea  si,t_bottm
        mov  cx,o_tabl
        cld                     ;limpa direcao
        __print_bottm_loop:
        lodsw                   ;carrega primeiro caractere
        stosw                   ;carrega caractere e seua atributos na memoria de video
        loop  __print_bottm_loop;repete ate terminar topo

        call _print_coords

        pop  es
        ret
_print_table endp

_print_coords proc
        mov di,8
        add di,(80*2)*6
        lea si,t_numbers
        mov cx,8
        mov ah,grey_on_blue

        cld                     ;limpa direcao
        __print_coords_loop:
        lodsb
        stosw                   ;carrega caractere e seua atributos na memoria de video
        add   di,(80*2)*2-2
        loop  __print_coords_loop;repete ate terminar topo

        mov di,14
        add di,(80*2)*22
        lea si,t_letters
        mov cx,8
        mov ah,grey_on_blue

        cld                     ;limpa direcao
        __print_coords2_loop:
        lodsb
        stosw                   ;carrega caractere e seua atributos na memoria de video
        add   di,6
        loop  __print_coords2_loop;repete ate terminar topo

        ret
_print_coords endp

_print_line proc
        ret
_print_line endp

_print_title proc
        mov  di,9*2         ;inicia na coluna 14
        add  di,(80*2)       ;linha 1
        lea  si,m_title      ;prepara para imprimir
        mov  cx,o_title           ;
        mov  ah,white_on_blue        ;carrega atributos da fonte
        call _print_text

        mov  di,3*2          ;inicia na coluna 3
        add  di,(80*2)*3     ;linha 3
        lea  si,m_autor      ;prepara para imprimir
        mov  cx,o_autor
        mov  ah,grey_on_blue        ;carrega atributos da fonte
        call _print_text

        ret
_print_title endp

_print_separator proc
        mov counter1,25

        __loop_separator:
        call __prepare_separator
        lea  dx,l_par
        call _write
        dec  counter1
        jz   __end_separator
        call __prepare_separator
        lea  dx,r_par
        call _write
        dec  counter1
        jmp  __loop_separator

        __prepare_separator proc
                mov ah,2           ; posiciona cursor
                mov dh,[counter1]    ; na linha <counter-1>,
                dec dh
                mov dl,41          ; coluna 38,
                mov bh,0           ; página 0
                int 10h
                ret
        __prepare_separator endp

        __end_separator:
        ret
_print_separator endp

_print_left_side proc
        call _initialise_screen
        call _print_table
        call _print_title
        call _print_separator
        ret
_print_left_side endp

_print_right_side proc
        mov  dh,1                    ;
        mov  dl,56                   ; imprime texto
        call __prepare_cursor        ; "Partida"
        lea  dx,m_part               ; no topo do lado direito
        call _write                  ;

        mov  dh,3                    ;
        mov  dl,50                   ;
        call __prepare_cursor        ; imprime
        lea  dx,m_jog                ; "Jogador"
        call _write                  ; e
        mov  dh,3                    ; "Computador"
        mov  dl,63                   ;
        call __prepare_cursor        ;
        lea  dx,m_comp               ;
        call _write                  ;

        mov  counter1,5              ;
        __print_placeholders:           ;
        mov  dh,counter1             ;
        mov  dl,52                   ; imprime placeholders
        call __prepare_cursor        ; para as jogadas
        lea  dx,m_plhld              ;
        call _write                  ;
        mov  dh,counter1             ;
        mov  dl,67                   ;
        call __prepare_cursor        ;
        lea  dx,m_plhld              ;
        call _write                  ;
        inc  counter1                ;
        cmp  counter1,9              ;
        jne  __print_placeholders    ;

        mov  dh,10
        mov  dl,44
        call __prepare_cursor
        lea  dx,m_comd
        call _write
        mov  dh,11
        mov  dl,46
        call __prepare_cursor
        lea  dx,m_comd1
        call _write
        mov  dh,12
        mov  dl,46
        call __prepare_cursor
        lea  dx,m_comd2
        call _write
        mov  dh,13
        mov  dl,46
        call __prepare_cursor
        lea  dx,m_comd3
        call _write
        mov  dh,14
        mov  dl,46
        call __prepare_cursor
        lea  dx,m_comd4
        call _write
        mov  dh,15
        mov  dl,46
        call __prepare_cursor
        lea  dx,m_mostr
        call _write
        mov  dh,16
        mov  dl,46
        call __prepare_cursor
        lea  dx,m_comd6
        call _write

        mov  dh,21
        mov  dl,44
        call __prepare_cursor
        lea  dx,m_msgs
        call _write

        mov  dh,18
        mov  dl,44
        call __prepare_cursor
        lea  dx,m_entr
        call _write

        call _clear_entrada_msg
        ret
_print_right_side endp

__prepare_cursor proc
        mov ah,2           ; posiciona cursor
        mov bh,0           ; página 0
        int 10h
        ret
__prepare_cursor endp

_clear_entrada_msg proc
        push  es
        mov   es,[video_segment]
        mov   di,53*2           ;inicia na coluna 5
        add   di,(80*2)*18     ;linha 5
        mov   cx,8       ;  que contem <o_tabl> caracteres
        mov   al,blank
        mov   ah,grey_on_black        ;carrega atributos da fonte
        __loop_entrada:
        stosw
        loop  __loop_entrada

        mov   di,44*2           ;inicia na coluna 44
        add   di,(80*2)*22     ;linha 5
        mov   cx,34       ;  que contem <o_tabl> caracteres
        mov   al,blank
        mov   ah,white_on_cyan        ;carrega atributos da fonte
        __loop_msg:
        stosw
        loop  __loop_msg

        call _position_cursor_on_entrada
        pop es
        ret
_clear_entrada_msg endp

_position_cursor_on_entrada proc
        mov ah,2
        mov dh,18
        mov dl,53
        int 10h
        ret
_position_cursor_on_entrada endp

_clear_screen proc
        push es
        mov  es,[video_segment]
        mov  di,0            ; will begin writing at offset 0
        mov  cx,2000         ; will write 2000 chars (80 * 25 = 2000 --- the whole screen)
        mov  al,blank      ; loads our blank char into ax
        mov  ah,grey_on_black
        cld                     ;limpa direcao
        __clear_screen_loop:
        stosw                   ;carrega caractere e seua atributos na memoria de video
        loop  __clear_screen_loop;repete ate terminar topo
        pop es
        ret
_clear_screen endp

_espera_tecla proc
        mov ah,0               ; funcao esperar tecla no AH
        int 16h                ; chamada do DOS
        ret
_espera_tecla endp

_write proc
        ; assume que dx aponta para a mensagem
        mov ah,9               ; funcao exibir mensagem no AH
        int 21h                ; chamada do DOS
        ret
_write endp

codigo  ends
        end main
