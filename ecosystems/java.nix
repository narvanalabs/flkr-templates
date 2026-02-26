# Java ecosystem builder
# Supports: maven, gradle | spring
#
# Uses stdenv.mkDerivation to build the JAR.
# Note: Maven/Gradle need pre-fetched deps or network access (--option sandbox false)
# for the initial build. The PaaS pipeline handles this.
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

  # Determine where the JAR ends up based on package manager
  jarDir = if config.packageManager == "gradle" then "build/libs" else "target";

  package = pkgs.stdenv.mkDerivation {
    pname = "java-app";
    version = config.appVersion;
    src = config.src;
    nativeBuildInputs = [ jdkPackage ] ++ pmPackages
      ++ (map (d: pkgs.${d}) config.systemDeps);
    JAVA_HOME = "${jdkPackage.home}";
    buildPhase = ''
      runHook preBuild
      ${if config.buildCommand != null then config.buildCommand else "echo 'No build command configured'"}
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/bin
      cp ${jarDir}/*.jar $out/lib/
      cat > $out/bin/start <<WRAPPER
      #!/bin/sh
      exec ${jdkPackage}/bin/java -jar $out/lib/*.jar "\$@"
      WRAPPER
      chmod +x $out/bin/start
      runHook postInstall
    '';
  };

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

  inherit package;

  app = {
    type = "app";
    program = "${package}/bin/start";
  };
}
