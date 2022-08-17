.file "src/game/game.s"
    
.global gameInit
.global gameLoop

.section .game.data
#strings
title_screen_string: .asciz "E n H A n C E d PONG"
names_string: .asciz "BY SANTIAGO DE HEREDIA & JAVIER PAEZ"
press_enter_string: .asciz "PRESS ENTER"
game_over_string: .asciz "GAME OVER!"
press_any_string: .asciz "PRESS ANY KEY TO CONTINUE..."
player_string: .asciz "PLAYER "
won_string: .asciz " WON!"
top_score_string: .asciz "TOP SCORE: "
main_string: .asciz "MAIN: "

#top score
top_score: .quad -1

#top score array
top_score_arr0: .quad 0
top_score_arr1: .quad 0

#random variable
random: .quad 0

#winner of round
winner: .quad 0

#player attributes
player_x: .quad 0
player_y: .quad 12
player_speed: .quad 4
player_width: .quad 2
player_length: .quad 10
player_lost: .quad 0
player_rounds_survived: .quad 0
player_key: .quad 0
main1: .quad 0

player2_x: .quad 78
player2_y: .quad 12
player2_lost: .quad 0
player2_rounds_survived: .quad 0
player2_key: .quad 0
main2: .quad 0

player_rounds_survived_arr0: .quad 0
player_rounds_survived_arr1: .quad 0
player2_rounds_survived_arr0: .quad 0
player2_rounds_survived_arr1: .quad 0


counter: .quad 0


#ball attributes
actual_ball_x: .quad 80
actual_ball_y: .quad 24
v_x: .quad -2
v_y: .quad 1
ball_x: .quad 40
ball_y: .quad 12
radius_x: .quad 3
radius_y: .quad 2
bounced_last: .quad -1

actual_ball2_x: .quad 100
actual_ball2_y: .quad 24
v2_x: .quad -2
v2_y: .quad 1
ball2_x: .quad 50
ball2_y: .quad 12
bounced_last2: .quad -1

#booleans: check if in end_screen or in title screen
end_screen: .quad 0
in_end_screen: .quad 0
title_screen: .quad 1

#input array
i0: .quad 0
i1: .quad 1

#number of balls flag
two_balls_flag: .quad 0

choose_velocity:
pair1: .quad 2, 1
pair2: .quad 2, -1
pair3: .quad -2, 1
pair4: .quad -2, -1
opair1: .quad 2, 1
opair2: .quad 2, -1
opair3: .quad -2, 1
opair4: .quad -2, -1
apair1: .quad 2, 1
apair2: .quad 2, -1
apair3: .quad -2, 1
apair4: .quad -2, -1
fastpair1: .quad 3, 2
fastpair2: .quad 3, -2
fastpair3: .quad -3, 2
fastpair4: .quad -3, -2


.section .game.text
format: .asciz "%ld"

gameInit:
    pushq %rbp
    movq %rsp, %rbp
    #set refresh rate to 60Hz 
    movq $19886, %rdi
    call setTimer

    #initalise random number
    #idea for choosing velocity: make random a number between 0 and 15 -> 16 choices
    #make a jump table with pairs for v_x and v_y. Then v_x = jumptable(2 * %rax), v_y = jumptable((2 * %rax) + 1)

    #initialise random velocities
    movq $0, %rdx
    movq random, %rax
    incq %rax
    addq player_rounds_survived, %rax
    movq %rax, random
    movq $16, %rdi
    divq %rdi
    shlq $4, %rdx   #shift once for proper index, 3 for .quad
    movq choose_velocity(%rdx), %rdi
    movq %rdi, v_x
    addq $8, %rdx
    movq choose_velocity(%rdx), %rdi
    movq %rdi, v_y

    #randomise if complementary or not, also randomise if two balls or not
    movq $0, %rdx
    movq random, %rax
    movq $2, %rdi
    divq %rdi
    movq %rdx, two_balls_flag
    cmpq $0, %rdx
    je not_complementary 

    #also, since this is a 1/2 chance, use this to set the two_balls_flag
    movq $0, %rdx
    movq random, %rax
    incq %rax   #if complementary, then %rax must be precisely one more

not_complementary:
    movq $16, %rdi
    divq %rdi
    shlq $4, %rdx   #shift once for proper index, 3 for .quad
    movq choose_velocity(%rdx), %rdi
    movq %rdi, v2_x
    addq $8, %rdx
    movq choose_velocity(%rdx), %rdi
    movq %rdi, v2_y

    #reset ball attributes
    movq $60, actual_ball_x
    movq $24, actual_ball_y
    movq $30, ball_x
    movq $12, ball_y
    movq $-1, bounced_last

    movq $100, actual_ball2_x
    movq $24, actual_ball2_y
    movq $50, ball2_x
    movq $12, ball2_y
    movq $-1, bounced_last2

    #reset player attributes
    movq $12, player_y
    movq $0, player_lost
    movq $0, player_rounds_survived

    movq $12, player2_y
    movq $0, player2_lost
    movq $0, player2_rounds_survived

    #reset screen states
    movq $0, end_screen
    movq $0, in_end_screen

#reset scores
    movq $0, player_lost
    movq $0, player2_lost

    movq %rbp, %rsp
    popq %rbp

    ret


gameLoop:
    pushq %rbp      #prologue
    movq %rsp, %rbp

    pushq %r12  #save callee-saved register onto the stack

    movq two_balls_flag, %r12 #have the two_balls_flag into %r12 for easy access

check_title:
    movq title_screen, %rdi
    cmpq $1, %rdi
    jne check_end

    call print_title_screen
    jmp screen_looping

check_end:
    movq end_screen, %rdi
    cmpq $0, %rdi
    je no_screen

    movq in_end_screen, %rdi
    cmpq $1, %rdi
    je screen_looping

    call print_over
    #indicate that we're already in the end screen
    movq $1, in_end_screen
    #finish game loop prematurely
    jmp end_game_loop

screen_looping:
    call readKeyCode    #wait for user to press a key, if user hasn't pressed a key, end gameloop
    cmpq $0, %rax
    je end_game_loop

    movq $0, title_screen   #we only want to show the title_screen once, so set title_screen to 0
    call gameInit       #when user has pressed key, initialise game again for a new round
                        #continue to game
no_screen:
    #get input
    call readKeyCode
    movq %rax, i0   #i0: first index of input array
    call readKeyCode
    movq %rax, i1   #i1: second index of input array

#handle player input/movement
    call handle_player_2
    call handle_player_1

handle_ball_movement:   #handle ball movement
    movq v_x, %rdi
    movq v_y, %rsi
    
    movq $2, %rcx   #move #2 for quick repeated divison

    addq %rdi, actual_ball_x
    addq %rsi, actual_ball_y

    movq $0, %rdx   #to have a higher refresh rate but not have the balls go too fast, we have a x2 scaled version
    movq actual_ball_x, %rax    #of the ball's position and we simply display it on (x//2, y//2).
    divq %rcx                   #this achieves smoother movement at the cost of a slightly glitchy ball
    movq %rax, ball_x           #changing to mode13h will solve this problem

    movq $0, %rdx
    movq actual_ball_y, %rax
    divq %rcx
    movq %rax, ball_y

    cmpq $1, %r12   #if two_balls_flag is not set, skip updating movement of ball2
    jne skip_movement_ball2

    movq v2_x, %rdi
    movq v2_y, %rsi

    addq %rdi, actual_ball2_x
    addq %rsi, actual_ball2_y

    movq $0, %rdx
    movq actual_ball2_x, %rax
    divq %rcx
    movq %rax, ball2_x

    movq $0, %rdx
    movq actual_ball_y, %rax
    divq %rcx
    movq %rax, ball2_y

skip_movement_ball2:
    call ball_collision_logic
draw:
    #clear screen
    movq $0, %r8
    movq $25, %rcx
    movq $80, %rdx
    movq $0, %rsi
    movq $0, %rdi
    call draw_rectangle

    #draw objects
    #draw player
    movq $255, %r8
    movq player_length, %rcx
    movq player_width, %rdx
    movq player_y, %rsi
    movq player_x, %rdi
    call draw_rectangle

    #draw player2
    movq $255, %r8
    movq player_length, %rcx
    movq player_width, %rdx
    movq player2_y, %rsi
    movq player2_x, %rdi
    call draw_rectangle

    #draw ball1
    movq $255, %r8
    movq radius_y, %rcx
    movq radius_x, %rdx
    movq ball_y, %rsi
    movq ball_x, %rdi
    call draw_rectangle

    cmpq $1, %r12   #if there's only one ball, skip drawing ball 2
    jne skip_draw_ball2

    #draw ball2
    movq $255, %r8
    movq radius_y, %rcx
    movq radius_x, %rdx
    movq ball2_y, %rsi
    movq ball2_x, %rdi
    call draw_rectangle

skip_draw_ball2:
    #print score numbers and their strings
    call print_scores

end_game_loop:
    popq %r12   #restore callee-saved register

    movq %rbp, %rsp #epilogue
    popq %rbp

    ret

#auxilary function definitions
draw_rectangle: #draws a rectangle with given x, y, width, height, color parameters
    pushq %rbp  #params: x,y,width,height,colour. Remember int8
    movq %rsp, %rbp

    pushq %r12  #push callee-saved registers onto the stack
    pushq %r13
    pushq %r14
    pushq %r15
    pushq %rbx

    movq %rdi, %r12 #x
    movq %rsi, %r13 #y
    movq %rdx, %r14 #width
    movq %rcx, %r15 #height
    movq %r8, %rbx  #colour

    movq $0, %rdi #i index variable

fori:
    cmpq %r14, %rdi #if index == the width of our rectangle, we are done
    je end_draw_rectangle

    movq $0, %rsi #j index variable
    jmp forj    #jump to nested j for loop

forj:
    cmpq %r15, %rsi
    je forj_ended

    pushq %rdi  #save indexes onto the stack
    pushq %rsi

    movq %rbx, %rcx 
    movq $32, %rdx
    addq %r12, %rdi #%rdi = x + i
    addq %r13, %rsi #%rsi = y + j
    call putChar

    popq %rsi   #recover indexes
    popq %rdi

    incq %rsi   #increment j, i.e j++
    jmp forj    #loop in nested j loop with next j

forj_ended:
    incq %rdi   #i++
    jmp fori    #loop with next i

end_draw_rectangle:
    popq %rbx   #recover callee-saved registers from the stack
    popq %r15
    popq %r14
    popq %r13
    popq %r12

    movq %rbp, %rsp #epilogue
    popq %rbp

    ret


ball_collision_logic:
    pushq %rbp
    movq %rsp, %rbp

    #calculate collision logic for each (ball, player) pair
    call ball1_collision_p1
    call ball1_collision_p2

    cmpq $1, %r12   #if there's only one ball, skip calculating collision logic for second ball
    jne skip_collision_ball2

    call ball2_collision_p1 #else, calculate collision logic for ball2
    call ball2_collision_p2

skip_collision_ball2:
    movq %rbp, %rsp
    popq %rbp

    ret


ball1_collision_p1:
    pushq %rbp
    movq %rsp, %rbp

    movq ball_x, %rdi   #move repeatedly used values into registers for easier access
    movq player_width, %rsi
    movq ball_y, %rdx
    movq player_length, %rcx
    movq bounced_last, %r9

b1p1_4:  #hit player
    cmpq %rdi, %rsi #ball_x <= player_width negation player_width < ball_x
    jl b1p1_0

    movq %rdx, %r8
    subq player_y, %r8  #r8 = ball_y - player_y
    cmpq %r8, player_length  #ball_y - player_y <= player_length, negation player_length < ball_y - player_y
    jl b1p1_0

    cmpq $0, %r8    #ball_y - player_y >= 0
    jl b1p1_0

    movq bounced_last, %r8
    cmpq $4, %r8    #bounced_last != 4
    je b1p1_0

    cmpq $0, %r8    #bounced_last != 0  to handle the ball colliding with the player and the wall at the same time
    je b1p1_0

    movq $-1, %r8   #else, the ball has collided with the player, so set v_x *= -1
    movq v_x, %rax
    mulq %r8
    movq %rax, v_x

    incq player_rounds_survived #if ball has been deflected, add this to their rounds survived

    movq $4, bounced_last   #set the ball's bounced last to the object bouncing off from

    jmp b1p1_end    #ignore other cases

b1p1_0:  #hit left wall
    cmpq $0, %rdi   #ball_x <= 0
    jg b1p1_1

    cmpq $0, %r9    #bounced_last != left wall
    je b1p1_1

    movq $-1, %r8   #else, the ball has collided with the left wall, so set v_x *= -1
    movq v_x, %rax
    mulq %r8
    movq %rax, v_x
    
    movq $0, bounced_last   #bouced_last = 0

    incq player_lost    #player_lost += 1, check if lost
    movq player_lost, %r8
    cmpq $2, %r8
    jle b1p1_end 

    movq $2, winner     #if player1 has lost the round, player2 is the winner
    movq $1, end_screen #set end_screen flag
    jmp b1p1_end

b1p1_1: #top wall
    cmpq $0, %rdx   #ball_y <= 0
    jg b1p1_2

    cmpq $1, %r9    #bounced_last != top wall
    je b1p1_2

    movq $-1, %r8   #else, the ball has collided with the top wall, so set v_y *= -1
    movq v_y, %rax
    mulq %r8
    movq %rax, v_y
    
    movq $1, bounced_last   #bouced_last = 1
    jmp b1p1_end 

b1p1_2:
    jmp b1p1_3  #we do not want to handle the right wall collision, as we first want to handle that with the player2

b1p1_3: #bottom wall
    movq %rdx, %r8
    addq radius_y, %r8  #r8 = ball_y + radius_y
    cmpq $25, %r8 #r8 >= screen height for collision
    jl b1p1_end 

    cmpq $3, %r9    #bounced_last != bottom wall
    je b1p1_end 

    movq $-1, %r8   #else, the ball has collided with the top wall, so set v_x *= -1
    movq v_y, %rax
    mulq %r8
    movq %rax, v_y

    movq $3, bounced_last

b1p1_end:
    movq %rbp, %rsp
    popq %rbp

    ret


ball1_collision_p2:
    pushq %rbp
    movq %rsp, %rbp

    movq ball_x, %rdi
    movq player_width, %rsi
    movq ball_y, %rdx
    movq player_length, %rcx
    movq bounced_last, %r9

b1p2_5:  #hit player
    cmpq $75, %rdi #ball_x <= player_width negation player_width < ball_x
    jl b1p2_2

    movq %rdx, %r8
    subq player2_y, %r8  #r8 = ball_y - player_y
    cmpq %r8, player_length  #ball_y - player_y <= player_length, negation player_length < ball_y - player_y
    jl b1p2_2

    cmpq $0, %r8    #ball_y - player_y >= 0
    jl b1p2_2

    movq bounced_last, %r8
    cmpq $5, %r8    #bounced_last != 5 (player)
    je b1p2_2

    cmpq $2, %r8    #bounced_last != 2  to handle the ball colliding with the player and the wall at the same time
    je b1p2_2

    movq $-1, %r8   #else, the ball has collided with the player, so set v_x *= -1
    movq v_x, %rax
    mulq %r8
    movq %rax, v_x

    incq player2_rounds_survived    #if ball has hit player, player has survived

    movq $5, bounced_last

    jmp b1p2_end

b1p2_2: #case 2: ball collides with right wall and has not collided with player 2
    movq %rdi, %r8
    addq radius_x, %r8  #r8 = ball_x + radius_x
    cmpq $80, %r8   #r8 >= screen width for collision
    jl b1p2_end

    cmpq $2, %r9
    je b1p2_end

    movq $-1, %r8   #else, the ball has collided with the right wall, so set v_x *= -1
    movq v_x, %rax
    mulq %r8
    movq %rax, v_x

    movq $2, bounced_last   #bouced_last = 2

    incq player2_lost   #right wall hit = player 2 has lost one more
    movq player2_lost, %r8  #check if player has lost
    cmpq $2, %r8
    jle b1p2_end 

    movq $1, winner #if player2 has lost, player1 is the winner
    movq $1, end_screen #set end_screen flag
    
b1p2_end:
    movq %rbp, %rsp
    popq %rbp

    ret

#same logic, but for ball2
ball2_collision_p1:
    pushq %rbp
    movq %rsp, %rbp

    movq ball2_x, %rdi  #move reused values to registers for easier access
    movq player_width, %rsi
    movq ball2_y, %rdx
    movq player_length, %rcx
    movq bounced_last2, %r9

b2p1_4:  #hit player
    cmpq %rdi, %rsi #ball2_x <= player_width negation player_width < ball2_x
    jl b2p1_0

    movq %rdx, %r8
    subq player_y, %r8  #r8 = ball2_y - player_y
    cmpq %r8, player_length  #ball2_y - player_y <= player_length, negation player_length < ball2_y - player_y
    jl b2p1_0

    cmpq $0, %r8    #ball2_y - player_y >= 0
    jl b2p1_0

    movq bounced_last2, %r8
    cmpq $4, %r8    #bounced_last2 != 4
    je b2p1_0

    cmpq $0, %r8    #bounced_last2 != 0  to handle the ball2 colliding with the playe and the wall at the same time
    je b2p1_0

    movq $-1, %r8   #else, the ball2 has collided with the player, so set v2_x *= -1
    movq v2_x, %rax
    mulq %r8
    movq %rax, v2_x

    incq player_rounds_survived

    movq $4, bounced_last2

    jmp b2p1_end 

b2p1_0:  #hit left wall
    cmpq $0, %rdi   #ball2_x <= 0
    jg b2p1_1

    cmpq $0, %r9
    je b2p1_1

    movq $-1, %r8   #else, the ball2 has collided with the left wall, so set v2_x *= -1
    movq v2_x, %rax
    mulq %r8
    movq %rax, v2_x
    
    movq $0, bounced_last2   #bouced_last = 0

    incq player_lost    #player_lost += 1, check if lost
    movq player_lost, %r8
    cmpq $2, %r8
    jle b2p1_end 

    movq $2, winner
    movq $1, end_screen

b2p1_1:
    cmpq $0, %rdx
    jg b2p1_2

    cmpq $1, %r9
    je b2p1_2

    movq $-1, %r8   #else, the ball2 has collided with the top wall, so set v2_x *= -1
    movq v2_y, %rax
    mulq %r8
    movq %rax, v2_y
    
    movq $1, bounced_last2   #bouced_last = 1
    jmp b2p1_end 


b2p1_2:
    jmp b2p1_3  #we do not want to handle the right wall collision, as we first want to handle that with the player2

b2p1_3:
    movq %rdx, %r8
    addq radius_y, %r8  #r9 = ball2_y + radius_y
    cmpq $25, %r8
    jl b2p1_end 

    cmpq $3, %r9
    je b2p1_end 

    movq $-1, %r8   #else, the ball2 has collided with the top wall, so set v2_x *= -1
    movq v2_y, %rax
    mulq %r8
    movq %rax, v2_y

    movq $3, bounced_last2

b2p1_end:
    movq %rbp, %rsp
    popq %rbp

    ret


ball2_collision_p2:
    pushq %rbp
    movq %rsp, %rbp

    movq ball2_x, %rdi
    movq player_width, %rsi
    movq ball2_y, %rdx
    movq player_length, %rcx
    movq bounced_last2, %r9

b2p2_5:  #hit player
    cmpq $75, %rdi #ball2_x <= player_width negation player_width < ball2_x
    jl b2p2_2

    movq %rdx, %r8
    subq player2_y, %r8  #r8 = ball2_y - player_y
    cmpq %r8, player_length  #ball2_y - player_y <= player_length, negation player_length < ball2_y - player_y
    jl b2p2_2

    cmpq $0, %r8    #ball2_y - player_y >= 0
    jl b2p2_2

    movq bounced_last2, %r8
    cmpq $5, %r8    #bounced_last2 != 5 (player)
    je b2p2_2

    cmpq $2, %r8    #bounced_last2 != 2  to handle the ball2 colliding with the player and the wall at the same time
    je b2p2_2

    movq $-1, %r8   #else, the ball2 has collided with the player, so set v2_x *= -1
    movq v2_x, %rax
    mulq %r8
    movq %rax, v2_x

    incq player2_rounds_survived

    movq $5, bounced_last2

    jmp b2p2_end

b2p2_2: #case 2: ball2 collides with right wall and has not collided with player 2
    movq %rdi, %r8
    addq radius_x, %r8  #r8 = ball2_x + radius_x
    cmpq $80, %r8
    jl b2p2_end

    cmpq $2, %r9        #bounced_last2 != right wall to prevent back and forth
    je b2p2_end

    movq $-1, %r8   #else, the ball2 has collided with the right wall, so set v2_x *= -1
    movq v2_x, %rax
    mulq %r8
    movq %rax, v2_x

    movq $2, bounced_last2   #bouced_last = 2

    incq player2_lost   #right wall hit = player 2 has lost one more
    movq player2_lost, %r8
    cmpq $2, %r8
    jle b2p2_end 

    movq $1, winner
    movq $1, end_screen
    
b2p2_end:
    movq %rbp, %rsp
    popq %rbp

    ret


handle_player_1:   
    pushq %rbp
    movq %rsp, %rbp

    movq player_speed, %rdi

    #check both indexes of keyboard buffer array and see if they're part of the player's movement
    #, if so, then update the player accordingly
    movq i0, %rax
    
    cmpq $'H', %rax
    jne check_h_i1
    subq %rdi, player_y #key H: go up = decrease y position
    jmp handle_player_1_end

check_h_i1:
    movq i1, %rax
    
    cmpq $'H', %rax
    jne check_p_key
    subq %rdi, player_y
    jmp handle_player_1_end

check_p_key:
    movq i0, %rax
    
    cmpq $'P', %rax
    jne check_p_i1
    addq %rdi, player_y #key P: go down = increase y position
    jmp handle_player_1_end

check_p_i1:
    movq i1, %rax
    
    cmpq $'P', %rax
    jne handle_player_1_end
    addq %rdi, player_y

handle_player_1_end:
    movq %rbp, %rsp
    popq %rbp

    ret


handle_player_2:
    pushq %rbp
    movq %rsp, %rbp

    movq player_speed, %rdi

    #check both indexes of keyboard buffer array and see if they're part of the player's movement
    #, if so, then update the player accordingly
    movq i0, %rax
    
    cmpq $'&', %rax
    jne check_and_i1
    subq %rdi, player2_y    #key &: go up = decrease y position 
    jmp handle_player_2_end

check_and_i1:
    movq i1, %rax
    
    cmpq $'&', %rax
    jne check_4_key
    subq %rdi, player2_y
    jmp handle_player_2_end

check_4_key:
    movq i0, %rax
    
    cmpq $'4', %rax
    jne check_4_i1
    addq %rdi, player2_y    #key 4: go down = increase y position
    jmp handle_player_2_end

check_4_i1:
    movq i1, %rax
    
    cmpq $'4', %rax
    jne handle_player_2_end
    addq %rdi, player2_y

handle_player_2_end:
    movq %rbp, %rsp
    popq %rbp

    ret


print_string:   #prints a given string with parameters (&string, x, y). String must be null-terminated
    pushq %rbp
    movq %rsp, %rbp

    pushq %r12  #save callee-saved registers onto the stack
    pushq %r13  
    pushq %r14
    pushq %r15

    movq %rdi, %r12 #string
    movq %rsi, %r13 #x
    movq %rdx, %r14 #y
    movq $0, %r15   #counter

print_string_loop:
    leaq (%r15, %r12), %rdi #load the pointer to the next character
    movb (%rdi), %dil   #dereference pointer
    cmpb $0, %dil   #see if char is null, if so, we have reached the end of the string
    je print_string_loop_end
                    
                    #_else, print the character along with its position
    movb $0x0f, %cl #character colour
    movb %dil, %dl  #character ascii code
    movq %r14, %rsi #y_char = y of string
    leaq (%r13, %r15), %rdi #x_char = x_initial + index of char
    call putChar

    incq %r15   #increase index

    jmp print_string_loop   #loop

print_string_loop_end:
    popq %r15   #restore callee-saved registers
    popq %r14
    popq %r13
    popq %r12

    movq %rbp, %rsp
    popq %rbp

    ret


check_top_score: #checks the rounds survived of each player and updates the top score accordingly.
    pushq %rbp
    movq %rsp, %rbp

    movq player_rounds_survived, %rdi
    cmpq top_score, %rdi
    jle check_player2_score #if the player's score is bigger than the top score, update it
                            #otherwise check for player 2
    movq %rdi, top_score

check_player2_score:
    movq player2_rounds_survived, %rdi  #check current top score and do the same as above
    cmpq top_score, %rdi
    jle end_top_score

    movq %rdi, top_score

end_top_score:
    movq %rbp, %rsp
    popq %rbp

    ret


convert_top_score_ascii:    #takes the top score and converts it to a series of ASCII codes
    pushq %rbp
    movq %rsp, %rbp

    movq $top_score_arr0, %rsi
    movq top_score, %rdi
    call convert_number_to_ascii

    movq %rbp, %rsp
    popq %rbp

    ret


convert_player_rounds_survived_ascii:   #helper function to convert the player_rounds_survived scores
                                        #into printable ASCII code arrays
    pushq %rbp
    movq %rsp, %rbp

    movq $player_rounds_survived_arr0, %rsi
    movq player_rounds_survived, %rdi
    call convert_number_to_ascii

    movq $player2_rounds_survived_arr0, %rsi
    movq player2_rounds_survived, %rdi
    call convert_number_to_ascii

    movq %rbp, %rsp
    popq %rbp

    ret


convert_number_to_ascii:    #params: a number and a pointer to an array
                            #returns the first two ASCII codes of the number to the array
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rdx   #clear %rdx for division
    movq %rdi, %rax

    movq $10, %rcx
    divq %rcx   #divide the top score by 10

    #rax = 10's digit , rdx = 1's digit, in ASCII codes
    addq $'0', %rax
    movq %rax, (%rsi)
    addq $'0', %rdx
    movq %rdx, 8(%rsi)  #move into array given in parameter

    movq %rbp, %rsp
    popq %rbp

    ret


print_scores:
    pushq %rbp
    movq %rsp, %rbp

    #draw MAIN: 
    movq $0, %rdx
    movq $0, %rsi
    movq $main_string, %rdi
    call print_string

    #main score for a given player = scored - been scored = player2_lost - player_lost
    #so if player_lost > player2_lost -> main = 0
    movq player2_lost, %r8
    subq player_lost, %r8
    cmpq $0, %r8    #if main is negative, set it to 0
    jge main_score1

    movq $0, %r8

main_score1:
    #main score for player 1
    movq $0x0f, %rcx
    movq $'0', %rdx
    addq %r8, %rdx  #third argument: code for main1 score
    movq $0, %rsi           #second argument: y
    movq $7, %rdi          #first argument: x
    call putChar

    movq player_lost, %r8
    subq player2_lost, %r8
    cmpq $0, %r8    #if main is negative, set it to 0
    jge main_score2

    movq $0, %r8
main_score2:
    #main score for player 2
    movq $0x0f, %rcx
    movq $'0', %rdx
    addq main1, %rdx  #third argument: code for main1 score
    movq $0, %rsi           #second argument: y
    movq $73, %rdi          #first argument: x
    call putChar

    #balls scored against player 1
    movq $0x0f, %rcx         #fourth argument, colour
    movq $'0', %rdx
    addq player_lost, %rdx  #third argument: code for player_lost char
    movq $1, %rsi           #second argument: y
    movq $7, %rdi          #first argument: x
    call putChar

    #balls scored against player 2
    movq $0x0f, %rcx         #fourth argument, colour
    movq $'0', %rdx
    addq player2_lost, %rdx  #third argument: code for player_lost char
    movq $1, %rsi           #second argument: y
    movq $73, %rdi          #first argument: x
    call putChar

    call convert_player_rounds_survived_ascii   #convert the player rounds survived scores into ASCII
                                                #codes stored in an array for each player

    #'balls deflected' player 1
    movq $0x0f, %rcx         #fourth argument, colour
    movq player_rounds_survived_arr0, %rdx  #third argument: code for player_lost char first digit
    movq $2, %rsi           #second argument: y
    movq $7, %rdi          #first argument: x
    call putChar

    movq $0x0f, %rcx         #fourth argument, colour
    movq player_rounds_survived_arr1, %rdx  #third argument: code for player_lost char second digit
    movq $2, %rsi           #second argument: y
    movq $8, %rdi          #first argument: x
    call putChar

    #'balls deflected' player 2
    movq $0x0f, %rcx         #fourth argument, colour
    movq player2_rounds_survived_arr0, %rdx  #third argument: code for player_lost char
    movq $2, %rsi           #second argument: y
    movq $73, %rdi          #first argument: x
    call putChar

    movq $0x0f, %rcx         #fourth argument, colour
    movq player2_rounds_survived_arr1, %rdx  #third argument: code for player_lost char
    movq $2, %rsi           #second argument: y
    movq $74, %rdi          #first argument: x
    call putChar

    movq %rbp, %rsp
    popq %rbp

    ret

print_over:
    pushq %rbp
    movq %rsp, %rbp

    #clear screen
    movq $255, %r8
    movq $25, %rcx
    movq $80, %rdx
    movq $0, %rsi
    movq $0, %rdi
    call draw_rectangle

    #print game over lines once
    #GAME OVER!
    movq $0, %rdx
    movq $0, %rsi
    movq $game_over_string, %rdi
    call print_string

    #PLAYER X WON!
    #PLAYER 
    movq $1, %rdx
    movq $0, %rsi
    movq $player_string, %rdi
    call print_string

    #prints 'X'
    movb $0x0f, %cl
    movq winner, %rdx
    addq $'0', %rdx #character of winner as character argument
    movq $1, %rsi
    movq $7, %rdi
    call putChar

    #WON!
    movq $1, %rdx
    movq $8, %rsi
    movq $won_string, %rdi
    call print_string

    call check_top_score    #checks if there has been a new top score and sets it

    #TOP SCORE: Y
    movq $2, %rdx
    movq $0, %rsi
    movq $top_score_string, %rdi
    call print_string

    #prints number of top score
    call convert_top_score_ascii

    movb $0x0f, %cl
    movq top_score_arr0, %rdx #character of first digit from left
    movq $2, %rsi
    movq $11, %rdi
    call putChar

    movb $0x0f, %cl
    movq top_score_arr1, %rdx #character of second digit from left
    movq $2, %rsi
    movq $12, %rdi
    call putChar

    #PRESS ANY KEY TO CONTINUE...
    movq $3, %rdx
    movq $0, %rsi
    movq $press_any_string, %rdi
    call print_string

    movq %rbp, %rsp
    popq %rbp

    ret


print_title_screen:
    pushq %rbp
    movq %rsp, %rbp

    #clear screen
    movq $255, %r8
    movq $25, %rcx
    movq $80, %rdx
    movq $0, %rsi
    movq $0, %rdi
    call draw_rectangle

    #print: 'EnHanCeD PONG'
    movq $10, %rdx
    movq $29, %rsi
    movq $title_screen_string, %rdi
    call print_string

    #print: 'BY SANTIAGO DE HEREDIA & JAVIER PAEZ'
    movq $11, %rdx
    movq $21, %rsi
    movq $names_string, %rdi
    call print_string

    movq %rbp, %rsp
    popq %rbp

    ret
