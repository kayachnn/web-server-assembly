.intel_syntax noprefix

.global _start

.section .data
	.asciz "0.0.0.0"
	.asciz "HTTP/1.0 200 OK\r\n\r\n"

.section .text

_start:
	push rbp
	mov rbp,rsp
	sub rsp, 0x28

#size of sockaddr_in
	mov QWORD PTR [rbp-0x28], 16

	xor rax, rax
#set [rbp-0x18] to [rbp-0x8] for sockaddr_in for local addr which is 16 bytes
	mov rdi, rbp
	sub rdi, 0x18 #first parameter to memset src
	xor rsi, rsi #second parameter to memset c
	mov rdx, 0x10 #third parameter size
	call memset
#---------------
#set [rbp-20] to [rbp-0x18] for sockaddr_in for remote addr 16 bytes
	mov rdi, rbp
	sub rdi, 0x20
	xor rsi, rsi
	mov rdx, 0x10
	call memset
#---------------
#create sockaddr_in struct on the stack
	xor rax, rax
	mov al, 0x02 #AF_INET for sin_family
	mov WORD PTR [rbp-0x18], ax
#call htons for port 80
	mov rdi, 80
	call htons
	mov WORD PTR [rbp-0x16], ax
#call inet_addr("0.0.0.0")
	xor rdi, rdi
	lea rdi, [address]
	xor rax, rax
	call inet_addr
	mov DWORD PTR [rbp-0x14], eax #4 byte sin_addr in memory
	
	call create_socket
	mov [rbp-0x8], rax #file descriptor from socket()

#call bind
	mov rdi, rax #sock fd
	mov rsi, rbp #pass second parameter as the address to sockaddr_in
	sub rsi, 0x18
	mov rdx,  0x10 #size of sockaddr_in
	mov rax, 49 #SYS_bind
	syscall
	cmp rax, 0
	jne exit

#call listen
	mov rdi, QWORD PTR [rbp-0x8]
	mov rsi, 0
	mov rax, 50
	syscall. #SYS_listen
	cmp rax, 0
	jne exit


#call accept
	xor rax, rax
	mov rdi, QWORD PTR [rbp-0x8]
	mov rsi, rbp # address of the remote addr
	sub rsi, 0x20
	mov rdx, rbp #address of the size of sockaddr_in for remote
	sub rdx, 0x28
	mov rax, 43 #SYS_accept
	syscall

	jmp exit

create_socket:
	push rbp
	mov rbp, rsp
	mov rdi, 2 #AF_INET
	mov rsi, 1 #SOCK_STREAM
	mov rdx, 0 #IPPROTO_IP
	mov rax, 41 #SYS_socket
	syscall
	mov rsp, rbp
	pop rbp
	ret



bind_socket:
	push rbp
	mov rbp, rsp

	pop rbp
	mov rsp, rbp
	ret

exit:
	mov rax, 60
	mov rdi, 0
	syscall

