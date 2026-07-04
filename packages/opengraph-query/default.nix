{ writeShellApplication
, tree-sitter-wrapped
, jq
, writeTextFile
, lib
,
}:
let
  opengraph = writeTextFile {
    name = "opengraph.scm";
    text = builtins.readFile ./opengraph.scm;
  };
in
writeShellApplication {
  name = "opengraph-query";
  runtimeInputs = [ tree-sitter-wrapped jq ];
  text = ''
    ${lib.getExe tree-sitter-wrapped} ${opengraph} "$1" | jq '[.[] | select(.capture == "2 - value") | .text | trimstr("`") | fromjson ] | reduce while(. != []; .[2:]) as [$key, $val] ({}; .[$key] = $val)'
  '';
}
