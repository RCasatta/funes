{
  description = "Funes — recall over past AI agent sessions";

  # The reference my_flakes pin has Rust 1.85; funes builds with Rust 1.95 in CI.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.rust-overlay = {
    url = "github:oxalica/rust-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import rust-overlay) ];
          };
          rust = pkgs.rust-bin.stable."1.95.0".minimal;
          rustPlatform = pkgs.makeRustPlatform { cargo = rust; rustc = rust; };
        in
        {
          default = rustPlatform.buildRustPackage {
            pname = "funes";
            version = "1.4.0+dev";
            src = ./.;

            cargoLock.lockFile = ./Cargo.lock;

            nativeBuildInputs = with pkgs; [ cmake pkg-config protobuf ];
            buildInputs = with pkgs; [ openssl ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.libiconv ];

            # The integration tests fetch model weights and access the Hub.
            doCheck = false;
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/funes";
        };
      });
    };
}
