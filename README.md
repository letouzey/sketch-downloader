Convert online sketch.sh pages to local markdown and OCaml/reasonML files
=========================================================================

For now, several separate tools :

 - `getsketch` : an OCaml program fetching the sketch.sh page and displaying it as markdown (or as raw json dump)
 - `md2ml` : an OCaml program turning a markdown file (with OCaml excerpts) into a .ml file

Olders tools:

 - `getsketch.sh` : a shell script running `curl` for dumping the sketch.sh page as json
 - `transketch` : an OCaml script translating this json dump into markdown and OCaml/reasonML files

## getsketch

Depends : ocaml + dune + yojson + cohttp-lwt-unix

Compile : `dune build ./getsketch.exe`

Usage : `dune exec -- ./getsketch.exe URL file.md`

URL could be the full `https://sketch.sh/s/.../` url, or just the final token.
The markdown filename is optional, if not there stdout is used.
If the file extension is .json instead of .md, the raw json data is dumped.

## md2ml

Depends : ocaml + dune

Compile : `dune build ./md2ml.exe`

Usage : `dune exec -- ./md2ml.exe URL file.md file.ml`

Reads an existing file.md and turn it into a file.ml where all ocaml code
blocks are at toplevel and everything else is in comments.
If filenames are lacking, stdin and stdout are used instead.

## getsketch.sh

Depends : curl

Usage : `./getsketch.sh URL dump.json`

URL could be the full `https://sketch.sh/s/.../` url, or just the final token.
The json filename is optional.

## transketch

Depends : ocaml + dune + yojson

Compile : `dune build transketch.exe`

Usage : `dune exec ./transketch.exe dump.json`

This will produce a `dump.md` and a `dump.ml` (resp. `dump.re`) files
from a `dump.json` obtained via `getsketch.sh`
