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
					numba
					opencv4
					GitPython
					numexpr
					matplotlib
					pandas

					imageio-ffmpeg
					scikit-image
					pip

					accelerate
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
					
					cp ${self}/extra_model_paths.yaml $out
				'';
			};

			comfyuimain = pkgs.writeShellApplication {
				name = "comfyuimain";
				text = ''
					#!/usr/bin/env bash
					COMFYUI_PATH="$1"
					shift
					HSA_OVERRIDE_GFX_VERSION=10.3.0 ${pyenv}/bin/python "$COMFYUI_PATH/main.py" "$@"
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
