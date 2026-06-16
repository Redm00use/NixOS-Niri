{ userName ? "kotlin", ... }:
{
  services.accounts-daemon.enable = true;
  system.activationScripts.script.text = ''
    mkdir -p /var/lib/AccountsService/icons
    if [ -f /home/${userName}/.face ]; then
      cp /home/${userName}/.face /var/lib/AccountsService/icons/${userName}
    fi
  '';
}
