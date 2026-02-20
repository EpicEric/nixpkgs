{
  callPackage,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
  versionCheckHook,
  zig_0_15,
  rustPlatform,
  rustc,
  cargo,
  pkg-config,
  cmake,
  python3,
  gperf,
  zlib,
  expat,
  gcc,
  glibc,
  glib,
  cacert,
  gclient2nix,

  breakpointHook,
}:
let
  pin = lib.importJSON ./v8_pin.json;

  v8 = fetchurl {
    url = "https://github.com/lightpanda-io/zig-v8-fork/releases/download/v${pin.version}/libc_v8_${pin.v8_version}_${pin.${stdenv.system}.suffix}.a";
    hash = pin.${stdenv.system}.hash;

    # downloadToTemp = true;

    # postFetch = ''
    #   mkdir -p $out/lib
    #   mv $downloadedFile $out/lib/libc_v8.a
    #   ls -la && exit 1
    # '';
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "lightpanda";
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "lightpanda-io";
    repo = "browser";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zoA7n+h7heIECCP2DRVcRjREceJRgcgxQASHL1XqEXk=";
    fetchSubmodules = true;
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs)
      pname
      version
      src
      cargoRoot
      ;
    hash = "sha256-2eUx3gG6ufaEuHESGq33UGMNIN2W4LF96/QjyUFIops=";
  };

  cargoRoot = "src/html5ever";

  DEPOT_TOOLS_UPDATE = "0";
  DEPOT_TOOLS_BOOTSTRAP_PYTHON3 = "0";

  nativeBuildInputs = [
    # breakpointHook

    zig_0_15
    pkg-config
    cmake
    python3
    rustc
    cargo
    rustPlatform.cargoSetupHook
    # gperf
    gclient2nix.gclientUnpackHook
  ];

  buildInputs = [
    # expat.dev
    glib.dev
    # gcc
    # gcc.cc.lib
    # glibc.dev
    zlib
    cacert
  ];

  postConfigure = ''
    export HOME=$(mktemp -d)
    mkdir -p $ZIG_GLOBAL_CACHE_DIR/p
    cp -rL ${callPackage ./deps.nix { }}/* $ZIG_GLOBAL_CACHE_DIR/p/
    chmod -R +w $ZIG_GLOBAL_CACHE_DIR/p
  '';

  buildPhase = ''
    runHook preBuild

    zig build -Doptimize=ReleaseFast \
      -Dprebuilt_v8_path=${v8} \
      snapshot_creator -- src/snapshot.bin
    zig build -Doptimize=ReleaseFast \
      -Dsnapshot_path=../../snapshot.bin \
      -Dprebuilt_v8_path=${v8}

    runHook postBuild
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Headless browser designed for AI and automation";
    changelog = "https://github.com/lightpanda-io/browser/releases/tag/v${finalAttrs.version}";
    homepage = "https://lightpanda.io";
    license = lib.licenses.agpl3Only;
    mainProgram = "lightpanda";
    maintainers = with lib.maintainers; [ EpicEric ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
