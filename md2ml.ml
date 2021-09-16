(** md2ml : From markdown to OCaml file

    All OCaml code fragments are put forward, the rest becomes comments
    Pierre Letouzey, 2020
    This file is released under the CC0 License, see the LICENSE file *)

let text_as_comment = ref true

let start_text () = if !text_as_comment then ["(*"] else []
let stop_text () = if !text_as_comment then ["*)"] else []

let rec read_lines chan =
  try
    let line = input_line chan in
    line :: read_lines chan
  with End_of_file -> close_in chan; []

let rec do_text = function
  | [] -> stop_text ()
  | line::rest when String.trim line = "```ocaml" ->
     (* Entering a code block *)
     stop_text () @ do_code rest
  | line::rest -> (if !text_as_comment then [line] else []) @ do_text rest

and do_code = function
  | [] -> []
  | line::rest when String.trim line = "```" ->
     (* Exiting a code block *)
     start_text () @ do_text rest
  | line::rest -> line :: do_code rest

let do_file inchan outchan =
  let lines = read_lines inchan in
  let treated = start_text () @ do_text lines in
  List.iter (fun line -> output_string outchan line;
                         output_char outchan '\n') treated;
  close_out outchan

let helps = ["-help";"--help";"-h";"--h";"-usage";"--usage"]

let usage =
 "md2ml : from a markdown file with OCaml excerpts to .ml\n"^
 "Usage : md2ml [-notext] {file.md {file.ml}}\n"

let main () =
  let argv = List.tl (Array.to_list Sys.argv) in
  let () = if List.mem "-notext" argv then text_as_comment := false in
  let argv = List.filter ((<>) "-notext") argv in
  match argv with
  | a :: _ when List.mem a helps -> print_string usage; exit 0
  | [] -> do_file stdin stdout
  | [md] -> do_file (open_in md) stdout
  | [md;ml] -> do_file (open_in md) (open_out ml)
  | _ -> print_string usage; exit 1

let _ = main ()
