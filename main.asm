# Program #9: Number Base Converter
# Author: Lazlo F. Steele
# Due Date : Nov. 2, 2024 Course: CSC2025-2H1
# Created: Oct. 20, 2024
# Last Modified: Nov. 2, 2024
# Functional Description: Given a 32-bit numeric value provided by the user, convert from base 2/10/16 to base 2/10/16.
# Language/Architecture: MIPS 32 Assembly
####################################################################################################
# Algorithmic Description:
#	
####################################################################################################

.data
	welcome_msg:.asciiz "\nGreetings. I am numberbot. I will convert numerical bases."
	mode_msg:	.asciiz	"\nPlease choose my mode from the options below:\n	[1] Decimal\n	[2] Binary\n	[3] Hex\n	[4] Exit"
	mode_prmpt: .asciiz "\nPlease enter the number for the mode you would like > "
	decimal_msg:.asciiz "\nPlease enter an integer between -2147483648 and 2147483647 > "
	binary_msg:	.asciiz "\nPlease enter a 32-bit binary number (32 characters long) > "
	hex_msg:	.asciiz "\nPlease enter a 32-bit hexadecimal number (8 characters long) > "
	dec_value_msg:	.asciiz "\nDecimal Value:		"
	bin_value_msg:	.asciiz "\nBinary Value:		"
	hex_value_msg:	.asciiz "\nHexadecimal Value:	"
	invalid_msg:.asciiz "\nInvalid input. Try again!\n"
	bye: 		.asciiz "Toodles! ;)"
	hex_digits: .asciiz "0123456789ABCDEF" 
	space: 		.ascii	" "
	newline: 	.asciiz "\n"

	min_signed:	.word -2147483648
	max_signed:	.word 2147483647
	dec_value:	.word

	mode_flag:	.byte 0		# 0 - off, 1 - integer, 2 - binary, 3 - hex, 4 - exit
	
				.align 2
	buffer:		.space 33

.globl	main

.text
####################################################################################################
# function: main
# purpose: to control program flow
####################################################################################################
main:							#
	jal	welcome					# welcome the user
								#
	jal	get_mode				# prompt for the mode
	jal	reset_buffer			# clear the buffer
								#
	jal get_number				# prompt for the number to be calculated
								#
	jal print_dec				# print the decimal value
	jal print_bin				# print the binary value
	jal print_hex				# print the hex value
								#
	j	re_enter				# clear the buffer and re-enter the main loop
								#
####################################################################################################
# function: welcome
# purpose: to welcome the user to our program
# registers used:
#	$v0 - syscall codes
#	$a0 - passing arugments to subroutines
#	$ra	- return address
####################################################################################################	
welcome:						# 
	la	$a0, welcome_msg		# load welcome message
	li	$v0, 4					# 
	syscall						# and print
								#
	jr $ra						# return to caller
								#
####################################################################################################
# function: get_mode
# purpose: to map application state to user input
# registers used:
#	$v0 - syscall codes
#	$a0 - passing arugments to subroutines
#	$a1 - buffer lengths
#	$t0 - buffer address
#	$t1 - first character of user input
#	$t2 - comparator values
#	$ra - return address
####################################################################################################
get_mode:						#
	la	$a0, mode_msg			# load message
	li	$v0, 4					#
	syscall						# print
								#
	la	$a0, mode_prmpt			# load message
	syscall						# print
								#
	mode_input:					#
		la 	$a0, buffer			# load buffer
		li	$a1, 33				# 32 characters plus null terminator
		li	$v0, 8				# 
		syscall					# and read to buffer
								#
	lb	$t1, 0($a0)				# load first byte from buffer
								#
	li	$t2, '1'				# 
	blt $t1, $t2, invalid_mode	# if it is less than '1' then invalid
	li	$t2, '4'				#
	bgt $t1, $t2, invalid_mode	# if it is greater than '4' then invalid
								#
	addi $t1, $t1, -48			# subtract '0' to store as integer in flag
								#
	la	$t2, mode_flag			# load the flag address
	sb	$t1, 0($t2)				# store the flag value
								#
	jr $ra						# return to caller
								#
	invalid_mode:				#
		la	$a0, invalid_msg	# 
		li	$v0, 4				#
		syscall					# print invalid message
								#
		j get_mode				# try again!
								#
####################################################################################################
# function: get_number
# purpose: to get a user sourced string as either decimal, binary, or hex
# registers used:
#	$v0 - syscall codes
#	$a0 - passing arugments to subroutines
#	$a1 - buffer size
#	$t0 - mode flag
####################################################################################################
get_number:						#
	lb 	$t0, mode_flag			# what's the mode???
								#
	beq $t0, 1, get_decimal		# go to the right one based on flag
	beq $t0, 2, get_binary		#
	beq $t0, 3, get_hex			#
	beq	$t0, 4, end				#
								#
	get_decimal:				# 
		la	$a0, decimal_msg	# 
		li	$v0, 4				#
		syscall					# print prompt
								#
		la 	$a0, buffer			#
		li	$a1, 33				#
		li	$v0, 8				#
		syscall					# get input
								#
		j	process_decimal		# process input as decimal
	get_binary:					#
		la	$a0, binary_msg		# 
		li	$v0, 4				#
		syscall					# print prompt
								#
		la 	$a0, buffer			#
		li	$a1, 33				#
		li	$v0, 8				#
		syscall					# get input
								#
		j	process_binary		# process input as binary
	get_hex:					#
		la	$a0, hex_msg		#
		li	$v0, 4				#
		syscall					# print prompt
								#
		la 	$a0, buffer			#
		li	$a1, 33				#
		li	$v0, 8				#
		syscall					# get input
								#
		j	process_hex			# process input as hex
								#
####################################################################################################
# function: process_decimal
# purpose: to convert a string of decimals into a decimal integer
# registers used:
#	$v0 - syscall codes
#	$a0 - passing arugments to subroutines
#	$t0 - integer value
#	$t1 - positive/negative flag
#	$t2 - buffer address
#	$t3 - working character
#	$t4 - comparator values ('-', '0', '9')
#	$ra - return address
####################################################################################################	
process_decimal:							#
	li $t0, 0               	        	# $t0 will hold the final integer value
	li $t1, 0								# $t1 is a flag for sign (0 = positive, 1 = negative)
	la $t2, buffer							# $t2 points to the current character in buffer
	li $t4, '-'								# to check for negative
											#
	lb $t3, 0($t2)							# load the first character
	beq $t3, $t4, check_negative			# if it's '-', set negative flag
	j process_digits						# if no sign, process digits directly
											#
	check_negative:							#
		li $t1, 1							# set negative flag
		addi $t2, $t2, 1					# move to next character
		j process_digits					#
											#
	process_digits:							#
		lb $t3, 0($t2)                  	# load the next character
		beq $t3, 10, finalize_conversion	# end of string (null terminator)
		blt $t3, '0', invalid_integer		# if character is not a digit, go to error
		bgt $t3, '9', invalid_integer		# if character is not a digit, go to error
											#
		sub $t3, $t3, '0'					# $t3 = character - '0' to get integer value
		mul $t0, $t0, 10					# shift existing number left by one decimal place
		add $t0, $t0, $t3					# add the new digit to the result
											#
		addi $t2, $t2, 1					# move to next character
		j process_digits					#
											#
	finalize_conversion:					#
		beq $t1, 1, make_negative			# if flag raised, go to make_negative
		j check_overflow					# check if it's an overflow
											#
	make_negative:							#
		sub $t0, $zero, $t0					# invert the value: $t0 = 0 - $t0
											#
	check_overflow:							#
		la $t4, min_signed					# minimum 32-bit signed integer value
		lw $t4, ($t4)						#
		blt $t0, $t4, invalid_integer		# check if result is too low
		la $t4, max_signed					# maximum 32-bit signed integer value
		lw $t4, ($t4)						#
		bgt $t0, $t4, invalid_integer		# check if result is too high
											#
	sw	$t0, dec_value						# store the final integer in $s1
	jr	$ra									# return to caller
											#
	invalid_integer:						#
		la $a0, invalid_msg					#
		li $v0, 4							#
		syscall								#
											#
		j	get_decimal						#
											#
####################################################################################################
# function: process_binary
# purpose: to convert binary string to decimal integer
# registers used:
#	$v0 - sycall codes
#	$a0 - passing arugments to subroutines
#	$t0 - output value
#	$t1 - buffer address
#	$t2 - working character
#	$t3 - comparator values, and 1's for the binary values
#	$ra - return address
####################################################################################################
process_binary:								#
	li	$t0, 0								# initialize integer output
	la	$t1, buffer							#
											#
	bin_to_dec_loop:						#
		lb		$t2, 0($t1)					#
		beq		$t2, 10, bin_done			# when end of loop, you are done
		beq		$t2, 0, bin_done			#
											#
		li 		$t3, '0'					# for comparator
		blt		$t2, $t3, invalid_binary	# if greater than '0' invalid
		beq 	$t2, $t3, next_byte			# if 0 then skip
											#
		li		$t3, '1'					#
		bgt		$t2, $t3, invalid_binary	# if greater than '1' invalid
		li		$t3, 1						# 
											#
		j add_value							#
											#
		next_byte:							#
			li		$t3, 0					# reset the value of the bit for next iteration
											#
		add_value:							#
			sll 	$t0, $t0, 1				# to the left, to the left
			add 	$t0, $t0, $t3			# every value you have in the bit to the left
											#
			addi 	$t1, $t1, 1				# buffer++
			j 		bin_to_dec_loop			# and again!
											#
	bin_done:								#
		sw	$t0, dec_value					# store the value
		jr	$ra								# return to caller
											#
	invalid_binary:							#
		la $a0, invalid_msg					#
		li $v0, 4							#
		syscall								# print invalid
											#
		j	get_binary						# and try again!
											#
####################################################################################################
# function: process-hex
# purpose: to convert hexadecimal string to decimal integer
# registers used:
# registers used:
#	$v0 - sycall codes
#	$a0 - passing arugments to subroutines
#	$t0 - output value
#	$t1 - buffer address
#	$t2 - working character
#	$t3 - comparator values ('0', '9', 'A', 'F', 'a', 'f')
#	$t4 - iterator to only allow the first 8 bytes... hacky and crappy but it is what it is...
#	$ra - return address
####################################################################################################	
process_hex:								#
	li	$t0, 0								# initialize integer output
	la	$t1, buffer							#
	li	$t4, 8								# hacky iterator to only accept first 8 characters of input
											#
	hex_to_dec_loop:						#
		beqz	$t4, hex_done				#
		lb		$t2, 0($t1)					#
		beq		$t2, 10, hex_done			# when null terminator check sign
											#
		li 		$t3, '0'					#
		blt 	$t2, $t3, invalid_hex		# If character is below '0', not hex
		li 		$t3, '9'					#
		ble 	$t2, $t3, convert_digit		# If '0' <= character <= '9' we good!
											#
		li 		$t3, 'A'					# 
		blt 	$t2, $t3, invalid_hex		# If '9' < character < 'A' invalid
		li 		$t3, 'F'					#
		ble 	$t2, $t3, convert_digit		# If 'A' <= character <= 'F' we good!
											#
		li 		$t3, 'a'					# If 'F' < character < 'a' invalid
		blt 	$t2, $t3, invalid_hex		#
		li 		$t3, 'f'					#
		ble 	$t2, $t3, convert_digit		# If 'a' <= character <= 'f' we good!
											#
		j		invalid_hex					# otherwise it's invalid
											#
		convert_digit:						# thanks Stack Overflow user paxdiablo for the algorithm inspo
			addi	$t2, $t2, -48			# subtract ascii '0' to get decimal digits
			blt		$t2, 10, add_hex		# if it is a decimal we are good!
			addi	$t2, $t2, -7			# bring ascii A-F down to 10-15
			blt		$t2, 16, add_hex		# if it is hex we are good!
			addi	$t2, $t2, -32			# bring ascii a-f down to 10-15
											#
	add_hex:								#
		sll $t0, $t0, 4						# move left by a nibble
		add $t0, $t0, $t2					# add the digit!
											#
		addi 	$t1, $t1, 1					#
		addi	$t4, $t4, -1				# iterate it!
		j hex_to_dec_loop					#
											#
	hex_done:								#
		sw	$t0, dec_value					# store the value
		jr	$ra								# return to caller!
											#
	invalid_hex:							#
		la $a0, invalid_msg					# 
		li $v0, 4							#
		syscall								# print invalid message
											#
		j	get_hex							# try again!
											#
####################################################################################################
# function: print_dec
# purpose: to print a decimal
# registers used:
#	$v0 - sycall codes
#	$a0 - passing arugments to subroutines
#	$t0 - output value
#	$ra - return address
####################################################################################################
print_dec:									#
	la	$a0, dec_value_msg					# 
	li	$v0, 4								#
	syscall									# print the message
											#
	la	$t0, dec_value						#
	lw	$a0, 0($t0)							#
	li	$v0, 1								#
	syscall									# print the integer
											#
	jr	$ra									# return to caller
											#
####################################################################################################
# function: print bin
# purpose: to print a binary
# registers used:
#	$v0 - sycall codes
#	$a0 - passing arugments to subroutines
#	$t0 - iterator
#	$t1 - decimal value
#	$t2 - shifted/masked value
#	$ra - return address
####################################################################################################
print_bin:									#
	la	$a0, bin_value_msg					#
	li	$v0, 4								#
	syscall									#
											#
	li	$t0, 31								# iterator for 32 bit length (doubles as a srl arg)
	la	$t1, dec_value						#
	lw	$t1, 0($t1)							# load the integer
											#
	bin_loop:								#
		bgez	$t0, get_bit				#
		jr		$ra							#
	get_bit:								#
		srlv	$t2, $t1, $t0				# shift dec value right by the current counter value
		andi	$t2, $t2, 1					# get LSB of shifted value
											#
	    li $v0, 11							# System call for print_char
		   									#
	    li $a0, '0'							# Load ASCII '0'
		beqz $t2, print_bit					# If $t2 is 0, print '0'
		li $a0, '1'							# Otherwise, load ASCII '1'
	print_bit:								#
		syscall								#
											#
		addi	$t0, $t0, -1				#
		j		bin_loop					#
											#
####################################################################################################
# function: print bin
# purpose: to print a binary
# registers used:
#	$v0 - sycall codes
#	$a0 - passing arugments to subroutines
#	$t0 - iterator
#	$t1 - decimal value
#	$t2 - shifted/masked value
#	$ra - return address
####################################################################################################			
print_hex:									#
	la	$a0, hex_value_msg					#
	li	$v0, 4								#
	syscall									#
											#
	li	$t0, 8								# iterator for 8 nibbles (doubles as a srl arg)
	la	$t1, dec_value						#
	lw	$t1, 0($t1)							# load the integer
											#
	hex_loop:								#
		bgez	$t0, get_nibble				#
		jr		$ra							#
	get_nibble:								#
		srl $t2, $t1, 28					# Shift right to get the MSB
		andi $t2, $t2, 0xF					# Mask to get the lower 4 bits (hex digit)
		lb $a0, hex_digits($t2)				# Load the corresponding hex character
											#
		li $v0, 11							# System call for print_char
		syscall								# Print the character
											#
		sll $t1, $t1, 4						# Shift left to bring the next hex digit into the LSB
		addi $t0, $t0, -1					# Decrease count of hex digits to print
		bgtz $t0, hex_loop					# Repeat until all 8 digits are printed
											#
####################################################################################################
# function: re-enter
# purpose: to clear the buffer and re-enter the main loop
# registers used:
#	$a0 - buffer address
#	$a1 - buffer length
####################################################################################################
re_enter:									#
	la	$a0, buffer							# load buffer address
	li	$a1, 33								# length of buffer
	jal	reset_buffer						# clear the buffer
	j	main								# let's do the time warp again!
											#
####################################################################################################
# function: reset_buffer
# purpose: to reset the buffer for stability and security
# registers used:
#	$t0 - buffer address
#	$t1 - buffer length
#	$t2 - reset value (0)
#	$t3 - iterator
####################################################################################################	
reset_buffer:									#
	move		$t0, $a0						# buffer to $t0
	move		$t1, $a1						# buffer_size to $t1
	li			$t2, 0							# to reset values in buffer
	li 			$t3, 0							# initialize iterator
	reset_buffer_loop:							#
		bge 	$t3, $t1, reset_buffer_return	#
		sw		$t2, 0($t0)						# store a 0
		addi	$t0, $t0, 4						# next word in buffer
		addi 	$t3, $t3, 1						# iterate it!
		j reset_buffer_loop 					# and loop!
	reset_buffer_return:						#
		jr 		$ra								#
												#
####################################################################################################
# function: end
# purpose: to eloquently terminate the program
# registers used:
#	$v0 - syscall codes
#	$a0 - message addresses
####################################################################################################	
end:	 					#
	la		$a0, bye		#
	li		$v0, 4			#
	syscall					#
							#
	li 		$v0, 10			# system call code for returning control to system
	syscall					# GOODBYE!
							#
####################################################################################################
