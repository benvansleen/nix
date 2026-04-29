{
  dockerTools,
  lib,
  cacert,
  unbound,
}:

dockerTools.buildLayeredImage {
  name = "unbound";
  tag = "latest";
  contents = [
    cacert
    dockerTools.caCertificates
  ];
  config.Cmd = [
    "${lib.getExe unbound}"
    "-d"
  ];
}
