# PHP ecosystem builder
# Supports: composer | laravel
{ pkgs, config }:

let
  # Version selection: php82, php83, php84
  phpPackage =
    if config.version != null then
      let
        parts = builtins.filter builtins.isString (builtins.split "\\." config.version);
        major = builtins.elemAt parts 0;
        minor = builtins.elemAt parts 1;
        attr = "php${major}${minor}";
      in
      pkgs.${attr} or pkgs.php
    else
      pkgs.php;

  pmPackages = [ pkgs.phpPackages.composer ];

  shellHook = builtins.concatStringsSep "\n" (
    map (e: "export ${e}") config.envVars
  );
in
{
  devShell = pkgs.mkShell {
    buildInputs = [ phpPackage ] ++ pmPackages
      ++ (map (d: pkgs.${d}) config.systemDeps);
    shellHook = ''
      echo "flkr: php $(php --version | head -1) dev shell"
      ${shellHook}
    '';
  };

  package = pkgs.writeShellApplication {
    name = "build";
    runtimeInputs = [ phpPackage ] ++ pmPackages;
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
