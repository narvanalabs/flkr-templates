# Pure-builtins multi-system helper (no flake-utils dependency).
# Takes a function (system -> attrset) and flips it to flake-shaped output.
f:
let
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  # For each system, evaluate f and collect into { <system> = f system; }
  perSystem = builtins.listToAttrs (
    map (system: {
      name = system;
      value = f system;
    }) systems
  );

  # Collect all output keys from the first system's result
  outputKeys = builtins.attrNames (f (builtins.head systems));

  # Flip from { system.outputKey } to { outputKey.system }
  flip = key: builtins.listToAttrs (
    map (system: {
      name = system;
      value = perSystem.${system}.${key};
    }) systems
  );
in
builtins.listToAttrs (
  map (key: {
    name = key;
    value = flip key;
  }) outputKeys
)
