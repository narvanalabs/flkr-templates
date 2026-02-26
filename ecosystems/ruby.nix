# Ruby ecosystem builder
# Supports: bundler | rails
{ pkgs, config }:

let
  # Version selection: ruby_3_2, ruby_3_3
  rubyPackage =
    if config.version != null then
      let
        parts = builtins.filter builtins.isString (builtins.split "\\." config.version);
        major = builtins.elemAt parts 0;
        minor = builtins.elemAt parts 1;
        attr = "ruby_${major}_${minor}";
      in
      pkgs.${attr} or pkgs.ruby
    else
      pkgs.ruby;

  pmPackages = [ pkgs.bundler ];

  shellHook = builtins.concatStringsSep "\n" (
    map (e: "export ${e}") config.envVars
  );
in
{
  devShell = pkgs.mkShell {
    buildInputs = [ rubyPackage ] ++ pmPackages
      ++ (map (d: pkgs.${d}) config.systemDeps);
    shellHook = ''
      echo "flkr: ruby $(ruby --version) dev shell"
      ${shellHook}
    '';
  };

  package = pkgs.writeShellApplication {
    name = "build";
    runtimeInputs = [ rubyPackage ] ++ pmPackages;
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
