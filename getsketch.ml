(** * Getsketch

Download the data of a https://sketch.sh page and dump it in json or markdown
Pierre Letouzey, 2020
This file is released under the CC0 License, see the LICENSE file

Reference : https://github.com/Sketch-sh/sketch-sh/blob/master/client/src/gql/GqlGetNoteById.re
See also https://github.com/Sketch-sh/sketch-sh/issues/41
For now, user_id, fork_from, updated_at are removed from the graphql request.
*)

(** Hack for fetching Sketch ID from URL :)
    Works with https:// and http://, with trailing / or not,
    and keeps IDs untouched *)

let get_ID url =
  let tok = Filename.basename url in
  if String.length tok <> 22 then
    (Printf.eprintf "Error bad length of Sketch ID %s\n" tok; exit 1);
  tok

(** Http request to fetch the json raw data from Sketch.sh
    tok is the Sketch unique ID *)

let get_sketch_json tok =
  let open Cohttp in
  let open Cohttp_lwt in
  let open Cohttp_lwt_unix in
  let uri = Uri.of_string "https://api.sketch.sh/graphql" in
  let headers = Header.init_with "content-type" "application/json" in
  let graphql_query =
    "query getNoteById($noteId: String!)"^
    "{note:note(where:{id:{_eq:$noteId}}) {id title data}}" in
  let json =
    `Assoc ["operationName", `String "getNoteById";
            "variables", `Assoc ["noteId",`String tok];
            "query", `String graphql_query] in
  let body = Body.of_string (Yojson.Basic.to_string json) in
  let handle_response (resp,body) =
    let code = Code.code_of_status (Response.status resp) in
    if not (Code.is_success code) then
      (Printf.eprintf "Unsuccessful request (code %d)\n" code; exit 1);
    Body.to_string body
  in
  Lwt.bind (Client.call ~headers ~body `POST uri) handle_response

(** From Json to Markdown *)

type block = Code of string | Text of string

type sketch = {
    id : string;
    title : string;
    lang : string;
    blocks : block list }

let parse_sketch json =
  let j = Yojson.Basic.from_string json in
  let open Yojson.Basic.Util in
  let note = j |> member "data" |> member "note" |> index 0 in
  let data = note |> member "data" in
  let lang = match data |> member "lang" |> to_string with
    | "ML" -> "ocaml"
    | "RE" -> "reason"
    | s -> failwith ("Unsupported language : "^s) in
  let blocks = data |> member "blocks" |> to_list in
  let visible_blocks =
    List.filter (fun blk -> not (blk |> member "deleted" |> to_bool)) blocks in
  let convert_block blk =
    let d = blk |> member "data" in
    let v = d |> member "value" |> to_string in
    match d |> member "kind" |> to_string with
    | "code" -> Code v
    | "text" -> Text v
    | s -> failwith ("Unknown kind of block : "^s)
  in
  { id = note |> member "id" |> to_string;
    title = note |> member "title" |> to_string;
    lang;
    blocks = List.map convert_block visible_blocks }

let block_to_markdown lang = function
  | Text s -> s ^ "\n"
  | Code s -> "```" ^ lang ^ "\n" ^ s ^ "\n```\n"

let sketch_to_markdown sk =
  sk.title ^ "\n" ^ String.map (fun _ -> '=') sk.title ^
  "\n\n[Sketch link](https://sketch.sh/s/"^ sk.id^ ")\n\n" ^
  String.concat "\n" (List.map (block_to_markdown sk.lang) sk.blocks)

(** Main *)

let helps = ["-help";"--help";"-h";"--h";"-usage";"--usage"]

let main () =
  if Array.length Sys.argv < 2 || List.mem Sys.argv.(1) helps then
    (Printf.eprintf "usage: getsketch SketchID_or_URL {out.md|out.json}\n";
     exit 1);
  let tok = get_ID Sys.argv.(1) in
  let out,raw =
    if Array.length Sys.argv = 3 then
      let f = Sys.argv.(2) in
      open_out f, Filename.check_suffix f ".json"
    else
      stdout, false
  in
  let json = Lwt_main.run (get_sketch_json tok) in
  let answer =
    if raw then json else sketch_to_markdown (parse_sketch json)
  in
  output_string out answer;
  close_out out

let _ = main ()
