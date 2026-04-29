{ envoyLib }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.envoy;
  generatedPath = cfg.outputDir + "/generated.nix";
  generated =
    if cfg.outputDir != null && builtins.pathExists generatedPath then
      import generatedPath
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
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./envoy";
      description = ''
        Path to the directory where `nvfetcher` writes `generated.nix` and
        `generated.json` — usually `./envoy` from the consuming flake.
        The module reads `${"\${outputDir}"}/generated.nix` to build the
        package set, and `write-sources` writes back to the same dir.
        If null or the file doesn't exist, the package set is empty
        (useful before the first `write-sources` run).
      '';
    };

    package = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      readOnly = true;
      description = ''
        The resolved nvfetcher package set, equivalent to
        `pkgs.callPackage ./generated.nix { }`. Consumers decide how to
        expose it — e.g. `_module.args.envoy = config.envoy.package;` or
        passed explicitly to whichever modules need it.
      '';
    };
  };

  config.envoy.package = pkgs.callPackage generated { };
}
