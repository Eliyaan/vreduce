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
	children []Elem // code blocks & children scopes
}

fn parse(file string) []Elem {
	tree := []Elem{}
	for i < file.len {
		if file[i] == `/` && file[i+1] == `/` {
			for file[i] != `\n` { // comment -> skip until newline
				i++
			}
		} else if multiline {
		} else if string ' " 
		} else if {} // update {} counter
		} else if fnc decla
		else {
			add to the actual codeblock
		}
		i++
	}
}

fn main() {
	file := os.read_file("../notOnlyNots/main.v")!
	// parse the file to extract the scopes  !!! comments //, multilines /*, strings " ', not scope {}
	// reduce the code first fns, then first, second... level scopes then code blocks & lines




	string_reproduces(file, "C error found", "v -no-skip-unused ")




	os.rm(folder) or {panic(err)}
}
