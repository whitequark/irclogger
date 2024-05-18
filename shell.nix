{ pkgs ? import <nixpkgs> { } }:

let
  ruby = pkgs.ruby_3_1;
  env = pkgs.bundlerEnv {
    name = "irclogger-gems";
    inherit ruby;
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
  };
in
pkgs.mkShell {
  packages = with pkgs; [
    bundix
    env
  ];
}
