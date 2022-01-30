{ pkgs ? import <nixpkgs> {} }:
let
  fetchDependencies = resolvedDeps: let
    checkout = { package, repositoryURL, state, ... }:
      let
        repo = builtins.fetchGit {
          url = repositoryURL;
          rev = state.revision;
          allRefs = true;
        };
      in pkgs.runCommand "download-${package}" { } ''
        mkdir $out
        ln -s ${repo} $out/${package}
      '';
  in pkgs.symlinkJoin {
    name = "checkouts";
    paths = map checkout resolvedDeps;
  };

  generateWorkspaceStateJSON = resolvedDeps: let
    depToObject = { package, repositoryURL, state, ... }: {
      basedOn = null;
      packageRef = {
        identity = pkgs.lib.toLower package;
        isLocal = false;
        name = package;
        path = repositoryURL;
      };
      state = {
        checkoutState = state;
        name = "checkout";
      };
      subpath = package;
    };
    state = {
      object = { artifacts = []; dependencies = map depToObject resolvedDeps; };
      version = 4;
    };
  in pkgs.runCommand "build-swift-pm-dependencies-state" { } ''
    echo '${builtins.toJSON state}' | ${pkgs.jq}/bin/jq > $out
  '';
in {
  buildExecutableProduct = {
    src,
    productName,
    buildConfig ? "release",
    executableName ? productName,
    nativeBuildInputs ? [],
    buildInputs ? [],
    additionalFlags ? "",
    installPhase ? ''
      mkdir -p $out/bin
      cp .build/release/${productName} $out/bin/${executableName}
    ''
  }:
  let
    resolvedDeps = (builtins.fromJSON (builtins.readFile "${src}/Package.resolved")).object.pins;
  in
    pkgs.stdenv.mkDerivation {
      name = executableName;
      nativeBuildInputs = [ pkgs.swift ] ++ nativeBuildInputs;
      buildInputs = buildInputs;
      phases = [ "unpackPhase" "buildPhase" "installPhase" ];
      buildPhase = ''
        rm -rf .build
        mkdir -p .build
        cp ${generateWorkspaceStateJSON resolvedDeps} .build/workspace-state.json
        chmod 755 .build/workspace-state.json # SwiftPM wants write access for some reason
        ln -s ${fetchDependencies resolvedDeps} .build/checkouts
        swift build -c ${buildConfig} --product ${productName} ${additionalFlags}
      '';

      inherit src installPhase;
    };
}
