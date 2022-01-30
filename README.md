# nixSwiftPM

A helper for building SwiftPM projects in Nix.

For now, it builds only executable product defined in Package.swift. An example:

```nix
{ pkgs ? import <nixpkgs> { } }:
let
  nixSwiftPM = import ./nixSwiftPM.nix { };
in nixSwiftPM.buildExecutableProduct {
  src = ./.;
  productName = "awesome-cli"; # product name as defined in Package.swift
  executableName = "awesome";  # Rename the final output
}
```

## FAQ

### Why not just run `swift build`?

In its current state, `nixSwiftPM` takes care of downloading source dependencies for SwiftPM according to its
Package.resolved. Each dependency is downloaded and unpacked as a Nix derivation. This way, we take advantage
of Nix's caching mechanism, leading us one step closer to hermetic build output.

### Does that mean Package.resolved must be present?

Yes.

### What's the build setting?

By default, the target is built in release configuration. You can change that to `debug` with the
`buildConfig` argument. Additional arguments for `swift build` can be passed by `additionalFlags`.

### What if I need more build time or runtime dependencies?

You can pass in additional `nativeBuildInputs` and/or `buildInputs` in the argument set.

### How about the final output?

By default, the built executable is placed in `$out/bin/`. You may completely override the `installPhase` as
you see fit.
