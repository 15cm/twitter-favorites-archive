{ pkgs ? import <nixos-unstable> { } }:
pkgs.mkShell {
  # nativeBuildInputs is usually what you want -- tools you need to run
  nativeBuildInputs = with pkgs; [ buildPackages.ruby_3_2 ];
}
