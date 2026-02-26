# Go ecosystem builder
# Supports: gomod | gin
#
# Uses buildGoModule for sandboxed, cacheable builds.
# Requires vendored dependencies (vendor/) or an explicit vendorHash.
{ pkgs, config }:

let
  # Version selection: go_1_22, go_1_23, go_1_24, go_1_25
  goPackage =
    if config.version != null then
      let
        parts = builtins.filter builtins.isString (builtins.split "\\." config.version);
        major = builtins.elemAt parts 0;
        minor = builtins.elemAt parts 1;
        attr = "go_${major}_${minor}";
      in
      pkgs.${attr} or pkgs.go
    else
      pkgs.go;

  # Extract binary name from startCommand: "./flkr" → "flkr"
  binName = let
    cmd = if config.startCommand != null then config.startCommand else "./app";
    tokens = builtins.filter (x: builtins.isString x && x != "")
      (builtins.split " " cmd);
    firstToken = builtins.head tokens;
    segments = builtins.filter (x: builtins.isString x && x != "")
      (builtins.split "/" firstToken);
  in builtins.elemAt segments (builtins.length segments - 1);

  package = pkgs.buildGoModule {
    pname = binName;
    version = "0.1.0";
    src = config.src;
    vendorHash = config.vendorHash;
    go = goPackage;
    ldflags = [ "-s" "-w" ];
    # Tests run in a sandbox with no network, no services, no secrets.
    # Projects with integration tests (DB, APIs, etc.) will always fail.
    # Testing belongs in CI, not in the Nix build.
    doCheck = false;
  };

  shellHook = builtins.concatStringsSep "\n" (
    map (e: "export ${e}") config.envVars
  );
in
{
  devShell = pkgs.mkShell {
    buildInputs = [ goPackage pkgs.gopls ]
      ++ (map (d: pkgs.${d}) config.systemDeps);
    shellHook = ''
      echo "flkr: go $(go version) dev shell"
      ${shellHook}
    '';
  };

  inherit package;

  app = {
    type = "app";
    program = "${package}/bin/${binName}";
  };
}
