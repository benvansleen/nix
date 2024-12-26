_:

{
  config.programs.bottom.settings = {
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
}
