# Node.js ecosystem builder
# Supports: npm, yarn, pnpm | nextjs, nuxt, remix, vite
{ pkgs, config }:

let
  # Version selection: nodejs_18, nodejs_20, nodejs_22
  nodePackage =
    if config.version != null then
      let
        major = builtins.head (builtins.split "\\." config.version);
        attr = "nodejs_${major}";
      in
      pkgs.${attr} or pkgs.nodejs
    else
      pkgs.nodejs;

  pmPackage = {
    npm = [ ];
    yarn = [ pkgs.yarn ];
    pnpm = [ pkgs.nodePackages.pnpm ];
  }.${config.packageManager} or [ ];

  shellHook = builtins.concatStringsSep "\n" (
    map (e: "export ${e}") config.envVars
  );
in
{
  devShell = pkgs.mkShell {
    buildInputs = [ nodePackage ] ++ pmPackage
      ++ (map (d: pkgs.${d}) config.systemDeps);
    shellHook = ''
      echo "flkr: node $(node --version) dev shell"
      ${shellHook}
    '';
  };

  package = pkgs.writeShellApplication {
    name = "build";
    runtimeInputs = [ nodePackage ] ++ pmPackage;
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
