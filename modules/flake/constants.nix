{ inputs, ... }:

{
  flake.constants = {
    inherit (inputs.secrets.personal-info) email tailscale-domain tailscale-dns-ip;
    backup-machine = "pi";
    backup-path = "/mnt/storage";
    privilege-escalation = "sudo";
  };
}
