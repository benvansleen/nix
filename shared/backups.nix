{
  clients = {
    desktop = {
      paths = [ "/persist" ];
      exclude = [ ];
    };
    laptop = {
      paths = [ "/persist" ];
      exclude = [ ];
    };
    pi = {
      paths = [ "/" ];
      exclude = [
        "/bin"
        "/boot"
        "/dev"
        "/lib"
        "/mnt"
        "/nix"
        "/proc"
        "/run"
        "/sys"
        "/usr"
      ];
    };
  };
}
