import os

const folder = ".tmp_v_reduce"
const reduced_code_file_name = "__v_reduced_code.v"
const path = "${folder}/${reduced_code_file_name}"

fn string_reproduces(file string, pattern string, command string) {
	if !os.exists(folder) {
		os.mkdir(folder) or {panic(err)}
	}
	os.write_file(path, file) or {panic(err)}
	res := os.execute(command + path)
	if res.output.contains(pattern) {
		println("reproduces")
	} else {
		println("does not reproduce")
	}
}

type Elem = string | Scope

struct Scope {
	name_id string // fn parse(file string) []Elem
mut:
	children []Elem // code blocks & children scope
}

fn parse(file string) Scope { // The parser is surely incomplete for the V syntax, but should work for most of the cases, if not, please open an issue
	mut tree := Scope{name_id: "BODY"}
	mut stack := []&Elem{} // add the last parent to the stack, to use .children.last()	
	stack << tree
	mut top := &(stack[0] as Scope)
	top.children << ""
	mut top_code := &(top.children[top.children.len-1] as string)
	mut scope_level := 0
	mut i := 0 // index in the file
	for i < file.len {
		top = &(stack[stack.len-1] as Scope)
		top_code = &(top.children[top.children.len-1] as string)
		if file[i] == `/` && file[i+1] == `/` {
			for file[i] != `\n` { // comment -> skip until newline
				unsafe{ *top_code += file[i].ascii_str()}
				i++
			}
		} else if file[i] == `/` && file[i+1] == `*` {
			unsafe{ *top_code += file[i].ascii_str()} // /
			i++
			unsafe{ *top_code += file[i].ascii_str()} // *
			i++	
			unsafe{ *top_code += file[i].ascii_str()} // maybe *
			i++
			for file[i-1] != `*` && file[i] != `/` { // multiline comment -> skip next */
				unsafe{*top_code += file[i].ascii_str()}
				i++
			}
			unsafe{ *top_code += file[i].ascii_str()} // /
			i++
		} else if file[i] == `\`` && file[i-1] != `\\`{ 
			unsafe{ *top_code += file[i].ascii_str()}
			i++ // should not skip important stuff, even better if vfmt before
			unsafe{ *top_code += file[i].ascii_str()}
			i++
			unsafe{ *top_code += file[i].ascii_str()}
			i++
		} else if file[i] == `'` {
			unsafe{ *top_code += file[i].ascii_str()} // '
			i++
			for file[i] != `'` && file[i-1] != `\\` { // string -> skip until next '
				unsafe{ *top_code += file[i].ascii_str()}
				i++
			}
			unsafe{ *top_code += file[i].ascii_str()} // '
			i++
		} else if file[i] == `"` {
			unsafe{ *top_code += file[i].ascii_str()} // "
			i++
			for file[i] != `"` && file[i-1] != `\\` { // string -> skip until next "
				unsafe{ *top_code += file[i].ascii_str()}
				i++
			}
			unsafe{ *top_code += file[i].ascii_str()} // "
			i++
		} else if file[i] == `{` { // update { counter
			unsafe{ *top_code += file[i].ascii_str()}
			i++
			scope_level += 1
		} else if file[i] == `}` {
			unsafe{ *top_code += file[i].ascii_str()}
			i++
			scope_level -= 1
			if scope_level == 0 && stack.len > 1{ // for the moment there are only fns
				stack.pop()	
				top = &(stack[stack.len-1] as Scope)
				top.children << ""
			}
		} else if file[i] == `f` && file[i+1] == `n` && file[i+2] == ` ` && file[i-1] == `\n` {
			fn_start := i
			for file[i+1] != `{` {
				i++
			}
			signature := file[fn_start .. i]
			top.children << Scope{signature, [Elem(signature)]}	
			stack << &(top.children[top.children.len-1]) // the fn scope
		} else {
			unsafe{ *top_code += file[i].ascii_str()}
			i++
		}
		// nothing here to avoid complexity, no need to predict what happened before, everything will be handled properly
	}
	assert stack.len == 1, 'The stack should only have the BODY scope'
	assert scope_level == 0, 'The scopes are not well detected'
	return tree
}


fn main() {
	file := os.read_file("../notOnlyNots/main.v")!
	// parse the file to extract the scopes  
	// reduce the code first fns, then first, second... level scopes then code blocks & lines




	string_reproduces(file, "C error found", "v -no-skip-unused ")
	tree := parse(file)	


	os.rmdir_all(folder) or {panic(err)}
}
