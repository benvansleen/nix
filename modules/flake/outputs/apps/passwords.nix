{
  perSystem =
    { pkgs, lib, ... }:

    let
      createApp = pkg: {
        type = "app";
        program = pkg;
      };

      eachUser =
        f:
        with lib;
        let
          users = pipe ../../../users [
            builtins.readDir
            (filterAttrs (_name: filetype: (filetype == "directory")))
            (mapAttrsToList (name: _filetype: name))
          ];
        in
        genAttrs users f;

      set-password-for =
        user:
        let
          file = "./secrets/users/${user}/password.sops";
          keyfile = if user == "root" then "/etc/ssh/ssh_host_ed25519_key" else "~/.ssh/master";
          need-privileged-execution = if user == "root" then "sudo" else "";
        in
        pkgs.writeShellApplication {
          name = "set-password";
          runtimeInputs = with pkgs; [ sops ];
          text = with lib; /* sh */ ''
            PASSWORD_FILE=${file}

            read -rp "New password: " password
            if [ -z "$password" ]
            then
                echo "Password cannot be empty!"
                exit 1
            fi

            SOPS_AGE_KEY=$(${need-privileged-execution} ${getExe pkgs.ssh-to-age} -i ${keyfile} -private-key)
            export SOPS_AGE_KEY
            if [ -e $PASSWORD_FILE ]
            then
                hash=$(${getExe pkgs.mkpasswd} "$password" -m sha-512)
                ${getExe pkgs.sops} set "$PASSWORD_FILE" '["data"]' "\"$hash\""
                echo "Password will update after next system rebuild"
                echo "Be sure to push to the \`secrets\` remote repository"
            else
                echo "$PASSWORD_FILE not found!"
            fi
          '';
        };
    in
    {
      apps =
        with lib;
        (pipe { root = set-password-for "root"; } [
          (attrs: attrs // (eachUser set-password-for))
          (mapAttrs' (user: app: nameValuePair "set-password-for-${user}" (createApp app)))
        ]);
    };
}
