{ tree-sitter-cli, writeNuApplication }: writeNuApplication rec {
  name = "generic-wrapper";
  runtimeInputs = [ tree-sitter-cli ];
  text = builtins.readFile ./${name}.nu;
}
