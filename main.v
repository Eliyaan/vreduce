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
	children []Elem // code blocks & children scopes
}

fn parse(file string) Scope {
	mut tree := Scope{name_id: "BODY"}
	mut stack := []&Elem{} // add the last parent to the stack, to use .children.last()	
	stack << tree
	mut top := &(stack[0] as Scope)
	mut top_code := &(top.children[top.children.len-1] as string)
	top.children << ""
	mut scope_level := 0
	mut i := 0 // index in the file
	for i < file.len {
		top = &(stack[stack.len-1] as scope)
		top_code = &(top.children[top.children.len-1] as string)
		if file[i] == `/` && file[i+1] == `/` {
			for file[i] != `\n` { // comment -> skip until newline
				top_code += file[i].ascii_str()
				i++
			}
		} else if file[i] == `/` && file[i+1] == `*` {
			top_code += file[i].ascii_str() // /
			i++
			top_code += file[i].ascii_str() // *
			i++
			for file[i] != `*` { // multiline comment -> skip next */
				top_code += file[i].ascii_str()
				i++
				if file[i] == `/` { // end of multiline
					top_code += file[i].ascii_str()
					break
				}
			}
		} else if file[i] == `\`` && file[i-1] != `\\`{ 
			top_code += file[i].ascii_str()
			i++ // should not skip important stuff, even better if vfmt before
			top_code += file[i].ascii_str()
			i++
			top_code += file[i].ascii_str()
		} else if file[i] == `'` {
			top_code += file[i].ascii_str()
			i++
			for file[i] != `'` && file[i-1] != `\\` { // string -> skip until next '
				top_code += file[i].ascii_str()
				i++
			}
		} else if file[i] == `"` {
			top_code += file[i].ascii_str()
			i++
			for file[i] != `"` && file[i-1] != `\\` { // string -> skip until next "
				top_code += file[i].ascii_str()
				i++
			}
		} else if file[i] == `{` { // update { counter
			scope_level += 1
		//} else if fnc decla
		} else {
			//add to the actual codeblock
		}
		i++
	}
	return tree
}


fn main() {
	file := os.read_file("../notOnlyNots/main.v")!
	// parse the file to extract the scopes  !!! comments //, multilines /*, strings " ', not scope {}
	// reduce the code first fns, then first, second... level scopes then code blocks & lines




	string_reproduces(file, "C error found", "v -no-skip-unused ")



	os.rmdir_all(folder) or {panic(err)}
}
