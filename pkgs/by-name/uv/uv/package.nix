{ lib
, cmake
, darwin
, fetchFromGitHub
, installShellFiles
, libiconv
, openssl
, pkg-config
, python3Packages
, rustPlatform
, stdenv
, testers
, uv
, nix-update-script
}:

python3Packages.buildPythonApplication rec {
  pname = "uv";
  version = "0.2.6";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "astral-sh";
    repo = "uv";
    rev = "refs/tags/${version}";
    hash = "sha256-8HKpqPkQ2FGaq0NrlBpnf49G3ikNhsS/rC/tBZ6de3g=";
  };

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "async_zip-0.0.17" = "sha256-Q5fMDJrQtob54CTII3+SXHeozy5S5s3iLOzntevdGOs=";
      "pubgrub-0.2.1" = "sha256-DtUK5k7Hfl5h9nFSSeD2zm4wBiVo4tScvFTUQWxTYlU=";
    };
  };

  nativeBuildInputs = [
    cmake
    installShellFiles
    pkg-config
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  buildInputs = [
    libiconv
    openssl
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  dontUseCmakeConfigure = true;

  cargoBuildFlags = [ "--package" "uv" ];

  env = {
    OPENSSL_NO_VENDOR = true;
  };

  postInstall = ''
    export HOME=$TMPDIR
    installShellCompletion --cmd uv \
      --bash <($out/bin/uv --generate-shell-completion bash) \
      --fish <($out/bin/uv --generate-shell-completion fish) \
      --zsh <($out/bin/uv --generate-shell-completion zsh)
  '';

  pythonImportsCheck = [
    "uv"
  ];

  passthru = {
    tests.version = testers.testVersion {
      package = uv;
    };
    updateScript = nix-update-script { };
  };

  meta = {
    description = "An extremely fast Python package installer and resolver, written in Rust";
    homepage = "https://github.com/astral-sh/uv";
    changelog = "https://github.com/astral-sh/uv/blob/${src.rev}/CHANGELOG.md";
    license = with lib.licenses; [ asl20 mit ];
    maintainers = with lib.maintainers; [ GaetanLepage ];
    mainProgram = "uv";
  };
}
