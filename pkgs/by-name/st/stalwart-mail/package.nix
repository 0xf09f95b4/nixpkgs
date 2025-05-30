{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  protobuf,
  bzip2,
  openssl,
  sqlite,
  foundationdb,
  zstd,
  stdenv,
  darwin,
  nix-update-script,
  nixosTests,
  rocksdb,
  callPackage,
}:

rustPlatform.buildRustPackage rec {
  pname = "stalwart-mail";
  version = "0.11.7";

  src = fetchFromGitHub {
    owner = "stalwartlabs";
    repo = "mail-server";
    tag = "v${version}";
    hash = "sha256-pBCj/im5UB7A92LBuLeB6EAHTJEuN62BG5Nkj8qsNNA=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-B+xsTVsh9QBAybKiJq0Sb7rveOsH05vuCmNQ5t/UZnk=";

  nativeBuildInputs = [
    pkg-config
    protobuf
    rustPlatform.bindgenHook
  ];

  buildInputs =
    [
      bzip2
      openssl
      sqlite
      zstd
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ foundationdb ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      darwin.apple_sdk.frameworks.CoreFoundation
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

  # Issue: https://github.com/stalwartlabs/mail-server/issues/1104
  buildNoDefaultFeatures = true;
  buildFeatures = [
    "sqlite"
    "postgres"
    "mysql"
    "rocks"
    "elastic"
    "s3"
    "redis"
  ];

  env = {
    OPENSSL_NO_VENDOR = true;
    ZSTD_SYS_USE_PKG_CONFIG = true;
    ROCKSDB_INCLUDE_DIR = "${rocksdb}/include";
    ROCKSDB_LIB_DIR = "${rocksdb}/lib";
  };

  postInstall = ''
    mkdir -p $out/etc/stalwart

    mkdir -p $out/lib/systemd/system

    substitute resources/systemd/stalwart-mail.service $out/lib/systemd/system/stalwart-mail.service \
      --replace "__PATH__" "$out"
  '';

  checkFlags = [
    # Require running mysql, postgresql daemon
    "--skip=directory::imap::imap_directory"
    "--skip=directory::internal::internal_directory"
    "--skip=directory::ldap::ldap_directory"
    "--skip=directory::sql::sql_directory"
    "--skip=directory::oidc::oidc_directory"
    "--skip=store::blob::blob_tests"
    "--skip=store::lookup::lookup_tests"
    "--skip=smtp::lookup::sql::lookup_sql"
    # thread 'directory::smtp::lmtp_directory' panicked at tests/src/store/mod.rs:122:44:
    # called `Result::unwrap()` on an `Err` value: Os { code: 2, kind: NotFound, message: "No such file or directory" }
    "--skip=directory::smtp::lmtp_directory"
    # thread 'imap::imap_tests' panicked at tests/src/imap/mod.rs:436:14:
    # Missing store type. Try running `STORE=<store_type> cargo test`: NotPresent
    "--skip=imap::imap_tests"
    # thread 'jmap::jmap_tests' panicked at tests/src/jmap/mod.rs:303:14:
    # Missing store type. Try running `STORE=<store_type> cargo test`: NotPresent
    "--skip=jmap::jmap_tests"
    # Failed to read system DNS config: io error: No such file or directory (os error 2)
    "--skip=smtp::inbound::data::data"
    # Expected "X-My-Header: true" but got Received: from foobar.net (unknown [10.0.0.123])
    "--skip=smtp::inbound::scripts::sieve_scripts"
    # panicked at tests/src/smtp/outbound/smtp.rs:173:5:
    "--skip=smtp::outbound::smtp::smtp_delivery"
    # thread 'smtp::queue::retry::queue_retry' panicked at tests/src/smtp/queue/retry.rs:119:5:
    # assertion `left == right` failed
    #   left: [1, 2, 2]
    #  right: [1, 2, 3]
    "--skip=smtp::queue::retry::queue_retry"
    # Missing store type. Try running `STORE=<store_type> cargo test`: NotPresent
    "--skip=store::store_tests"
    # thread 'config::parser::tests::toml_parse' panicked at crates/utils/src/config/parser.rs:463:58:
    # called `Result::unwrap()` on an `Err` value: "Expected ['\\n'] but found '!' in value at line 70."
    "--skip=config::parser::tests::toml_parse"
    # error[E0432]: unresolved import `r2d2_sqlite`
    # use of undeclared crate or module `r2d2_sqlite`
    "--skip=backend::sqlite::pool::SqliteConnectionManager::with_init"
    # thread 'smtp::reporting::analyze::report_analyze' panicked at tests/src/smtp/reporting/analyze.rs:88:5:
    # assertion `left == right` failed
    #   left: 0
    #  right: 12
    "--skip=smtp::reporting::analyze::report_analyze"
    # thread 'smtp::inbound::dmarc::dmarc' panicked at tests/src/smtp/inbound/mod.rs:59:26:
    # Expected empty queue but got Reload
    "--skip=smtp::inbound::dmarc::dmarc"
    # thread 'smtp::queue::concurrent::concurrent_queue' panicked at tests/src/smtp/inbound/mod.rs:65:9:
    # assertion `left == right` failed
    "--skip=smtp::queue::concurrent::concurrent_queue"
    # Failed to read system DNS config: io error: No such file or directory (os error 2)
    "--skip=smtp::inbound::auth::auth"
    # Failed to read system DNS config: io error: No such file or directory (os error 2)
    "--skip=smtp::inbound::antispam::antispam"
    # Failed to read system DNS config: io error: No such file or directory (os error 2)
    "--skip=smtp::inbound::vrfy::vrfy_expn"
  ];

  doCheck = !(stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64);

  passthru = {
    inherit rocksdb; # make used rocksdb version available (e.g., for backup scripts)
    webadmin = callPackage ./webadmin.nix { };
    updateScript = nix-update-script { };
    tests.stalwart-mail = nixosTests.stalwart-mail;
  };

  meta = {
    description = "Secure & Modern All-in-One Mail Server (IMAP, JMAP, SMTP)";
    homepage = "https://github.com/stalwartlabs/mail-server";
    changelog = "https://github.com/stalwartlabs/mail-server/blob/main/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [
      happysalada
      onny
      oddlama
      pandapip1
    ];
  };
}
