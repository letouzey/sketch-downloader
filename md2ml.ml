(** md2ml : From markdown to OCaml file

    All OCaml code fragments are put forward, the rest becomes comments
    Pierre Letouzey, 2020
    This file is released under the CC0 License, see the LICENSE file *)

let rec read_lines chan =
  try
    let line = input_line chan in
    line :: read_lines chan
  with End_of_file -> close_in chan; []

let rec do_text = function
  | [] -> ["*)"]
  | line::rest when String.trim line = "```ocaml" ->
     (* Entering a code block *)
     "*)" :: do_code rest
  | line::rest -> line :: do_text rest

and do_code = function
  | [] -> []
  | line::rest when String.trim line = "```" ->
     (* Exiting a code block *)
     "(*" :: do_text rest
  | line::rest -> line :: do_code rest

let do_file inchan outchan =
  let lines = read_lines inchan in
  let treated = "(*" :: do_text lines in
  List.iter (fun line -> output_string outchan line;
                         output_char outchan '\n') treated;
  close_out outchan

let helps = ["-help";"--help";"-h";"--h";"-usage";"--usage"]

let usage =
 "md2ml : from a markdown file with OCaml excerpts to .ml\n"^
 "Usage : md2ml {file.md {file.ml}}\n"

let main () =
  match Array.length Sys.argv with
  | 1 -> do_file stdin stdout
  | _ when List.mem Sys.argv.(1) helps -> print_string usage; exit 0
  | 2 -> let inchan = open_in Sys.argv.(1) in
         do_file inchan stdout
  | 3 -> let inchan = open_in Sys.argv.(1) in
         let outchan = open_out Sys.argv.(2) in
         do_file inchan outchan
  | _ -> print_string usage; exit 1

let _ = main ()
