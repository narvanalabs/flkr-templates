# Go ecosystem builder
# Supports: gomod | gin
{ pkgs, config }:

let
  # Version selection: go_1_22, go_1_23
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

  package = pkgs.writeShellApplication {
    name = "build";
    runtimeInputs = [ goPackage ];
    text = ''
      cd "${config.src}"
      ${if config.buildCommand != null then config.buildCommand else "go build -o app ."}
    '';
  };

  app = {
    type = "app";
    program = let
      script = pkgs.writeShellScript "start" ''
        cd "${config.src}"
        ${if config.startCommand != null then config.startCommand else "./app"}
      '';
    in "${script}";
  };
}
