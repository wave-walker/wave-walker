{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ruby_3_3
    rubyPackages_3_3.ruby-lsp
    postgresql_16
    libffi
    openssl
    libxml2
    libxslt
    zlib
    vips
    wget
    curl
    gnumake
    libyaml
  ];

  shellHook = ''
    export BUNDLE_PATH=$PWD/.bundle
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath (with pkgs; [ vips ])};
    export RUBY_YJIT_ENABLE=1;
  '';
}
