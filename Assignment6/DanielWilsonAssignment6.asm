; Daniel Wilson
; CSC 3000 X00 Advanced Computer Architecture
; Homework #6
; 10/3/2024

; Program: Tic-Tac-Toe Game
; Description: This program implements a simple console-based Tic-Tac-Toe game for two players.
; Players are prompted to enter their names, and they take turns to input their moves on a 3x3 grid.
; The program checks for valid moves, manages player turns, and detects winning combinations.
; If a player wins or if an invalid move is made, appropriate messages are displayed.
; The game continues until a player wins or the board is full.
; Key Features:
; - Displays the current game grid.
; - Collects player names.
; - Validates user input for moves.
; - Tracks moves and checks for winning conditions.
; - Prompts players in turn to make their moves.



INCLUDE C:\Irvine\Irvine32.inc          
INCLUDELIB C:\Irvine\Irvine32.lib       

.386                                     
.model flat, stdcall                    
.stack 4096                              
ExitProcess proto, dwExitCode:dword     

.data
    grid BYTE "1", "|", "2", "|", "3", 0                    ; the first row of the grid
         BYTE "4", "|", "5", "|", "6", 0                    ; the second row of the grid
         BYTE "7", "|", "8", "|", "9", 0                    ; the third row of the grid

    lookupTable DWORD 0, 2, 4                       ; index for input 1, 2, 3
                DWORD 6, 8, 10                       ; index for input 4, 5, 6
                DWORD 12, 14, 16                       ; index for input 7, 8, 9

    winningCombinations DWORD 0, 1, 2          ; Row 1
                        DWORD 3, 4, 5          ; Row 2
                        DWORD 6, 7, 8          ; Row 3
                        DWORD 0, 3, 6          ; Column 1
                        DWORD 1, 4, 7          ; Column 2
                        DWORD 2, 5, 8          ; Column 3
                        DWORD 0, 4, 8          ; Diagonal 1
                        DWORD 2, 4, 6           ; Diagonal 2
    
    p1NamePrompt BYTE "Player 1, enter your name: ", 0      ; prompt for first player name
    p2NamePrompt BYTE "Player 2, enter your name: ", 0      ; prompt for second player name
    movePrompt BYTE ", enter your move: ", 0      ; prompt for second player move
    invalidPrompt BYTE "Invalid Input, Please Try Again", 0 ; error for invalid input
    occupiedError BYTE "That Cell Is Occupied Try Again", 0 ; error for occupied cell
    p1WinMessage BYTE "Player 1 Wins The Game!", 0          ; player 1 win message
    p2WinMessage BYTE "Player 2 Wins The Game!", 0          ; player 2 win message

    p1Name BYTE 20 DUP(0)              ; player one name
    p2Name BYTE 20 DUP(0)              ; player two name
    currentPlayerTurn BYTE 1           ; store which player's turn it is, initialized to 1
    requestedMove BYTE ?               ; store requested move
    p1MoveRecord DWORD 9 DUP(0)             ; array to track player 1's moves
    p2MoveRecord DWORD 9 DUP(0)             ; array to track player 2's moves

.code
main proc
startGame:
    ; call displayInstructions
    call displayGrid
    call collectNames

gameLoop:
    call playTurn
    call displayGrid
    call checkWin
    call switchPlayer
    jmp gameLoop


displayGrid proc
; Summary:
; Input: None
; Output: Displays the current game grid to the console.
; Registers Used: 
;   ECX - Loop counter for rows
;   EDX - Pointer to the grid data for output
                                        ; display the grid
    mov ecx, 3                          ; loop counter for each row
    mov edx, OFFSET grid                ; load grid into edx for output

    displayRow:
    call Writestring                    ; display row
    call Crlf                           ; print new line
    add edx, 6                          ; move to next line
    loop displayRow                     ; loop all rows

    ret
displayGrid endp

collectNames proc
; Summary:
; Input: Names of Players
; Output: Prompts
; Registers Used: 
;   EDX - Pointer to the prompt or player name
;   ECX - Size of the name buffer
                                        ; collect user names 
                                        ; PLAYER 1
    mov edx, OFFSET p1NamePrompt        ; load prompt into edx for output
    call WriteString                    ; display prompt to consol
    mov edx, OFFSET p1Name              ; load the address to store name
    mov ecx, SIZEOF p1Name              ; load size of string (20 byte max)
    call ReadString                     ; collect input
                                        ; PLAYER 2
    mov edx, OFFSET p2NamePrompt        ; load prompt into edx for output
    call WriteString                    ; display prompt to consol
    mov edx, OFFSET p2Name              ; load the address to store name
    mov ecx, SIZEOF p2Name              ; load size of string (20 byte max)
    call ReadString                     ; collect input
    ret
collectNames endp

playTurn proc
; Summary:
; Input: Move input
; Output: Updates the grid with the player's move or prompts for a valid move.
; Registers Used:
;   EAX - Holds the converted move index
;   EBX - Pointer to the lookup table or player move record
;   ECX - Max input length for player input
;   EDX - Pointer to prompt strings or move record                                   ; collect player input
    cmp currentPlayerTurn, 2        ; is it player 2's turn?
    je promptPlayer2                ; if yes, display player 2 prompt

   promptPlayer1:
   mov edx, OFFSET p1Name           ; move p1 name to register for display
   call WriteString                 ; display name
   mov edx, OFFSET movePrompt       ; move prompt to register for display
   call WriteString                 ; display prompt
   jmp promptComplete               ; skip over player 2 prompt

   promptPlayer2:
   mov edx, OFFSET p2Name           ; move p2 name to register for display
   call WriteString                 ; display name
   mov edx, OFFSET movePrompt       ; move prompt to register for display
   call WriteString                 ; display prompt

   promptComplete:                  ; continue to collect input
    
                                    ; COLLECT MOVE INPUT
   mov edx, OFFSET requestedMove    ; store move in requestedMove variable
   mov ecx, 2                       ; max input length (1 digit + null term)
   call ReadString
                        
                                    ; Convert input character to number
    movzx eax, requestedMove
    sub eax, '0'                    ; convert ascii to int

                                    ; Validate the input (0-9)
    cmp eax, 1                      ; compare to 1
    jl invalidInput                 ; error if less than 1
    cmp eax, 9                      ; compare to 9
    jg invalidInput                 ; error if greater than 9

                                    ; Use the lookup table to get the corrosponding index
    dec eax                         ; conver 1 based input to 0 based index
    mov ebx, OFFSET lookupTable
    mov eax, [ebx + eax * 4]        ; get the index from the lookup table
                                    ; eax now contains the index of the 2d array
    
                                    ; Compare index with symbols to check if the cell is occupied
    mov bl, [grid + eax]            ; load the value at the index into bl
    cmp bl, 'X'                     ; compare with symbol
    je cellOccupied                 ; error if occupied
    cmp bl, 'O'                     ; compare with symbol
    je cellOccupied                 ; error if occupied

                                    ; If cell is not occupied, place current players symbol
    cmp currentPlayerTurn, 1        ; check if player 1 turn
    je placePlayer1Symbol           ; place player 1's symbol if true
    mov [grid + eax], 'O'           ; place player 2's symbol if false
    jmp completePlacement           ; done placing symbol
    placePlayer1Symbol:
    mov [grid + eax], 'X'           ; display player 1 symbol
    completePlacement:

                                    ; Update the player's move record
    cmp currentPlayerTurn, 1        ; check if p1 turn
    je updatePlayer1Moves           ; if so, update p1 record
    mov ebx, OFFSET p2MoveRecord    ; else, load p2 record
    jmp updateMoves
    updatePlayer1Moves:
    mov ebx, OFFSET p1MoveRecord    ; load p1 record
    
    updateMoves: 
    mov ecx, 1
    mov [ebx + eax * 4], ecx          ; mark the move in the player's move record

    jmp turnComplete

    cellOccupied:
    mov edx, OFFSET occupiedError   ; move prompt to register for output
    call WriteString                ; output to consol
    call Crlf                       ; print new line
    jmp playTurn                    ; restart turn

    invalidInput:
    mov edx, OFFSET invalidPrompt   ; move prompt to register for output
    call WriteString                ; output to consol
    call Crlf                       ; print new line
    jmp playTurn                    ; restart turn

    turnComplete:
   ret
playTurn endp

switchPlayer proc
; Summary:
; Input: None
; Output: Switches the current player.
; Registers Used:
;   CurrentPlayerTurn (global variable) - holds the current player's turn (1 or 2)                                    ; Switch to the other player
    cmp currentPlayerTurn, 1        ; is it player 1 now?
    je switchToPlayer2              ; if yes, change to player 2
    mov currentPlayerTurn, 1        ; if not, set it to player 1
    jmp endSwitchPlayer             ; jump to the end of proc

    switchToPlayer2:
    mov currentPlayerTurn, 2        ; swith to player 2

    endSwitchPlayer:
    ret
switchPlayer endp

checkWin proc
; Summary:
; Input: None (checks if current player has a winning combination)
; Output: Displays winning message if a player wins.
; Registers Used:
;   ECX - Counter for the number of winning combinations
;   ESI - Pointer to the winning combinations
;   EAX, EBX, EDX - Index registers for checking player's moves
;   EDI - Pointer to the current player's move record
                                        ; Check if the current player has a winning combination
    mov ecx, 8                          ; number of winning combiniations
    mov esi, OFFSET winningCombinations ; load winning combinations into esi

    checkCombination:
    mov eax, [esi]                      ; load the first index of the combination
    mov ebx, [esi + 4]                  ; load the second index of the combination
    mov edx, [esi + 8]                  ; load the third index of the combination

                                        ; Check if all three indices are marked in the player's move array
    cmp currentPlayerTurn, 1            ; check if player 1 current
    je checkPlayer1Moves                ; check player 1 move record if current
    mov edi, OFFSET p2MoveRecord        ; else, check player 2 move record
    jmp checkMoves
    checkPlayer1Moves:
    mov edi, OFFSET p1MoveRecord        ; load player 1's move record into EDI

    checkMoves:
        mov eax, [edi + eax * 4]            ; Load the move record for the index in EAX
        test eax, eax                       ; Check if this position is occupied (not zero)
        jz notWinning                       ; If it's zero, jump to notWinning

        mov eax, [edi + ebx * 4]            ; Load the move record for the index in EBX
        test eax, eax                       ; Check if this position is occupied
        jz notWinning                       ; If it's zero, jump to notWinning

        mov eax, [edi + edx * 4]            ; Load the move record for the index in EDX
        test eax, eax                       ; Check if this position is occupied
        jz notWinning                       ; If it's zero, jump to notWinning

        jmp playerWins                      ; If all three indices are occupied, jump to playerWins

    notWinning:
        add esi, 12                         ; Move to the next set of winning indices
        loop checkCombination               ; Decrement ECX and loop back if not zero

    ret

playerWins:
    cmp currentPlayerTurn, 1        ; check if player1 turn
    je player1Win                   ; display p1 win if true
    mov edx, OFFSET p2WinMessage    ; else, load p2 win message
    jmp displayWin
    player1Win:
    mov edx, OFFSET p1WinMessage    ; load p1 win message

    displayWin:
    call WriteString                ; write message to consol
    ;jmp exitlabel                   ; exit the program
    
    ret
checkWin endp

exitLabel:                                ; Label for exiting the program
    push 0                                ; Push exit code (0) onto the stack
    call ExitProcess                      ; Call the ExitProcess procedure to exit the program
main endp                                 ; End of main procedure
end main                                  
