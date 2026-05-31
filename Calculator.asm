section .data

    remainder_storage db 0,0,0,0,0,0,0,0
    remainder_storage_len equ $ - remainder_storage

    error_operation db 'Ошибка:Аргументе Операций можно выбрать только +,-,*,/', 10
    error_operation_len equ $ - error_operation

    error_args db 'Ошибка: Недостаточно аргументов для запуска программы', 10, '(1 аргумент = первое число, 2 аргумент = второе число, 3 аргумент = операция(+,-,*,/))', 10
    error_args_len  equ $ - error_args

    error_div_0 db 'Ошибка: Нельзя делить на 0', 10
    error_div_0_len  equ $ - error_div_0

    ERROR_ARGS equ 1
    ERROR_OPERATION equ 2
    ERROR_DIV_0 equ 3

section .text
global _start
_start:

    mov rdi,[rsp]

    cmp rdi, 4
    jb .error_args 

    mov rdi,[rsp + 16]
    mov rsi, 10
    xor rax,rax

    call .trasform_args_in_digit

    mov r9, rax
    mov rdi,[rsp + 24]
    xor rax,rax

    call .trasform_args_in_digit

    mov r10, rax
    xor rax,rax 

    mov rdi, [rsp + 32]
    mov r11b, [rdi]

    mov rdi, r9
    mov rsi, r10
    mov dl, r11b

    ;rdi = primary number
    ;rsi = secondary number
    ;dl = operation
    ;rax = result  
    call .urls_dispatcher_operation

    mov r15,rax

    mov rsi, 10
    mov rdi, r15
    mov rbx, remainder_storage 
    mov rcx, remainder_storage_len

    call .trasform_digits_in_text

    mov rdi, remainder_storage
    mov rsi, remainder_storage_len

    call .system_call_for_write

    mov rax, 60
    mov rdi, 0
    syscall 

.system_call_for_write:
    mov rdx, rsi
    mov rsi, rdi

    mov rax, 1
    mov rdi, 1
    syscall
    ret

.trasform_args_in_digit:
    movzx r15,byte [rdi]

    test r15,r15

    jz .done 

    sub r15, 48
        
    cmp r15,10
    jae .error_get_text_in_args 

    mul rsi
    add rax, r15
    inc rdi

    jmp .trasform_args_in_digit

    .done:
        ret

    .error_get_text_in_args: ; <----- надо сделать 
        ret

.trasform_digits_in_text:

    mov rax, rdi

    call .handler_trasform_digits_in_text
    ret

.handler_trasform_digits_in_text:
    xor rdx, rdx
    div rsi

    add rdx, 48

    dec rcx
    mov [rbx + rcx], dl 

    cmp rax, 0
    je .return

    cmp rcx, 0
    je .return

    jmp .handler_trasform_digits_in_text

    .return:
        ret


;rdi = primary number
;rsi = secondary number
;rdx = operation
;rax = result

.urls_dispatcher_operation:

    cmp dl, '+'
    je .add
    cmp dl, '-'
    je .sub
    cmp dl, '*'
    je .mul
    cmp dl, '/'
    je .div

    jmp .error_operation 

    .sub:
        call .sub_handler
        ret
    .add:
        call .add_handler
        ret
    .mul:
        call .mul_handler
        ret
    .div:
        call .div_handler 
        ret

    .add_handler:
        xor rdx,rdx
        add rdi,rsi
        mov rax,rdi
        ret
        
    .sub_handler:
        xor rdx,rdx
        sub rdi,rsi
        mov rax,rdi
        ret
        
    .mul_handler:
        xor rdx,rdx
        mov rax, rdi
        mul rsi
        ret
        
    .div_handler:
        cmp rsi, 0
        je .error_div_0

        xor rdx,rdx
        mov rax,rdi
        div rsi
        ret
    
.error_operation:
    mov rdi, ERROR_OPERATION
    jmp .dispatcher_error

.error_args:
    mov rdi, ERROR_ARGS
    jmp .dispatcher_error

.error_div_0:
    mov rdi, ERROR_DIV_0
    jmp .dispatcher_error

.dispatcher_error:
    cmp rdi, ERROR_ARGS
    je .configure_args_error

    cmp rdi, ERROR_OPERATION
    je .configure_operation_error

    cmp rdi, ERROR_DIV_0
    je .configure_div_0_error

.configure_args_error:
    mov rsi, error_args
    mov rdx, error_args_len
    jmp .write_error

.configure_div_0_error:
    mov rsi, error_div_0
    mov rdx, error_div_0_len
    jmp .write_error

.configure_operation_error:
    mov rsi, error_operation
    mov rdx, error_operation_len
    jmp .write_error
    
.write_error:

    mov rax, 1
    mov rdi, 1
    syscall

    mov rax, 60
    mov rdi, 0
    syscall 