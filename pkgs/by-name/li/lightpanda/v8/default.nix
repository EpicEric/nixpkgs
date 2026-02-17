{
  callPackage,
  fetchFromGitHub,
  lib,
  stdenv,
  zig_0_15,
  pkg-config,
  cmake,
  python3,
  gperf,
  zlib,
  expat,
  gcc,
  glibc,
  glib,
  google-cloud-sdk,

  runCommand,

  breakpointHook,
}:
let
  zig = zig_0_15;

  crtFiles = runCommand "crt-files" { } ''
    mkdir -p $out/lib
    cp -r ${gcc.cc}/lib/gcc $out/lib/gcc
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zig-v8-fork";
  version = "0.2.9";

  src = fetchFromGitHub {
    owner = "lightpanda-io";
    repo = "zig-v8-fork";
    tag = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  DEPOT_TOOLS_UPDATE = "0";
  DEPOT_TOOLS_BOOTSTRAP_PYTHON3 = "0";

  nativeBuildInputs = [
    breakpointHook

    zig
    pkg-config
    cmake
    python3
    gperf
    google-cloud-sdk
  ];

  buildInputs = [
    expat.dev
    glib.dev
    gcc
    gcc.cc.lib
    glibc.dev
    zlib
    crtFiles
  ];

  postConfigure = ''
    mkdir -p $ZIG_GLOBAL_CACHE_DIR/p
    cp -rL ${callPackage ./deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p/
    chmod -R +w $ZIG_GLOBAL_CACHE_DIR/p
  '';
})
