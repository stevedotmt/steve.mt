{ pkgs, lib, config, inputs, ... }:

{
  packages = [ pkgs.git pkgs.hugo ];

  processes.hugo.exec = "hugo serve";
}
