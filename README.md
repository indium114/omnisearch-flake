# omnisearch-flake

This is a Nix flake for [OmniSearch](https://git.bwaaa.monster/omnisearch/about), as the official one in the repo seems to not be maintained anymore.

## setup

Add the following to your `flake.nix` to get started:

```nix
{
  inputs = {
    omnisearch = {
      url = "github:indium114/omnisearch-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, omnisearch, ... }: {
    nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
      modules = [
        omnisearch.nixosModules.default
        {
          services.omnisearch.enable = true;
        }
      ];
    };
  };
}
```

You can also configure OmniSearch through this module.

```nix
{
  services.omnisearch = {
    enable = true;        # enable the service
    configFile = null;    # specify a config file to use. (e.g. /srv/omnisearch.ini)
    settings = {          # configure omnisearch
      server = {          # server settings
        host = "0.0.0.0"; # specify the host address
        port = 8087;      # specify the port to listen on
      };
    }
  };
}
```

For more options, see `module.nix` in the root of this repo.
