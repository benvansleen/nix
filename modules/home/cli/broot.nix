_:

{
  config.programs.broot.settings = {
    modal = true;
    verbs = [
      {
        key = ";";
        execution = ":mode_input";
      }
      {
        key = "q";
        execution = ":quit";
      }
    ];
  };
}
