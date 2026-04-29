{
  dockerTools,
  lib,
  prometheus-unbound-exporter,
}:

dockerTools.buildLayeredImage {
  name = "unbound-exporter";
  tag = "latest";
  config.Entrypoint = [
    (lib.getExe prometheus-unbound-exporter)
  ];
}
