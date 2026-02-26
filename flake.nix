{
  description = "flkr-templates — reusable Nix builders for flkr-generated flakes";

  outputs = { self, ... }: {
    lib.mkApp = import ./lib/mkApp.nix;
  };
}
