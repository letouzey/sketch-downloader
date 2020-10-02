Convert online sketch.sh pages to local markdown and OCaml/reasonML files
=========================================================================

For now, two separate tools :

 - `getsketch` : a shell script running `curl` for dumping the sketch.sh page as json
 - `transketch` : an OCaml script translating this json dump into markdown and OCaml/reasonML files

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
