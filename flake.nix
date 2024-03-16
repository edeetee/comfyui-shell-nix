{
  inputs = {
    utils.url = "github:numtide/flake-utils";
	 mach-nix.url = "github:DavHau/mach-nix";
	nixpkgs.url = "github:NixOS/nixpkgs";
	comfyuigit = {
		flake = false;
		url = "github:comfyanonymous/ComfyUI/";
	};

  };
  outputs = { self, nixpkgs, utils, mach-nix, comfyuigit}: utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
	  pyenv = pkgs.python311.buildEnv.override {
		  ignoreCollisions = true;
		  extraLibs =  with pkgs.python311Packages; [
					torchWithRocm
					torchvision
					torchaudio
					torchsde

					einops
					transformers
					safetensors
					aiohttp
					pyyaml
					pillow
					scipy
					tqdm
					psutil
					kornia
				];
	  };

    in
    rec {
		packages = rec {
			comfyuisrc = pkgs.stdenv.mkDerivation{
				name = "comfyui";
				src = comfyuigit;
				installPhase = ''
					mkdir -p $out/bin
					cp -r $src/* $out

					for dir in "output" "user" "temp" "input"; do
						if [ ! -d $dir ]; then
							path="./$dir"
							mkdir -p "$path"
							ln -s "$path" "$out/$dir"
						fi
					done

					cp ${self}/extra_model_paths.yaml $out
				'';
			};

			comfyuimain = pkgs.writeShellApplication {
				name = "comfyuimain";
				text = ''
					#!/usr/bin/env bash
					HSA_OVERRIDE_GFX_VERSION=10.3.0 ${pyenv}/bin/python ${comfyuisrc}/main.py "$@"
				'';
			};

			default = comfyuisrc;
		};

		apps = rec {
			comfyui = {
				type = "app";
				program = "${packages.comfyuimain}/bin/comfyuimain";
			};

			default = comfyui;
		};

      devShell = pkgs.mkShell {
        buildInputs = [packages.comfyuimain pyenv];
      };
    }
  );
}
