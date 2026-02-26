# Python ecosystem builder
# Supports: pip, poetry, pipenv, uv | django, flask, fastapi
{ pkgs, config }:

let
  # Version selection: python311, python312, python313
  pythonPackage =
    if config.version != null then
      let
        parts = builtins.filter builtins.isString (builtins.split "\\." config.version);
        major = builtins.elemAt parts 0;
        minor = builtins.elemAt parts 1;
        attr = "python${major}${minor}";
      in
      pkgs.${attr} or pkgs.python3
    else
      pkgs.python3;

  pmPackages = {
    pip = [ ];
    poetry = [ pkgs.poetry ];
    pipenv = [ pkgs.pipenv ];
    uv = [ pkgs.uv ];
  }.${config.packageManager} or [ ];

  shellHook = builtins.concatStringsSep "\n" (
    map (e: "export ${e}") config.envVars
  );
in
{
  devShell = pkgs.mkShell {
    buildInputs = [ pythonPackage ] ++ pmPackages
      ++ (map (d: pkgs.${d}) config.systemDeps);
    shellHook = ''
      echo "flkr: python $(python3 --version) dev shell"
      ${shellHook}
    '';
  };

  package = pkgs.writeShellApplication {
    name = "build";
    runtimeInputs = [ pythonPackage ] ++ pmPackages;
    text = ''
      cd "${config.src}"
      ${if config.buildCommand != null then config.buildCommand else "echo 'No build command configured'"}
    '';
  };

  app = {
    type = "app";
    program = let
      script = pkgs.writeShellScript "start" ''
        cd "${config.src}"
        ${if config.startCommand != null then config.startCommand else "echo 'No start command configured'"}
      '';
    in "${script}";
  };
}
