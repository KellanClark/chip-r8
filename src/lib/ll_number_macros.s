; Macros for working with the "numbers" in ../tables/ll_numbers.s

; Cleaner way to get number constants
macro dw_number num* {
	dw (number_0 + 4 + ((num) * NUMBER_SIZE))
}

; Decrements the number in src and stores the result in dst
macro num_dec dst*, src {
	if src eq
		ldmdb dst, {dst\}
	else
		ldmdb src, {dst\}
	end if
}

; Increments the number in src and stores the result in dst
macro num_inc dst*, src {
	if src eq
		ldmib dst, {tmp0, tmp1, dst\}
	else
		ldmib src, {tmp0, tmp1, dst\}
	end if
}
