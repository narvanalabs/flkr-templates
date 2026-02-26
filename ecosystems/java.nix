# Java ecosystem builder
# Supports: maven, gradle | spring
{ pkgs, config }:

let
  # Version selection: jdk17, jdk21, jdk23
  jdkPackage =
    if config.version != null then
      let
        major = builtins.head (builtins.filter builtins.isString (builtins.split "\\." config.version));
        attr = "jdk${major}";
      in
      pkgs.${attr} or pkgs.jdk
    else
      pkgs.jdk;

  pmPackages = {
    maven = [ pkgs.maven ];
    gradle = [ pkgs.gradle ];
  }.${config.packageManager} or [ ];

  shellHook = builtins.concatStringsSep "\n" (
    map (e: "export ${e}") config.envVars
  );
in
{
  devShell = pkgs.mkShell {
    buildInputs = [ jdkPackage ] ++ pmPackages
      ++ (map (d: pkgs.${d}) config.systemDeps);
    shellHook = ''
      echo "flkr: java $(java --version 2>&1 | head -1) dev shell"
      export JAVA_HOME="${jdkPackage.home}"
      ${shellHook}
    '';
  };

  package = pkgs.writeShellApplication {
    name = "build";
    runtimeInputs = [ jdkPackage ] ++ pmPackages;
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
