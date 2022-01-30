{
  description = "Nix helper for building SwiftPM projects.";
  outputs = { self }: {
    lib = import ./.;
  };
}
