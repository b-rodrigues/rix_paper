let
 pkgs = import (fetchTarball "https://github.com/b-rodrigues/nixpkgs/archive/06b93631a20bc9c1e73d7b5c706af12ee01922aa.tar.gz") {};
 rpkgs = builtins.attrValues {
  inherit (pkgs.rPackages) quarto targets tarchetypes visNetwork;
};
  rix = (pkgs.buildRPackage {
           name = "rix";
           src = pkgs.fetchgit {
             url = "https://github.com/b-rodrigues/rix/";
             branchName = "master";
             rev = "ea92a88ecdfc2d74bdf1dde3e441d008521b1756";
             sha256 = "sha256-fKNtFaWPyoiS7xOOlhjok3Ddqsij7CymoKAeTT8ygIU=";
           };
           propagatedBuildInputs = [
             builtins.attrValues {
                inherit (pkgs.rPackages) httr jsonlite sys;
                }
            ];
           });
  tex = (pkgs.texlive.combine {
  inherit (pkgs.texlive) scheme-small amsmath booktabs setspace lineno cochineal tex-gyre framed multirow wrapfig fontawesome5 tcolorbox orcidlink environ tikzfill pdfcol;
});
 system_packages = builtins.attrValues {
  inherit (pkgs) R glibcLocalesUtf8 quarto;
};
  in
  pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then  "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";

    buildInputs = [  rpkgs tex system_packages  ];
      
  }