import os

const folder = '.tmp_v_reduce'
const reduced_code_file_name = '__v_reduced_code.v'
const path = '${folder}/${reduced_code_file_name}'

fn string_reproduces(file string, pattern string, command string) bool {
	if !os.exists(folder) {
		os.mkdir(folder) or { panic(err) }
	}
	os.write_file(path, file) or { panic(err) }
	res := os.execute(command + path)
	if res.output.contains(pattern) {
		//println('reproduces')
		return true
	} else {
		//println('does not reproduce')
		//println(res.output)
		return false
	}
}

@[heap]
struct Scope {
mut:
	ignored bool // is ignored when creating the file
	tmp_ignored bool // testing if it can be ignored in the file
	children []Elem // code blocks & children scope
}

type Elem = string | Scope

// Maybe replace mutable strings w/ byte arrays much less problems ;)

fn parse(file string) Scope { // The parser is surely incomplete for the V syntax, but should work for most of the cases, if not, please open an issue
	mut stack := []&Scope{} // add the last parent to the stack
	stack << &Scope{}	
	mut top := stack[0]
	mut scope_level := 0 // if we are in a scope (like a function)
	mut i := 0 // index of the current char in the file
	mut current_string := ''
	for i < file.len {
		top = stack[stack.len - 1]
		if file[i] == `/` && file[i + 1] == `/` {
			for file[i] != `\n` { // comment -> skip until newline
				//current_string += file[i].ascii_str()
				i++
			}
		} else if file[i] == `/` && file[i + 1] == `*` {
			//current_string += file[i].ascii_str() // /
			i++
			//current_string += file[i].ascii_str() // *
			i++
			//current_string += file[i].ascii_str() // maybe *
			i++
			for !(file[i - 1] == `*` && file[i] == `/`) { // multiline comment -> skip next multiline end sequence
				//current_string += file[i].ascii_str()
				i++
			}
			//current_string += file[i].ascii_str() // /
			i++
		} else if file[i] == `\`` && file[i - 1] != `\\` {
			current_string += file[i].ascii_str()
			i++
			for file[i] != `\`` || (file[i - 1] == `\\` && file[i - 2] != `\\`) { // string -> skip until next `
				current_string += file[i].ascii_str()
				i++
			}
			current_string += file[i].ascii_str() // `
			i++
		} else if file[i] == `'` {
			current_string += file[i].ascii_str() // '
			i++
			for file[i] != `'` || (file[i - 1] == `\\` && file[i - 2] != `\\`) { // string -> skip until next '
				current_string += file[i].ascii_str()
				i++
			}
			current_string += file[i].ascii_str() // '
			i++
		} else if file[i] == `"` {
			current_string += file[i].ascii_str() // "
			i++
			for file[i] != `"` || (file[i - 1] == `\\` && file[i - 2] != `\\`){ // string -> skip until next "
				current_string += file[i].ascii_str()
				i++
			}
			current_string += file[i].ascii_str() // "
			i++
		} else if file[i] == `{` { // update { counter
			current_string += file[i].ascii_str()
			i++
			top.children << current_string
			scope_level += 1
			current_string = ''
			top.children << &Scope{}
			stack << &(top.children[top.children.len - 1] as Scope)
							/*
							println("\n####new scope: ${scope_level}")
							if stack[0].children.len > 0 {
								println(stack[0].children.last())
							}
							println('\n\n')
							println(current_string)
							println('\n\n')
							*/
		} else if file[i] == `}` {
			scope_level -= 1
							/*
							println("\n####get out of the scope: ${scope_level}")
							if stack[0].children.len > 0 {
								println(stack[0].children.last())
							}
							println('\n\nCurrent string:')
							println(current_string)
							println('\n\n')
							*/
			assert scope_level >= 0, 'The scopes are not well detected ${stack[0]}'
			top.children << current_string
			stack.pop()
			top = stack[stack.len - 1]
			current_string = ''
			current_string += file[i].ascii_str() // }
			i++
		} else {
			current_string += file[i].ascii_str()
			i++
		}
		// nothing here to avoid complexity, no need to predict what happened before, everything will be handled properly
	}
	top = stack[stack.len - 1]
	top.children << current_string // last part of the file
	assert scope_level == 0, 'The scopes are not well detected'
	assert stack.len == 1, 'The stack should only have the BODY scope'
	return *stack[0]
}

fn create_code(sc Scope) string {
	mut output_code := ""
	mut stack := []Elem{}
	stack << sc
	for stack.len > 0 {
		item := stack.pop() 
		if item is Scope {
			if !item.ignored && !item.tmp_ignored {
				stack << item.children.reverse() // to traverse the tree in the good order
			} else {
			}
		} else if item is string { // string
			output_code += item
		} else {
			panic("Should never happen")
		}
	}
	return output_code
}

fn reduce_scope(mut sc Scope) {
	mut modified_smth := true // was a modification successful in reducing the code in the last iteration
	for modified_smth {
		modified_smth = false
		println("NEXT ITERATION")
		mut stack := []&Elem{}
		for i := sc.children.len-1; i > 0; i-- {
			stack << &sc.children[i]
		}
		for stack.len > 0 {
			mut item := stack.pop() 
			if mut item is Scope {
				if !item.ignored {
					item.tmp_ignored = true
					code := create_code(sc)
					item.tmp_ignored = false // dont need it
					if string_reproduces(code, 'C error found', 'v -no-skip-unused ') {
						item.ignored = true
						modified_smth = true
						println("Code size: ${code.len}")
					} else { // if can remove it, can remove it's children 
						for i := item.children.len-1; i > 0; i-- {
							stack << &item.children[i]
						}
					}
				}
			} 
			/*
			if !ignored
				-> tmp_ignore
			create the file
			test for reproduction :
				ignored & modified_smth = true & print file size / original size
				not ignored
				tmp_ignore -> false
			*/
		}
	}
	mre := create_code(sc)
	assert string_reproduces(mre, 'C error found', 'v -no-skip-unused')
	os.write_file('rpdc.v', mre) or {panic(err)}
}

fn main() {
	file := os.read_file("../notOnlyNots/main.v")!
	println("Original code size: ${file.len}")
	assert !string_reproduces(os.read_file('main.v')!, 'C error found', 'v -no-skip-unused')
	// parse the file to extract the scopes
	// reduce the code first fns, then first, second... level scopes then code blocks & lines

	// startup tests
	assert string_reproduces(file, 'C error found', 'v -no-skip-unused ')
	mut tree := parse(file)
	code := create_code(tree)
	assert string_reproduces(code, 'C error found', 'v -no-skip-unused ')
	println("Code size without comments: ${code.len}")

	// reduce
	reduce_scope(mut tree)

	// clean up
	os.rmdir_all(folder) or { panic(err) }
}
