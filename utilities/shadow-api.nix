{ lib, pkgs, ... }:

/*
  Helper to interact with the Shadow API

  Import example:
  let
    inherit (import ./utilities/shadow-api.nix { inherit lib; }) getLatestInfo;

    ...
  in
*/
rec {
  yamlInfo-prod = builtins.fetchurl {
    url = "https://storage.googleapis.com/shadow-update/launcher/prod/linux/ubuntu_18.04/latest-linux.yml";
    sha256 = "sha256-eVr+quVnIQlp/lcOYmKAYytHbcmjBDzCh6XNeBpPF3g=";
  };

  yamlInfo-preprod = builtins.fetchurl {
    url = "https://storage.googleapis.com/shadow-update/launcher/preprod/linux/ubuntu_18.04/latest-linux.yml";
    sha256 = "sha256-UYQjAoSujBat+GMud5ul4H1CbOhk8B3y4Aw5a679/0s=";
  };

  yamlInfo-testing = builtins.fetchurl {
    url = "https://storage.googleapis.com/shadow-update/launcher/testing/linux/ubuntu_18.04/latest-linux.yml";
    sha256 = "sha256-4c1jDJypAqC5A6lcdmemPWqf7Tlw+IBSYd6ixk/Y530=";
  };

  /*
    Return the latest version information for the given channel

    Example:
      getLatestInfo "preprod"
      => { channel = "preprod"; version = "3.1.6"; sha512 = "..."; path = "..."; }
  */
  getLatestInfo =
    channel:
    let
      yamlInfo =
        if channel == "prod" then
          yamlInfo-prod
        else if channel == "preprod" then
          yamlInfo-preprod
        else if channel == "testing" then
          yamlInfo-testing
        else
          throw "Unknown channel: ${channel}";
      jsonInfo = (
        pkgs.runCommand "transform" {
          buildInputs = with pkgs; [
            yq
            jq
          ];
        } "cat ${yamlInfo} | yq -j . > $out"
      );
      info = builtins.fromJSON (builtins.readFile jsonInfo);
    in
    {
      channel = channel;
      version = info.version;
      sha512 = info.sha512;
      path = info.path;
    };

  /*
    Return the file information to give to fetchurl

    Example:
      getDownloadInfo info
      => { url = "..."; hash = "sha512-..."; }
  */
  getDownloadInfo = info: {
    url = "https://update.shadow.tech/launcher/${info.channel}/linux/ubuntu_18.04/${info.path}";
    hash = "sha512-${info.sha512}";
  };
}
