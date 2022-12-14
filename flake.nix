{

  description = "Random packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "flake:flake-utils";
    piped-frontend-src = {
      url = "github:TeamPiped/Piped";
      flake = false;
    };
    piped-proxy-src = {
      url = "github:TeamPiped/piped-proxy";
      flake = false;
    };
    piped-backend-src = {
      url = "github:TeamPiped/piped-backend";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
  
  {
    nixosModules.default = { ... }: {
      imports = [
        (import ./piped-backend/module.nix { inherit self; })
        (import ./piped-frontend/module.nix { inherit self; })
        (import ./piped-proxy/module.nix { inherit self; })
      ];
    };
  } //
  
  flake-utils.lib.eachSystem (with flake-utils.lib.system; [ aarch64-linux x86_64-linux ]) (system:

    let

      pkgs = nixpkgs.legacyPackages."${system}";

    in

    with pkgs;

    rec {
      packages = flake-utils.lib.flattenTree {
        piped-proxy = callPackage ./piped-proxy {
          src = inputs.piped-proxy-src;
        };
        piped-proxy-test = nixosTest (import ./piped-proxy/test.nix { inherit self; });
        piped-backend = callPackage ./piped-backend {
          src = inputs.piped-backend-src;
        };
        piped-backend-test = nixosTest (import ./piped-backend/test.nix { inherit self; });
        piped-frontend = callPackage ./piped-frontend {
          src = inputs.piped-frontend-src;
        };
        piped-frontend-test = nixosTest (import ./piped-frontend/test.nix { inherit self; });
        piped-test = nixosTest (import ./piped-test { inherit self; });
      };
      checks = flake-utils.lib.flattenTree {
        inherit (packages) piped-proxy-test piped-backend-test piped-frontend-test;
      };
      devShells = {
        package-update = mkShell {
          name = "package-update";
          nativeBuildInputs = [
            jq 
          ];
        };
      };
    }
  );
}
