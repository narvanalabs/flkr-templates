# flkr-templates

[![Nix Flake](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![Ecosystems](https://img.shields.io/static/v1?label=ecosystems&message=8&color=00B4D8)](https://github.com/narvanalabs/flkr-templates#supported-ecosystems)
[![Platforms](https://img.shields.io/badge/platforms-linux%20%7C%20darwin-grey?logo=linux&logoColor=white)](https://github.com/narvanalabs/flkr-templates)
[![License: MIT](https://img.shields.io/badge/license-MIT-green?logo=opensourceinitiative&logoColor=white)](LICENSE)

Reusable Nix builders for **flkr-generated flakes**.

`flkr-templates` is the bridge between [flkr](https://github.com/narvanalabs/flkr)'s
language/framework detection and Nix flakes — flkr tells you *what* the project is,
this repo tells Nix *how* to build and run it.

## Quick start

Add `flkr-templates` as a flake input and delegate your outputs to `mkApp`:

```nix
{
  description = "my-app — flkr-generated flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flkr-templates.url = "github:narvanalabs/flkr-templates";
  };

  outputs = { self, nixpkgs, flkr-templates, ... }:
    flkr-templates.lib.mkApp {
      inherit nixpkgs;
      src = ./.;

      ecosystem = "node";       # node | python | go | rust | ruby | elixir | php | java
      framework = "nextjs";     # nextjs, django, gin, actix, phoenix, rails, ...
      packageManager = "npm";   # npm, yarn, pnpm, pip, poetry, gomod, cargo, ...

      # optional overrides:
      # version       = "22.0.0";
      # buildCommand  = "npm run build";
      # startCommand  = "npm start";
      # outputDir     = ".next";
      # port          = 3000;
      # systemDeps    = [ "pkg-config" "openssl" ];
      # envVars       = [ "FOO=bar" ];
      # vendorHash    = null;   # Go: hash of vendored deps
      # cargoHash     = null;   # Rust: hash of cargo deps
    };
}
```

This produces a standard flake with:

| Output | Description |
|---|---|
| `devShells.default` | Language/tooling-appropriate development shell |
| `packages.default` | Build wrapper aligned with the ecosystem defaults |
| `apps.default` | Runs your service or application |

Outputs are generated for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin`.

## How `mkApp` works

`lib/mkApp.nix` is the core orchestrator. It:

1. **Validates** the ecosystem against `lib/defaults.nix`.
2. **Merges defaults** in order of precedence: explicit args > framework defaults > package-manager defaults > ecosystem defaults.
3. **Loads the ecosystem builder** from `ecosystems/<ecosystem>.nix`.
4. **Wraps** the result in `forAllSystems` for multi-platform output.

### Full signature

```nix
flkr-templates.lib.mkApp {
  nixpkgs        = <flake input>;
  src            = ./.;
  ecosystem      = "node" | "python" | "go" | "rust" | "ruby" | "elixir" | "php" | "java";

  # optional
  version        = null;    # ecosystem-specific runtime version
  packageManager = null;    # override detected package manager
  framework      = null;    # framework name
  buildCommand   = null;    # shell command
  startCommand   = null;    # shell command
  outputDir      = null;    # relative directory
  port           = null;    # integer
  systemDeps     = [ ];     # extra nixpkgs attrs
  envVars        = [ ];     # "KEY=value" strings
  vendorHash     = null;    # Go vendor hash
  cargoHash      = null;    # Rust Cargo.lock hash
}
```

## Supported ecosystems

| Ecosystem | Default port | Default PM | Frameworks |
|---|---|---|---|
| **Node** | 3000 | npm | nextjs, nuxt, remix, vite |
| **Python** | 8000 | pip | django, flask, fastapi |
| **Go** | 8080 | gomod | gin |
| **Rust** | 8080 | cargo | actix |
| **Ruby** | 3000 | bundler | rails |
| **Elixir** | 4000 | mix | phoenix |
| **PHP** | 8000 | composer | laravel |
| **Java** | 8080 | maven | spring |

### Node

Package managers: `npm`, `yarn`, `pnpm`

Version selection: `"18.x"`, `"20.x"`, `"22.x"` map to `pkgs.nodejs_18`, etc.

Framework output dirs: nextjs (`.next`), nuxt (`.output`), remix (`build`), vite (`dist`).

### Python

Package managers: `pip`, `poetry`, `pipenv`, `uv`

Version selection: `"3.11.x"`, `"3.12.x"`, `"3.13.x"` map to `pkgs.python311`, etc.

Framework defaults: django (`manage.py runserver`), flask (`flask run`, port 5000), fastapi (`uvicorn`).

### Go

Version selection: `"1.22.x"`, `"1.23.x"` map to `pkgs.go_1_22`, etc.

Dev shell includes `go`, `gopls`, and any extra `systemDeps`. Pass `vendorHash` for reproducible builds.

### Rust

Dev shell includes `rustc`, `cargo`, and `rust-analyzer`. Pass `cargoHash` for reproducible builds.

### Ruby

Framework: `rails` sets build to `bundle exec rake assets:precompile` and start to `bundle exec rails server -b 0.0.0.0`.

### Elixir

Framework: `phoenix` adds `inotify-tools` to system deps. Dev shell includes Elixir and Erlang.

### PHP

Framework: `laravel` sets build to `composer install --no-dev --optimize-autoloader` and start to `php artisan serve`.

### Java

Package managers: `maven`, `gradle` (each with their own build/start defaults).

Version selection: `"17.x"`, `"21.x"`, `"23.x"` map to `pkgs.jdk17`, etc. Dev shell exports `JAVA_HOME`.

## Project structure

```
flake.nix                  # exports lib.mkApp
lib/
  mkApp.nix                # core orchestrator
  defaults.nix             # default commands, ports, packages per ecosystem
  forAllSystems.nix        # multi-platform helper
ecosystems/
  node.nix                 # Node.js builder
  python.nix               # Python builder
  go.nix                   # Go builder
  rust.nix                 # Rust builder
  ruby.nix                 # Ruby builder
  elixir.nix               # Elixir builder
  php.nix                  # PHP builder
  java.nix                 # Java builder
```

## License

[MIT](LICENSE)
