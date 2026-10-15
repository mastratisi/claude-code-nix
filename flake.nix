{
  description = "Nix package for Claude Code, from Anthropic's release manifest";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems }:
    let
      inherit (nixpkgs) lib;
      eachSystem = f: lib.genAttrs (import systems) f;
      overlay = final: prev: {
        claude-code = final.callPackage ./package.nix { };
      };
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ overlay ];
      };
    in
    {
      overlays.default = overlay;

      packages = eachSystem (system: rec {
        claude-code = (pkgsFor system).claude-code;
        default = claude-code;
      });

      apps = eachSystem (system: rec {
        claude-code = {
          type = "app";
          program = "${(pkgsFor system).claude-code}/bin/claude";
        };
        default = claude-code;
      });

      devShells = eachSystem (system: {
        default = (pkgsFor system).mkShell {
          packages = with (pkgsFor system); [ nixpkgs-fmt jq curl nix ];
        };
      });
    };
}
