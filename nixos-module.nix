{ envoyLib }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.envoy;
  generated =
    if cfg.generatedPath != null && builtins.pathExists cfg.generatedPath then
      import cfg.generatedPath
    else
      (_: { });
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
          nvfetcher-git = {
            src.git = "https://github.com/berberman/nvfetcher";
            fetch.github = "berberman/nvfetcher";
          };
          fuzzy-search.github = "onelocked/fuzzy-search.yazi";
        }
      '';
    };

    outputDir = lib.mkOption {
      type = lib.types.str;
      default = "envoy";
      description = ''
        Directory (relative to the consuming flake) where nvfetcher writes
        `generated.nix` and `generated.json`.
      '';
    };

    generatedPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the `generated.nix` file produced by `nvfetcher`. Usually
        `./envoy/generated.nix` from the consuming flake. If null or
        missing on disk, the package set is empty (useful before the first
        `write-sources` run).
      '';
    };

    package = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      readOnly = true;
      description = ''
        The resolved nvfetcher package set, equivalent to
        `pkgs.callPackage ./generated.nix { }`.
      '';
    };
  };

  config = {
    envoy.package = pkgs.callPackage generated { };
    _module.args.envoy = cfg.package;
  };
}
