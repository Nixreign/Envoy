{
  description = "envoy: declarative nvfetcher source definitions for Nix flakes.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      envoyLib = import ./lib.nix { inherit (nixpkgs) lib; };
    in
    {
      lib = {
        inherit (envoyLib) sourceType evalSources stripInternal;

        mkWriteSources =
          {
            pkgs,
            sources,
            outputDir ? "envoy",
          }:
          import ./write-sources.nix {
            inherit
              pkgs
              sources
              outputDir
              envoyLib
              ;
          };

        # Convenience bundle: returns both the resolved package set and
        # the `write-sources` app for a given flake. `outputDir` may be a
        # path (e.g. `./envoy`) — the package set is read from
        # `${outputDir}/generated.nix`, and the script writes back there.
        mkEnvoy =
          {
            pkgs,
            sources,
            outputDir ? "envoy",
          }:
          let
            generatedPath = if nixpkgs.lib.isPath outputDir then outputDir + "/generated.nix" else null;
            generated =
              if generatedPath != null && builtins.pathExists generatedPath then
                import generatedPath
              else
                (_: { });
          in
          {
            packages = pkgs.callPackage generated { };
            writeSources = self.lib.mkWriteSources { inherit pkgs sources outputDir; };
          };
      };

      flakeModules.default = import ./flake-module.nix { inherit nixpkgs; };
      flakeModules.envoy = self.flakeModules.default;
    };
}
