# mkApp — core orchestrator for flkr-generated flakes.
# Called as: flkr-templates.lib.mkApp { nixpkgs, src, ecosystem, ... }
{
  nixpkgs,
  src,
  ecosystem,
  version ? null,
  packageManager ? null,
  framework ? null,
  buildCommand ? null,
  startCommand ? null,
  outputDir ? null,
  port ? null,
  systemDeps ? [ ],
  envVars ? [ ],
  # Go: hash of vendored deps. null = use vendor/ dir (recommended).
  vendorHash ? null,
  # Rust: hash of cargo deps. null = use Cargo.lock from source.
  cargoHash ? null,
}:

let
  forAllSystems = import ./forAllSystems.nix;
  defaults = import ./defaults.nix;

  knownEcosystems = builtins.attrNames defaults.ecosystems;

  # Validate ecosystem
  _ = assert builtins.elem ecosystem knownEcosystems
    || throw "flkr-templates: unknown ecosystem '${ecosystem}'. Known: ${builtins.concatStringsSep ", " knownEcosystems}";
    true;

  ecoDefaults = defaults.ecosystems.${ecosystem};

  # Resolve package manager: explicit > ecosystem default
  resolvedPM = if packageManager != null then packageManager else ecoDefaults.packageManager;

  # Framework defaults (if a known framework is specified)
  frameworkDefaults =
    if framework != null && builtins.hasAttr "frameworks" ecoDefaults && builtins.hasAttr framework ecoDefaults.frameworks
    then ecoDefaults.frameworks.${framework}
    else { };

  # Package-manager-specific defaults (for java's maven/gradle split)
  pmDefaults =
    if builtins.hasAttr "packageManagers" ecoDefaults && builtins.hasAttr resolvedPM ecoDefaults.packageManagers
    then ecoDefaults.packageManagers.${resolvedPM}
    else { };

  # Merge order: explicit args > framework defaults > package manager defaults > ecosystem defaults
  resolve = explicit: fwDefault: pmDefault: ecoDefault:
    if explicit != null then explicit
    else if fwDefault != null then fwDefault
    else if pmDefault != null then pmDefault
    else ecoDefault;

  config = {
    inherit ecosystem src version framework envVars vendorHash cargoHash;
    packageManager = resolvedPM;
    buildCommand = resolve buildCommand (frameworkDefaults.buildCommand or null) (pmDefaults.buildCommand or null) ecoDefaults.buildCommand;
    startCommand = resolve startCommand (frameworkDefaults.startCommand or null) (pmDefaults.startCommand or null) ecoDefaults.startCommand;
    outputDir = resolve outputDir (frameworkDefaults.outputDir or null) null null;
    port = resolve port (frameworkDefaults.port or null) null ecoDefaults.port;
    systemDeps = systemDeps ++ (frameworkDefaults.systemDeps or [ ]);
  };

  ecosystemBuilder = import ../ecosystems/${ecosystem}.nix;
in
forAllSystems (system:
  let
    pkgs = import nixpkgs { inherit system; };
    result = ecosystemBuilder { inherit pkgs config; };
  in {
    devShells.default = result.devShell;
    packages.default = result.package;
    apps.default = result.app;
  }
)
