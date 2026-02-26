# Elixir ecosystem builder
# Supports: mix | phoenix
{ pkgs, config }:

let
  # Version selection: elixir_1_16, elixir_1_17
  elixirPackage =
    if config.version != null then
      let
        parts = builtins.filter builtins.isString (builtins.split "\\." config.version);
        major = builtins.elemAt parts 0;
        minor = builtins.elemAt parts 1;
        attr = "elixir_${major}_${minor}";
      in
      pkgs.${attr} or pkgs.elixir
    else
      pkgs.elixir;

  shellHook = builtins.concatStringsSep "\n" (
    map (e: "export ${e}") config.envVars
  );
in
{
  devShell = pkgs.mkShell {
    buildInputs = [ elixirPackage pkgs.erlang ]
      ++ (map (d: pkgs.${d}) config.systemDeps);
    shellHook = ''
      echo "flkr: elixir $(elixir --version | tail -1) dev shell"
      ${shellHook}
    '';
  };

  package = pkgs.writeShellApplication {
    name = "build";
    runtimeInputs = [ elixirPackage pkgs.erlang ];
    text = ''
      cd "${config.src}"
      ${if config.buildCommand != null then config.buildCommand else "mix do deps.get, compile"}
    '';
  };

  app = {
    type = "app";
    program = let
      script = pkgs.writeShellScript "start" ''
        cd "${config.src}"
        ${if config.startCommand != null then config.startCommand else "mix phx.server"}
      '';
    in "${script}";
  };
}
