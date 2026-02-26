# Rust ecosystem builder
# Supports: cargo | actix
{ pkgs, config }:

let
  rustToolchain = [
    pkgs.rustc
    pkgs.cargo
    pkgs.rust-analyzer
  ];

  shellHook = builtins.concatStringsSep "\n" (
    map (e: "export ${e}") config.envVars
  );
in
{
  devShell = pkgs.mkShell {
    buildInputs = rustToolchain
      ++ (map (d: pkgs.${d}) config.systemDeps);
    shellHook = ''
      echo "flkr: rust $(rustc --version) dev shell"
      ${shellHook}
    '';
  };

  package = pkgs.writeShellApplication {
    name = "build";
    runtimeInputs = rustToolchain;
    text = ''
      cd "${config.src}"
      ${if config.buildCommand != null then config.buildCommand else "cargo build --release"}
    '';
  };

  app = {
    type = "app";
    program = let
      script = pkgs.writeShellScript "start" ''
        cd "${config.src}"
        ${if config.startCommand != null then config.startCommand else "./target/release/app"}
      '';
    in "${script}";
  };
}
