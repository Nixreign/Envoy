{ nixpkgs }:
topLevel@{ lib, ... }:
let
  envoyLib = import ./lib.nix { inherit lib; };
  # Sources are fixed-output derivations, so the system used for
  # callPackage doesn't affect what gets fetched. Pin a system to keep
  # `config.envoy.package` evaluable at top-level (no perSystem).
  fetchPkgs = nixpkgs.legacyPackages.x86_64-linux;
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

    package = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      readOnly = true;
      visible = false;
      description = ''
        Resolved package set from `${"\${outputDir}"}/generated.nix`.
        Access srcs via `config.envoy.package.<name>.src`.
      '';
    };
  };

  config.envoy.package =
    let
      outputDir = topLevel.config.envoy.outputDir;
      generatedPath = if lib.isPath outputDir then outputDir + "/generated.nix" else null;
      generated =
        if generatedPath != null && builtins.pathExists generatedPath then
          import generatedPath
        else
          (_: { });
    in
    fetchPkgs.callPackage generated { };

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
    };
}
