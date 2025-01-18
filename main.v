import os

const folder = '.tmp_v_reduce'
const reduced_code_file_name = '__v_reduced_code.v'
const path = '${folder}/${reduced_code_file_name}'

fn string_reproduces(file string, pattern string, command string) {
	if !os.exists(folder) {
		os.mkdir(folder) or { panic(err) }
	}
	os.write_file(path, file) or { panic(err) }
	res := os.execute(command + path)
	if res.output.contains(pattern) {
		println('reproduces')
	} else {
		println('does not reproduce')
//		println(res.output)
	}
}

@[heap]
struct Scope {
	name_id string // fn parse(file string) []Elem
mut:
	children []Elem // code blocks & children scope
}

type Elem = string | Scope

// Maybe replace mutable strings w/ byte arrays much less problems ;)

fn parse(file string) Scope { // The parser is surely incomplete for the V syntax, but should work for most of the cases, if not, please open an issue
	mut stack := []&Scope{} // add the last parent to the stack
	stack << &Scope{
		name_id: '' // parent
	}
	mut top := stack[0]
	mut scope_level := 0 // if we are in a scope (like a function)
	mut i := 0 // index of the current char in the file
	mut current_string := ''
	for i < file.len {
		top = stack[stack.len - 1]
		if file[i] == `/` && file[i + 1] == `/` {
			for file[i] != `\n` { // comment -> skip until newline
				current_string += file[i].ascii_str()
				i++
			}
		} else if file[i] == `/` && file[i + 1] == `*` {
			current_string += file[i].ascii_str() // /
			i++
			current_string += file[i].ascii_str() // *
			i++
			current_string += file[i].ascii_str() // maybe *
			i++
			for !(file[i - 1] == `*` && file[i] == `/`) { // multiline comment -> skip next multiline end sequence
				current_string += file[i].ascii_str()
				i++
			}
			current_string += file[i].ascii_str() // /
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
			scope_level += 1
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
			current_string += file[i].ascii_str()
			i++
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
			if scope_level == 0 && stack.len > 1 { // for the moment there are only fns
				top.children << current_string
				stack.pop()
				top = stack[stack.len - 1]
				current_string = ''
			}
		} else if file[i] == `f` && file[i + 1] == `n` && file[i + 2] == ` ` && file[i - 1] == `\n` {
			fn_start := i
			for file[i + 1] != `{` {
				i++
			}
			top.children << current_string
			current_string = ''
			signature := file[fn_start..i]
			top.children << &Scope{signature, [Elem(signature)]}
			stack << &(top.children[top.children.len - 1] as Scope) // the fn scope
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
			stack << item.children.reverse() // to traverse the tree in the good order
		} else if item is string { // string
			output_code += item
		} else {
			panic("Should never happen")
		}
	}
	return output_code
}

fn main() {
	file := os.read_file("../notOnlyNots/main.v")!
//	file := os.read_file('main.v')!
	// parse the file to extract the scopes
	// reduce the code first fns, then first, second... level scopes then code blocks & lines

	string_reproduces(file, 'C error found', 'v -no-skip-unused ')
	tree := parse(file)
	code := create_code(tree)
	string_reproduces(code, 'C error found', 'v -no-skip-unused ')
	assert code == file
	
	os.rmdir_all(folder) or { panic(err) }
}
