; Daniel Wilson
; Originally completed for:
; CSC 3000 X00 Advanced Computer Architecture
; 10/8/2024

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
                        DWORD 2, 4, 6          ; Diagonal 2
    
    pOneNamePrompt BYTE "Player 1, enter your name: ", 0      ; prompt for first player name
    pTwoNamePrompt BYTE "Player 2, enter your name: ", 0      ; prompt for second player name
    movePrompt BYTE ", enter your move: ", 0      ; prompt for second player move
    invalidPrompt BYTE "Invalid Input, Please Try Again", 0 ; error for invalid input
    occupiedError BYTE "That Cell Is Occupied Try Again", 0 ; error for occupied cell
    winMessage BYTE " Wins The Game!", 0          ; win message
    gameEndedMessage BYTE "The Game Has Ended.", 0          ; end game message
    gameInstructionsLOne BYTE "Welcome to Tic-Tac-Toe!", 0          ; game instructions line 1
    gameInstructionsLTwo BYTE "Players will take turns to place their marks (X for player 1 and O for Player 2) on a 3x3 grid.", 0 ; game instructions line 2
    gameInstructionsLThree BYTE "The first player to align three of their marks vertically, horizontally, or diagonally wins!", 0  ; game instructions line 3
    gameInstructionsLFour BYTE "Good luck!", 0                      ; game instructions line 4

    pOneName BYTE 20 DUP(0)              ; player one name
    pTwoName BYTE 20 DUP(0)              ; player two name
    currentPlayerTurn BYTE 1           ; store which player's turn it is, initialized to 1
    requestedMove DWORD ?               ; store requested move
    pOneMoveRecord DWORD 9 DUP(0)             ; array to track player 1's moves
    pTwoMoveRecord DWORD 9 DUP(0)             ; array to track player 2's moves
    gameActive BYTE 1                       ; is the game ended? 1 or 0
    ; DEBUG DATA
    debugText BYTE "--- Debug Data ---", 0              ; debug message
    p1MoveDebug BYTE "Player 1 move record: ", 0        ; debug message
    p2MoveDebug BYTE "Player 2 move record: ", 0        ; debug message
    oneMessage BYTE "1", 0                              ; char for debug
    zeroMessage BYTE "0", 0                             ; char for debug
    commaMessage BYTE ", ", 0                           ; char for debug


.code
main proc
startGame:
    call displayInstructions
    call displayGrid
    call collectNames

gameLoop:
    call playTurn
    call Clrscr
    call displayGrid
    ;call debugOutput
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
    mov edx, OFFSET pOneNamePrompt      ; load prompt into edx for output
    call WriteString                    ; display prompt to consol
    mov edx, OFFSET pOneName            ; load the address to store name
    mov ecx, SIZEOF pOneName            ; load size of string (20 byte max)
    call ReadString                     ; collect input
                                        ; PLAYER 2
    mov edx, OFFSET pTwoNamePrompt      ; load prompt into edx for output
    call WriteString                    ; display prompt to consol
    mov edx, OFFSET pTwoName            ; load the address to store name
    mov ecx, SIZEOF pTwoName            ; load size of string (20 byte max)
    call ReadString                     ; collect input
    ret
collectNames endp

playTurn proc
; Summary:
; Input: Move input
; Output: Updates the grid with the player's move or prompts for a valid move.
;         Updates each player's move record.
; Registers Used:
;   EAX - Holds the converted move index
;   EBX - Pointer to the lookup table or player move record
;   ECX - Max input length for player input
;   EDX - Pointer to prompt strings or move record 
;   ESI - Stores copy of unmodified requested index for move record
cmp gameActive, 0                   ; check if game is still active
je gameAlreadyEnded                 ; if not active, jump to message
                                    ; collect player input
    cmp currentPlayerTurn, 2        ; is it player 2's turn?
    je promptPlayer2                ; if yes, display player 2 prompt

   promptPlayer1:
   mov edx, OFFSET pOneName           ; move p1 name to register for display
   call WriteString                 ; display name
   mov edx, OFFSET movePrompt       ; move prompt to register for display
   call WriteString                 ; display prompt
   jmp promptComplete               ; skip over player 2 prompt

   promptPlayer2:
   mov edx, OFFSET pTwoName           ; move p2 name to register for display
   call WriteString                 ; display name
   mov edx, OFFSET movePrompt       ; move prompt to register for display
   call WriteString                 ; display prompt

   promptComplete:                  ; continue to collect input
    
                                    ; COLLECT MOVE INPUT
   mov edx, OFFSET requestedMove    ; store move in requestedMove variable
   mov ecx, 2                       ; max input length (1 digit + null term)
   call ReadInt

                                    ; Validate the input (0-9)
    cmp eax, 1                      ; compare to 1
    jl invalidInput                 ; error if less than 1
    cmp eax, 9                      ; compare to 9
    jg invalidInput                 ; error if greater than 9

    mov esi, eax                    ; copy unmodified index to esi
    dec esi                         ; convert 1 based input to 0 based index

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
    mov ebx, OFFSET pTwoMoveRecord    ; else, load p2 record
    jmp updateMoves
    updatePlayer1Moves:
    mov ebx, OFFSET pOneMoveRecord    ; load p1 record
    
    updateMoves: 
    mov ecx, 1
    mov [ebx + esi * 4], ecx          ; mark the move in the player's move record

    jmp turnComplete

    gameAlreadyEnded:
    call displayGameEndedMessage    ; display end game message
    exit

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
   mov ecx, 8                           ; Number of winning combinations
    mov esi, OFFSET winningCombinations ; Pointer to winning combinations

checkWinCombination:
                                        ; Load the indices of the current winning combination
    mov eax, [esi]                      ; First index
    mov ebx, [esi + 4]                  ; Second index
    mov edx, [esi + 8]                  ; Third index

                                        ; Check if all three indices are marked in the current player's move record
    cmp currentPlayerTurn, 1            ; Check if player 1's turn
    je checkPlayer1Moves                ; If so, check player 1's moves
    mov edi, OFFSET pTwoMoveRecord      ; Otherwise, check player 2's moves
    jmp checkMoves

checkPlayer1Moves:
    mov edi, OFFSET pOneMoveRecord      ; Load player 1's move record into EDI

checkMoves:
                                        ; Check each position for occupancy
    mov eax, [edi + eax * 4]            ; Load first move record
    test eax, eax                       ; Check if it is occupied
    jz notWinning                       ; If zero (not occupied), jump to notWinning

    mov eax, [edi + ebx * 4]            ; Load second move record
    test eax, eax                       ; Check if it is occupied
    jz notWinning                       ; If zero (not occupied), jump to notWinning

    mov eax, [edi + edx * 4]            ; Load third move record
    test eax, eax                       ; Check if it is occupied
    jz notWinning                       ; If zero (not occupied), jump to notWinning

                                        ; If all three indices are occupied, the player wins
    jmp playerWins                      ; Jump to player wins

notWinning:
    add esi, 12                         ; Move to the next set of winning indices (3 indices * 4 bytes each)
    loop checkWinCombination            ; Decrement ECX and loop if not zero

    ret                                 ; Return if no player has won

playerWins:
                                        ; Set game state to inactive
    mov gameActive, 0
                                        ; Determine and display the winning message
    cmp currentPlayerTurn, 1            ; Check if it is player 1
    je player1Win                       ; If yes, jump to player 1 win message
    mov edx, OFFSET pTwoName            ; Otherwise, load player 2 name
    jmp displayWin

player1Win:
    mov edx, OFFSET pOneName            ; Load player 1 name

displayWin:
    call WriteString                    ; Display the winner's name
    mov edx, OFFSET winMessage          ; move win message to register
    call WriteString                    ; write to consol
    ret                                 ; Return to the main loop or end the game

checkWin endp

displayGameEndedMessage proc
    call Crlf                           ; print new line
    mov edx, OFFSET gameEndedMessage    ; set message pointer
    call WriteString                    ; output message
    ret
displayGameEndedMessage endp

debugOutput proc
; Summary:
; This procedure prints Player 1's and Player 2's move records to the console.
; Input: None
; Output: move record values.
; Registers Used:
;   EAX - Loop index for accessing move records
;   ECX - Counter for the loop
;   EDX - Pointer to the move record

    mov edx, OFFSET debugText       ; Load debug title to register
    call WriteString                ; Print to Console

                                    ; Set up for output for Player 1
    mov edx, OFFSET p1MoveDebug     ; Load the debug message prompt for Player 1
    call WriteString                ; Display the prompt
    call Crlf                       ; New line

    mov ecx, 9                      ; Set loop counter (9 moves)
    mov ebx, OFFSET pOneMoveRecord    ; Load the address of pOneMoveRecord

printPlayer1Moves:
    mov eax, [ebx]                  ; Load the current move record value for Player 1
    cmp eax, 0                      ; Check if the move record is occupied
    je printZero1                   ; If zero, print "0"
    
    ; If occupied, print "1"
    mov edx, OFFSET oneMessage      ; oneMessage contains "1"
    call WriteString                ; Display "1"
    jmp printComma1                 ; Jump to print comma

printZero1:
    mov edx, OFFSET zeroMessage     ; zeroMessage contains "0"
    call WriteString                ; Display "0"

printComma1:
    mov edx, OFFSET commaMessage    ; commaMessage contains ", "
    call WriteString                ; Display comma and space

    add ebx, 4                      ; Move to the next DWORD in the record
    loop printPlayer1Moves          ; Loop until all moves are printed

    call Crlf                       ; New line after printing Player 1's moves

                                    ; Set up for output for Player 2
    mov edx, OFFSET p2MoveDebug     ; Load the debug message prompt for Player 2
    call WriteString                ; Display the prompt
    call Crlf                       ; New line

    mov ecx, 9                      ; Reset loop counter (9 moves)
    mov ebx, OFFSET pTwoMoveRecord    ; Load the address of pTwoMoveRecord

printPlayer2Moves:
    mov eax, [ebx]                  ; Load the current move record value for Player 2
    cmp eax, 0                      ; Check if the move record is occupied
    je printZero2                   ; If zero, print "0"
    
    ; If occupied, print "1"
    mov edx, OFFSET oneMessage      ; oneMessage contains "1"
    call WriteString                ; Display "1"
    jmp printComma2                 ; Jump to print comma

printZero2:
    mov edx, OFFSET zeroMessage     ; zeroMessage contains "0"
    call WriteString                ; Display "0"

printComma2:
    mov edx, OFFSET commaMessage    ; commaMessage contains ", "
    call WriteString                ; Display comma and space

    add ebx, 4                      ; Move to the next DWORD in the record
    loop printPlayer2Moves          ; Loop until all moves are printed

    call Crlf                       ; New line
    ret
debugOutput endp


; Summary:
; This procedure prints the instructions for the game.
; Input: None
; Output: instructions for game
; Registers Used:
;   EDX - Used for printing messages to consol.
displayInstructions proc
    mov edx, OFFSET gameInstructionsLOne    ; load string to register
    call WriteString                        ; print string
    call Crlf                               ; print new line
    mov edx, OFFSET gameInstructionsLTwo    ; load string to register
    call WriteString                        ; print string
    call Crlf                               ; print new line
    mov edx, OFFSET gameInstructionsLThree  ; load string to register
    call WriteString                        ; print string
    call Crlf                               ; print new line
    mov edx, OFFSET gameInstructionsLFour   ; load string to register
    call WriteString                        ; print string
    call Crlf                               ; print new line
    ret
displayInstructions endp


exitLabel:                                ; Label for exiting the program
    push 0                                ; Push exit code (0) onto the stack
    call ExitProcess                      ; Call the ExitProcess procedure to exit the program
main endp                                 ; End of main procedure
end main                                  
