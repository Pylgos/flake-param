{
  inputs = {
    nixpkgs-lib.url = "github:nixos/nixpkgs/22.11?dir=lib";
  };

  outputs = { self, nixpkgs-lib }:
    {
      lib = import ./lib.nix { lib = self.lib // nixpkgs-lib.lib; };
      __functor = self: self.lib.parametrize;
      
      tests =
        let
          results = import ./test.nix { lib = self.lib // nixpkgs-lib.lib; };
        in
          if results == []
          then "all tests passed"
          else throw (builtins.toJSON results);
      
      test = (builtins.getFlake "path:/home/aoi/work/nix/flake-param/test").body self;
    };
}
