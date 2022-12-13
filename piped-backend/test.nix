{ self }:
{ pkgs, ... }:

let

  listenPort = 14302;

in
{
  name = "piped-backend-test";
  nodes.machine = {
    imports = [
      self.nixosModules.piped-frontend
      self.nixosModules.piped-proxy
      self.nixosModules.piped-backend
    ];
    config = {
      services.piped-backend = {
        enable = true;
        inherit listenPort;
      };
      services.postgresql = {
        initialScript = pkgs.writeText "init-postgres-with-password" ''
          CREATE USER piped WITH PASSWORD 'piped';
          CREATE DATABASE piped;
          GRANT ALL PRIVILEGES ON DATABASE piped TO piped;
        '';
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("piped-backend")
    machine.succeed("sleep 20")
    machine.succeed("curl http://127.0.0.1:${builtins.toString listenPort}")
  '';

}