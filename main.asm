# Program #10: Decimal Place Rounder
# Author: Lazlo F. Steele
# Due Date : Nov. 9, 2024 Course: CSC2025-2H1
# Created: Nov. 3, 2024
# Last Modified: Nov. 7, 2024
# Functional Description: Given a numeric value provided by the user with at least 5 decimal places,
# 	round to a user provided decimal precision.
# Language/Architecture: MIPS 32 Assembly
####################################################################################################
# Algorithmic Description:
#	get input
#	check input for only numeric characters, '-', a single '.', and at least 5 digits after the ',' character
#	store all digits before the '.' as whole
#	store all digits after the '.' as fractional
#	store the count of digits after '.' in a $s0
#	convert whole to float
#	convert fractional to float
#	for i in range($s0):
#		divide fractional by 10
# 	add fractional to whole
#	store value as dec_value
#	for i in range(precision_flag):
#		dec_value*=10
#	dec_value += 0.5
#	convert dec_value to int
#	convert to float
#	for i in range(precision_flag):
#		dec_value/=10
#	print dec_value!
#	again?
####################################################################################################

.data
	welcome_msg:	.asciiz "\nAhoy. I am the point floater. I will provide rounded floats to a precision of your choice."
	places_msg:		.asciiz	"\nPlease enter your dcimal precision from 1-4 decimal places > "
	float_msg:		.asciiz "\nPlease enter a number with at least 5 decimal places > "
	precision_msg:	.asciiz "\nPrecision - "
	colon:			.asciiz " : "
	repeat_msg:		.asciiz "\nGo again? Y/N > "
	invalid_msg:	.asciiz "\nInvalid input. Try again!\n"
	bye: 			.asciiz "Toodles! ;)"
	space: 			.ascii	" "
	newline: 		.asciiz "\n"

	float_zero:		.float 0.0
	float_ten:		.float 10.0
	float_half:		.float 0.5
		
	whole:			.word 0
	fractional:		.word 0
	dec_value:		.float 0.0

	precision_flag:	.byte 0		# number of place values
	
					.align 2
	buffer:			.space 33

					.globl	main

					.text

####################################################################################################
# function: main
# purpose: to control program flow
# registers used:
#	$a0 - argument passed
#	$s0 - decimal places found in get_int
####################################################################################################
main:								#
	jal		welcome					# welcome the user
									#
	jal 	get_int					# get input
									#
	move 	$a0, $s0				# move the number of decimal places to the first argument register
	jal 	convert_to_float		# convert input to float
									#
	jal 	get_mode				# how many decimal places to round to?
									#
	jal 	round					# rount the value
									#
	jal 	print_float				# print the value!
	j		again					# again?
									#
####################################################################################################
# function: welcome
# purpose: to welcome the user to our program
# registers used:
#	$v0 - syscall codes
#	$a0 - passing arugments to subroutines
#	$ra	- return address
####################################################################################################	
welcome:							# 
	la	$a0, welcome_msg			# load welcome message
	li	$v0, 4						# 
	syscall							# and print
									#
	jr	$ra							# return to caller
									#
####################################################################################################
# function: get_mode
# purpose: to map application state to user input
# registers used:
#	$v0 - syscall codes
#	$a0 - passing arugments to subroutines
#	$a1 - buffer lengths
#	$t0 - first character of user input
#	$t1 - comparator values
#	$ra - return address
####################################################################################################
get_mode:							#
	la		$a0, places_msg			# load message
	li		$v0, 4					#
	syscall							# print
									#
	mode_input:						#
		la 	$a0, buffer				# load buffer
		li	$a1, 33					# 32 characters plus null terminator
		li	$v0, 8					# 
		syscall						# and read to buffer
									#
	lb		$t0, 0($a0)				# load first byte from buffer
									#
	li		$t1, '1'				# 
	blt 	$t0, $t1, invalid_mode	# if it is less than '1' then invalid
	li		$t1, '4'				#
	bgt 	$t0, $t1, invalid_mode	# if it is greater than '4' then invalid
									#
	addi 	$t0, $t0, -48			# subtract '0' to store as integer in flag
									#
	la		$t1, precision_flag		# load the flag address
	sb		$t0, 0($t1)				# store the flag value
									#
	jr		$ra						# return to caller
									#
	invalid_mode:					#
		la	$a0, invalid_msg		# 
		li	$v0, 4					#
		syscall						# print invalid message
									#
		j get_mode					# try again!
									#
####################################################################################################
# function: get_int
# purpose: to convert a string of floats into a float integer
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
get_int:									#
	move	$s0, $ra						# save return address for nesting
	la		$a0, buffer						# load buffer address for clearing value
	li		$a1, 33							# load buffer length
	jal		reset_buffer					# reset buffer
	move 	$ra, $s0						# move return address back from saved value
											#
	la		$a0, float_msg					# load prompt
	li		$v0 4							# prepare to print string
	syscall									# print!
											#
	la		$a0, buffer						# load buffer address
	li		$a1, 33							# load 
	li		$v0, 8							# prepare to read string
	syscall									# read!
											#
	li		$t0, 0							# $t0 will hold the final integer value
	li		$t1, 0							# $t1 is a flag for sign (0 = positive, 1 = negative)
	la		$t2, buffer						# $t2 points to the current character in buffer
	li		$t4, '-'						# to check for negative
	li		$t5, 0							# decimal point flag
	li		$t6, -1							# decimal place counter, initialized at -1 because SLOPPPPPPP!!!
											#
	lb		$t3, 0($t2)						# load the first character
	beq		$t3, $t4, check_negative		# if it's '-', set negative flag
	j		process_digits					# if no sign, process digits directly
											#
	check_negative:							#
		li	$t1, 1							# set negative flag
		addi $t2, $t2, 1					# move to next character
		j	process_digits					#
											#
	process_digits:							#
		lb	$t3, 0($t2)                  	# load the next character
		beqz $t5, for_digit					#
											#
		addi $t6, $t6, 1					#
		for_digit:							#
		beq	$t3, 10, store_fractional		# end of string (null terminator)
		beq	$t3, '.', decimal_found			#
		blt $t3, '0', invalid_integer		# if character is not a digit, go to error
		bgt $t3, '9', invalid_integer		# if character is not a digit, go to error
											#
		sub $t3, $t3, '0'					# $t3 = character - '0' to get integer value
		mul $t0, $t0, 10					# shift existing number left by one decimal place
		add $t0, $t0, $t3					# add the new digit to the result
											#
		addi $t2, $t2, 1					# move to next character
		j	process_digits					#
											#
	invalid_integer:						#
		la	$a0, invalid_msg				#
		li	$v0, 4							#
		syscall								#
											#
		j get_int							#
											#
	decimal_found:							#
		beq $t5, 1, invalid_integer			# if a decimal has already been found, input is invalid
											#		
		li	$t5, 1							# set decimal found flag
											#
		beqz $t1, store_whole				# if negative flag not raised, skip make_negative
											#
		make_negative:						#
			sub $t0, $zero, $t0				# negate $t0
											#
		store_whole	:						#
			sw	$t0, whole					# store the final integer in whole number
			li	$t0, 0						# reset the result to store the fractional!
											#
		addi $t2, $t2, 1					#
		j process_digits					#
											#
	store_fractional:						#
		blt $t6, 5, invalid_integer			#
		move $s0, $t6						#
		sw	$t0, fractional					#
											#
		jr	$ra								#
											#
####################################################################################################
# function: convert_to_float
# purpose: to convert two integers into a float
# registers used:
#	$a0  - number of decimal places found
#	$t0  - working addresses and int values
#	$f0  - working float values
#	$f1  - 10.0
#	$f12 - the final float to return
#	$ra  - return address
####################################################################################################
convert_to_float:					#
	move	$t1, $a0				# load the number of decimal points found in input string
	la		$t0, whole				#
	lw		$t0, 0($t0)				# load the whole portion of the input string
	mtc1	$t0, $f0				# store it in the floating point coproc
	cvt.s.w	$f0, $f0				# convert to float
									#
	mov.s	$f12, $f0				# move the value to save
									#
	la		$t0, fractional			#
	lw		$t0, 0($t0)				# load the fractional part of the input string
	mtc1	$t0, $f0				# store it in the floating coproc
	cvt.s.w	$f0, $f0				# convert it to a float
									#
	lwc1 	$f1, float_ten			# load a floating point 10.0
									#
	fractional_loop:				#
		beqz	$t1, convert_done	#
		div.s	$f0, $f0, $f1		# divide by 10 for each decimal point
		addi	$t1, $t1, -1		#
		j 		fractional_loop		#
									#
	convert_done:					#
		add.s	$f12, $f12, $f0		# add the fractional to the stored whole portion
									#
		swc1	$f12, dec_value		# and store the value in memory
		jr 		$ra					# return to caller
									#
####################################################################################################
# function: round
# purpose: to round the number to the decimal point provided
# registers used:
#	$t0 - decimal precision to round to
#	$t1 - integer value for rounding algorithm
#	$f0 - working float value
#	$f1 - 10.0
#	$f2 - 0.5
#	$ra - return address
####################################################################################################
round:								#
	lwc1	$f0, dec_value			# load the float value
	lwc1	$f1, float_ten			# load 10.0
									#
	lw		$t0, precision_flag		# load the decimal precision
									#
	mult_loop:						#
		beqz	$t0, float_to_int	# multiply by ten for each in decimal precision
		mul.s	$f0, $f0, $f1		#
		addi	$t0, $t0, -1		#
		j		mult_loop			#
									#
	float_to_int:					#
		lwc1	$f2, float_half		#
		add.s	$f0, $f0, $f2		# add .5 to the result to approximate rounding to the nearest int
		cvt.w.s	$f0, $f0			# convert to int
		mfc1	$t1, $f0			# store in a standard register
		mtc1	$t1, $f0			# move back to a float register
		cvt.s.w	$f0, $f0			# convert back to float
									#
	lw		$t0, precision_flag		# load the decimal precision
									#
	div_loop:						#
		beqz 	$t0, round_done		# divide by 10 for each in decimal precision
		div.s	$f0, $f0, $f1		#
		addi 	$t0, $t0, -1		#
		j		div_loop			#
									#
	round_done:						#
		swc1	$f0, dec_value		# store the final value
		jr		$ra					# and return to caller
									#
####################################################################################################
# function: print_float
# purpose: to clear the buffer and re-enter the main loop
# registers used:
#	$v0  - syscall codes
#	$f12 - float to print
#	$ra  - return address
####################################################################################################
print_float:						#
	lwc1	$f12, dec_value			# load float
	li		$v0, 2					# print as float
	syscall							# print
									#
	jr		$ra						# return to caller
####################################################################################################
# function: re-enter
# purpose: to clear the buffer and re-enter the main loop
# registers used:
#	$a0 - buffer address
#	$a1 - buffer length
####################################################################################################
re_enter:							#
	la	$a0, buffer					# load buffer address
	li	$a1, 33						# length of buffer
	jal	reset_buffer				# clear the buffer
	j	main						# let's do the time warp again!
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
# macro: upper
# purpose: to make printing messages more eloquent
# registers used:
#	$t0 - string to check for upper case
#	$t1 - ascii 'a', 'A'-'Z' is all lower value than 'a'
# variables used:
#	%message - message to be printed
####################################################################################################		
upper:							#
	move $s0, $ra				#
	move $t0, $a0				# load the buffer address
	li $t1, 'a'					# lower case a to compare
	upper_loop:					#
		lb $t2, 0($t0)			# load next byte from buffer
		blt $t2, $t1, is_upper	# bypass uppercaserizer if character is already upper case (or invalid)
		to_upper:				# 
			subi $t2, $t2, 32	# Convert to uppercase (ASCII difference between 'a' and 'A' is 32)
		is_upper:				#
			sb $t2, 0($t0)		# store byte
		addi $t0, $t0, 1		# next byte
		bne $t2, 0, upper_loop	# if not end of buffer go again!
	move $ra, $s0				#
	jr $ra						#
								#
####################################################################################################
# function: again
# purpose: to user to repeat or close the program
# registers used:
#	$v0 - syscall codes
#	$a0 - message storage for print and buffer storage
#	$t0 - stores the memory address of the buffer and first character of the input received
#	$t1 - ascii 'a', 'Y', and 'N'
####################################################################################################
again:							#		
	la $a0, repeat_msg			#
	li $v0, 4					#
	syscall						#
								#
	la $a0, buffer				#
	la $a1, 4					#
	li $v0, 8					#
	syscall						#
								#
	la $a0, buffer				#
	jal upper					# load the buffer for string manipulation
								#
	la $t0, buffer				#
	lb $t0, 0($t0)				#
	li $t1, 'Y'					# store the value of ASCII 'Y' for comparison
	beq $t0, $t1, re_enter		# If yes, go back to the start of main
	li $t1, 'N'					# store the value of ASCII 'N' for comparison
	beq $t0, $t1, end			# If no, goodbye!
	j again_invalid				# if invalid try again...
								#
	again_invalid:				#
		la $a0, invalid_msg		#
		li $v0, 4				#
		syscall					#
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
