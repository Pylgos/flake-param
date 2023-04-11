{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/22.11";
  };

  outputs = inputs: {
    body = flake-param: flake-param.lib.parametrize
      {
        inherit inputs; compat = true;
      }
      ({ self, nixpkgs }: { localSystem, ... }@args: {
        packages.${localSystem.system}.pkgA = nixpkgs.legacyPackages.${localSystem.system}.zlib;
      });
  };
}
