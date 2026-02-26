# Rust ecosystem builder
# Supports: cargo | actix
#
# Uses buildRustPackage for sandboxed, cacheable builds.
# Resolves dependencies from Cargo.lock (preferred) or explicit cargoHash.
{ pkgs, config }:

let
  # Extract binary name from startCommand: "./target/release/myapp" → "myapp"
  binName = let
    cmd = if config.startCommand != null then config.startCommand else "./app";
    tokens = builtins.filter (x: builtins.isString x && x != "")
      (builtins.split " " cmd);
    firstToken = builtins.head tokens;
    segments = builtins.filter (x: builtins.isString x && x != "")
      (builtins.split "/" firstToken);
  in builtins.elemAt segments (builtins.length segments - 1);

  package = pkgs.rustPlatform.buildRustPackage ({
    pname = binName;
    version = "0.1.0";
    src = config.src;
    nativeBuildInputs = map (d: pkgs.${d}) config.systemDeps;
  } // (if config.cargoHash != null then {
    cargoHash = config.cargoHash;
  } else {
    cargoLock.lockFile = config.src + "/Cargo.lock";
  }));

  shellHook = builtins.concatStringsSep "\n" (
    map (e: "export ${e}") config.envVars
  );
in
{
  devShell = pkgs.mkShell {
    buildInputs = [
      pkgs.rustc
      pkgs.cargo
      pkgs.rust-analyzer
    ] ++ (map (d: pkgs.${d}) config.systemDeps);
    shellHook = ''
      echo "flkr: rust $(rustc --version) dev shell"
      ${shellHook}
    '';
  };

  inherit package;

  app = {
    type = "app";
    program = "${package}/bin/${binName}";
  };
}
