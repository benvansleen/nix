{
  flake.modules.homeManager.bottom = {
    config = {
      programs.bottom = {
        enable = true;
        settings = {
          tree = true;
          enable_gpu = true;
          processes.columns = [
            "PID"
            "Name"
            "Mem%"
            "CPU%"
            "GPU%"
            "User"
            "State"
            "R/s"
            "W/s"
            "T.Read"
            "T.Write"
          ];
        };
      };
    };
  };
}
