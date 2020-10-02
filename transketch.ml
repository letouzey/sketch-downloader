(** Transketch : From a sketch.sh json dump to markdown and ocaml/reason
    Pierre Letouzey, 2020
    This file is released under the CC0 License, see the LICENSE file *)

open Yojson.Basic
open Util

let rec submember labels json = match labels with
  | [] -> json
  | label::labels -> submember labels (member label json)

type block = Code of string | Text of string

type lang = ML | RE

let to_lang = function
| "ML" -> ML
| "RE" -> RE
| _ -> failwith "Unsupported Language"

let prlang = function ML -> "ocaml" | RE -> "reason"
let extlang = function ML -> ".ml" | RE -> ".re"

type sketch = {
    id : string;
    title : string;
    lang : lang;
    blocks : block list }

let read_sketch jsonfile =
  let j = from_file jsonfile in
  let note = j |> submember ["data";"note"] |> index 0 in
  let data = note |> member "data" in
  let lang = data |> member "lang" |> to_string |> to_lang in
  let blocks = data |> member "blocks" |> to_list in
  let visible_blocks =
    List.filter (fun blk -> not (blk |> member "deleted" |> to_bool)) blocks in
  let convert_block blk =
    let d = blk |> member "data" in
    let v = d |> member "value" |> to_string in
    match d |> member "kind" |> to_string with
    | "code" -> Code v
    | "text" -> Text v
    | _ -> failwith "unknown code"
  in
  { id = note |> member "id" |> to_string;
    title = note |> member "title" |> to_string;
    lang;
    blocks = List.map convert_block visible_blocks }

let to_markdown lang = function
  | Text s -> s ^ "\n"
  | Code s -> "```" ^ prlang lang ^ "\n" ^ s ^ "\n```\n"

let underline s = String.make (String.length s) '='

let sketch_to_markdown sk =
  sk.title ^ "\n" ^ underline sk.title ^
  "\n\nfetched from https://sketch.sh/s/"^ sk.id^ "\n\n" ^
  String.concat "" (List.map (to_markdown sk.lang) sk.blocks)

(* Any suggestion for a better way to indicate OCaml (or Reason)
   comments containing markdown ? The following choices are quite
   arbitrary *)

let comment lang sep s =
  match lang with
  | ML -> "(*" ^ sep ^ s ^ sep ^ "*)\n"
  | RE -> "/*" ^ sep ^ s ^ sep ^ "*/\n"

let to_ml lang = function
  | Text s -> comment lang ":" ("\n"^ s ^ "\n")
  | Code s -> s ^ "\n"

let sketch_to_ml sk =
  comment sk.lang " " sk.title ^
  comment sk.lang " " (underline sk.title) ^ "\n" ^
  comment sk.lang " " ("fetched from https://sketch.sh/s/"^ sk.id) ^ "\n" ^
  String.concat "" (List.map (to_ml sk.lang) sk.blocks)

let output_file filename content =
  print_string ("creating "^filename^"\n");
  let c = open_out filename in
  output_string c content;
  close_out c

let main =
  if Array.length Sys.argv < 2 then failwith "usage: transketch file.json";
  let jsonfile = Sys.argv.(1) in
  let basename =
    if Filename.check_suffix jsonfile ".json" then
      Filename.chop_suffix jsonfile ".json"
    else jsonfile
  in
  let sk = read_sketch jsonfile in
  output_file (basename^".md") (sketch_to_markdown sk);
  output_file (basename^extlang sk.lang) (sketch_to_ml sk)
