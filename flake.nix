{

  inputs = {
    actions-nix.url = "github:nialov/actions.nix";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nuenv.url = "github:YPares/nushellWith";
    tree-sitter.inputs.nixpkgs.follows = "nixpkgs";
    tree-sitter.url = "github:tree-sitter/tree-sitter/v0.26.8";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, ... }@inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {

    systems = inputs.nixpkgs.lib.systems.flakeExposed;
    imports = [
      inputs.actions-nix.flakeModules.default
      inputs.devshell.flakeModule
      inputs.flake-parts.flakeModules.easyOverlay
      inputs.treefmt-nix.flakeModule
    ];

    perSystem = { pkgs, config, system, lib, ... }: {

      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.nuenv.overlays.default
          self.overlays.default
        ];
        config = { };
      };

      overlayAttrs = {
        inherit (config.packages)
          opengraph-query
          ;
      };

      treefmt.config = {
        flakeCheck = true;
        flakeFormatter = true;
        programs = {
          deadnix.enable = true;
          nixpkgs-fmt.enable = true;
          statix.enable = true;
        };
        projectRootFile = "flake.nix";
      };

      packages."opengraph-query" = pkgs.callPackage ./packages/opengraph-query {
        tree-sitter-wrapped = pkgs.callPackage ./packages/generic-wrapper {
          tree-sitter-cli = pkgs.callPackage ./packages/tree-sitter-cli {
            inherit (pkgs) tree-sitter;
            grammars = [
              pkgs.tree-sitter-grammars.tree-sitter-html
            ];
          };
          writeNuApplication = pkgs.callPackage ./packages/writeNuApplication { };
        };
        inherit (pkgs) jq;
      };

      devshells.default.commands = [
        {
          name = "opengraph-query";
          help = "Query OpenGraph meta-tags from HTML files.";
          command = "${lib.getExe config.packages.opengraph-query}";
        }
      ];
    };

    flake = {

      # nix run .#render-workflows
      actions-nix = {
        defaultValues = {
          jobs = {
            timeout-minutes = 30;
            runs-on = "ubuntu-latest";
          };
        };
        pre-commit.enable = true;
        workflows = {
          ".github/workflows/main.yaml" = {
            on = {
              push.branches = [ "main" ];
              workflow_dispatch = { };
              pull_request = { };
            };
            jobs = {
              nix-flake-check = {
                steps = with inputs.actions-nix.lib.steps; [
                  actionsCheckout
                  DeterminateSystemsNixInstallerAction
                  runNixFlakeCheck
                ];
              };
            };
          };
        };
      };

    };
  };
}
