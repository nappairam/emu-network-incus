{
  description = "Flake to play with emulated network";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.config.allowUnfree = true; }
            (
              { pkgs, ... }:
              {
                # Boot configuration
                boot.loader.systemd-boot.enable = true;
                boot.loader.efi.canTouchEfiVariables = true;

                # Root filesystem
                fileSystems."/" = {
                  device = "/dev/disk/by-label/nixos";
                  fsType = "ext4";
                };

                # Use the existing shared mount but configure it properly
                virtualisation.vmVariant = {
                  virtualisation.diskSize = 20480; # 20GB disk
                  virtualisation.memorySize = 4096; # 4GB RAM
                  virtualisation.sharedDirectories = {
                    host = {
                      source = toString ./.;
                      target = "/mnt/host";
                    };
                  };
                };

                environment.systemPackages = with pkgs; [
                  helix
                  curl
                  terraform
                ];

                users.users.testuser = {
                  isNormalUser = true;
                  extraGroups = [ "wheel" "incus-admin" ];
                  packages = with pkgs; [ git ];
                  initialPassword = "password";
                };

                security.sudo.wheelNeedsPassword = false;
                services.sshd.enable = true;

                virtualisation.incus.enable = true;
                virtualisation.incus.preseed = {
                  networks = [
                    {
                      name = "incusbr0";
                      type = "bridge";
                      config = {
                        "ipv4.address" = "10.20.30.1/24";
                        "ipv4.dhcp" = "true";
                        "ipv4.nat" = "true";
                        "ipv6.address" = "none";
                      };
                    }
                  ];
                  storage_pools = [
                    {
                      name = "default";
                      driver = "dir";
                      config = {
                        source = "/var/lib/incus/storage-pools/default";
                      };
                    }
                  ];
                  profiles = [
                    {
                      name = "default";
                      devices = {
                        eth0 = {
                          name = "eth0";
                          network = "incusbr0";
                          type = "nic";
                        };
                        root = {
                          path = "/";
                          pool = "default";
                          type = "disk";
                        };
                      };
                    }
                  ];
                };
                virtualisation.vswitch.enable = true;

                networking.nftables.enable = true;
                networking.firewall.trustedInterfaces = [ "incusbr0" "net_ovsbr0" ];

                system.stateVersion = "25.05";
              }
            )
          ];
        };
      };

      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              incus
              openvswitch
              terraform
            ];

            shellHook = '''';
          };

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
