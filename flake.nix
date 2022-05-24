{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { flake-utils, nixpkgs, self }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages = with nixpkgs.legacyPackages."${system}"; rec {
        erlang_24 = erlang.overrideAttrs (oldAttrs: rec {
          name = "erlang-${version}";
          version = "24.3.4";

          src = fetchFromGitHub {
            owner = "erlang";
            repo = "otp";
            rev = "OTP-${version}";
            sha256 = "1hb5rr952lgglwz721hkczjrag29ri1w9q3va6whcx3dwsyw39i2";
          };

          configureFlags = oldAttrs.configureFlags
            ++ [ "--with-ssl=${lib.getOutput "out" openssl}" ]
            ++ [ "--with-ssl-incl=${lib.getDev openssl}" ];
        });

        elixir_1_13 = elixir.overrideAttrs (oldAttrs: rec {
          name = "elixir-${version}";
          version = "1.13.4";

          buildInputs = [ erlang_24 ];

          src = fetchFromGitHub {
            owner = "elixir-lang";
            repo = "elixir";
            rev = "v${version}";
            sha256 = "1z19hwnv7czmg3p56hdk935gqxig3x7z78yxckh8fs1kdkmslqn4";
          };

          nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ]
            ++ [ makeWrapper ];
        });
      };

      devShell = with nixpkgs.legacyPackages."${system}";
        mkShell {
          buildInputs = with self.packages."${system}"; [
            elixir_1_13
            erlang_24
          ];
        };
    });
}
