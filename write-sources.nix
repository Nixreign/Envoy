{
  pkgs,
  sources,
  outputDir ? "envoy",
  envoyLib,
}:
let
  lib = pkgs.lib;
  evaluated = envoyLib.evalSources sources;
  processedSources = lib.mapAttrs (_: envoyLib.stripInternal) evaluated;
  tomlFile = (pkgs.formats.toml { }).generate "nvfetcher.toml" processedSources;
  unlockedNames = lib.attrNames (lib.filterAttrs (_: s: !s.locked) evaluated);
  unlockedNamesStr = lib.concatStringsSep "\n" unlockedNames;
  allNamesStr = lib.concatStringsSep "\n" (lib.attrNames evaluated);
in
pkgs.writeShellApplication {
  name = "write-sources";
  runtimeInputs = [
    pkgs.nvfetcher
    pkgs.ripgrep
  ];
  text = ''
    # Without a filter: update unlocked only (safe default).
    # With an explicit filter: match against all sources, so users
    # can force-update a locked entry by naming it.
    if [ $# -eq 0 ]; then
      user_filter="."
      candidates=${lib.escapeShellArg unlockedNamesStr}
    else
      user_filter="$1"
      candidates=${lib.escapeShellArg allNamesStr}
    fi
    # nvfetcher's -f matches by full source name, so we build an
    # alternation of just the names we want to update.
    matched=$(printf '%s\n' "$candidates" \
      | rg -e "$user_filter" || true)
    if [ -z "$matched" ]; then
      echo "No sources match '$user_filter'; nothing to update." >&2
      exit 0
    fi
    regex="^($(echo "$matched" | paste -sd'|' -))$"
    nvfetcher -c ${tomlFile} -o ${lib.escapeShellArg outputDir} -f "$regex"
  '';
}
