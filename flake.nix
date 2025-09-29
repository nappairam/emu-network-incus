{
  description = "Flake to play with emulated network";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {self, nixpkgs, ...} @ inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        nixosModules.base =
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

            environment.systemPackages = with pkgs; [
              helix
              curl
              terraform
            ];

            users.users.testuser = {
              isNormalUser = true;
              extraGroups = [
                "wheel"
                "incus-admin"
              ];
              packages = with pkgs; [ git ];
              initialPassword = "password";
              home = "/home/testuser";
            };

            # Copy terraform directory with proper ownership
            systemd.tmpfiles.rules = [
              "d /home/testuser/terraform 0755 testuser users -"
            ];

            systemd.services.copy-terraform = {
              description = "Copy terraform files to user home";
              wantedBy = [ "multi-user.target" ];
              after = [ "local-fs.target" ];
              serviceConfig = {
                Type = "oneshot";
                User = "testuser";
                Group = "users";
              };
              script = ''
                mkdir -p /home/testuser/terraform
                cp -r ${toString ./terraform}/* /home/testuser/terraform/ 2>/dev/null || true
                chmod -R u+w /home/testuser/terraform
              '';
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
            networking.firewall.trustedInterfaces = [
              "incusbr0"
              "net_ovsbr0"
            ];

            system.stateVersion = "25.05";
          };

        nixosModules.vm =
          { ... }:
          {
            # Make VM output to the terminal instead of a separate window
            virtualisation.vmVariant.virtualisation.graphics = false;
            virtualisation.vmVariant.virtualisation.diskSize = 20480;
          };

        nixosConfigurations.darwinVm = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            {
              nixpkgs.pkgs = import nixpkgs {
                system = "aarch64-linux";
                config.allowUnfree = true;
              };
            }
            # { nixpkgs.config.allowUnfree = true; }
            inputs.self.nixosModules.base
            inputs.self.nixosModules.vm
            {
              virtualisation.vmVariant.virtualisation.host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;
            }
          ];
        };
        packages.aarch64-darwin.darwinVM = self.nixosConfigurations.darwinVm.config.system.build.vm;
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

          packages.x86_64-linux.linuxVM = self.nixosConfigurations.linuxVM.config.system.build.vm;

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
