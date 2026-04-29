topLevel@{ lib, ... }:
let
  envoyLib = import ./lib.nix { inherit lib; };
in
{
  options.envoy = {
    sources = lib.mkOption {
      type = lib.types.attrsOf envoyLib.sourceType;
      default = { };
      description = "nvfetcher source definitions, written to nvfetcher.toml.";
      example = lib.literalExpression ''
        {
          helix.src.github = "helix-editor/helix";
          fuzzy-search.github = "onelocked/fuzzy-search.yazi";
        }
      '';
    };

    outputDir = lib.mkOption {
      type = lib.types.either lib.types.str lib.types.path;
      default = "envoy";
      example = lib.literalExpression "./envoy";
      description = ''
        Where `nvfetcher` writes `generated.nix` and `generated.json`,
        relative to the consuming flake. May be a string ("envoy") or a
        path (`./envoy`); a path lets the package set be read back from
        `${"\${outputDir}"}/generated.nix`.
      '';
    };
  };

  config.perSystem =
    { pkgs, ... }:
    {
      apps.write-sources = {
        meta.description = "Update envoy sources via nvfetcher.";
        program = "${
          import ./write-sources.nix {
            inherit pkgs envoyLib;
            inherit (topLevel.config.envoy) sources outputDir;
          }
        }/bin/write-sources";
      };

      legacyPackages.envoy =
        let
          outputDir = topLevel.config.envoy.outputDir;
          generatedPath = if lib.isPath outputDir then outputDir + "/generated.nix" else null;
          generated =
            if generatedPath != null && builtins.pathExists generatedPath then
              import generatedPath
            else
              (_: { });
        in
        pkgs.callPackage generated { };
    };
}
