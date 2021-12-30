(module
	(import "seal0" "seal_input" (func $seal_input (param i32 i32)))
	(import "seal0" "seal_get_storage" (func $seal_get_storage (param i32 i32 i32) (result i32)))
	(import "seal0" "seal_set_storage" (func $seal_set_storage (param i32 i32 i32)))
	(import "__unstable__" "seal_call_code" (func $seal_call_code (param i32 i32 i32 i32 i32 i32) (result i32)))
	(import "env" "memory" (memory 3 3))

	;; [0, 32) storage key
	(data (i32.const 0) "\01")
    ;; [32, 64) storage value
	(data (i32.const 32) "\20")

	;; [64, 96) buffer where input is copied

	;; [96, 100) size of the input buffer
	(data (i32.const 96) "\20")

	;; [100, 104) size of buffer for seal_get_storage
	(data (i32.const 100) "\20")

	;; [104, 136) seal_get_storage buffer

	;; 'seal_call_code' input data buffer
	(data (i32.const 136) "\20")

	(func $assert (param i32)
		(block $ok
			(br_if $ok
				(get_local 0)
			)
			(unreachable)
		)
	)

	(func (export "call")
		(local $exit_code i32)

		(call $seal_input (i32.const 64) (i32.const 96))

		;; assert input size == 32
		(call $assert
			(i32.eq
				(i32.load (i32.const 96))
				(i32.const 32)
			)
		)

		;; place a value in storage, the size of which is specified by the call input.
		(call $seal_set_storage
			(i32.const 0)		;; Pointer to storage key
			(i32.const 32)		;; Pointer to value
		    (i32.load (i32.const 100))		;; Size of value
		)

		(call $assert
			(i32.eq
		        (call $seal_get_storage
		        	(i32.const 0)		;; Pointer to storage key
		        	(i32.const 104)		;; buffer where to copy result
		        	(i32.const 100)		;; pointer to size of buffer
		        )
				(i32.const 0) ;; ReturnCode::Success
			)
		)

		(call $assert
			(i32.eq
				(i32.load (i32.const 104))
				(i32.load (i32.const 32))
			)
		)

		;; Call deployed library contract code.
		(set_local $exit_code
			(call $seal_call_code
				(i32.const 1)   ;; Set FORWARD_INPUT bit
				(i32.const 64)	;; Pointer to "callee" code_hash.
				(i32.const 136)	;; Pointer to input data buffer address
				(i32.const 4)	;; Length of input data buffer
				(i32.const 140)  ;; Ptr to output buffer (any value)
				(i32.const 32)  ;; Output buffer len (any value)
			)
		)

		;; Check for success exit status.
		(call $assert
			(i32.eq (get_local $exit_code) (i32.const 0)) ;; ReturnCode::Success
		)

		(call $assert
			(i32.eq
				(call $seal_get_storage
					(i32.const 0)		;; Pointer to storage key
					(i32.const 104)		;; buffer where to copy result
					(i32.const 100)		;; pointer to size of buffer
				)
				(i32.const 0) ;; ReturnCode::Success
			)
		)

        ;; Make sure that 'callee' code changed the value
		(call $assert
			(i32.eq
				(i32.load (i32.const 104))
				(i32.const 1)
			)
		)
	)

	(func (export "deploy"))

)
