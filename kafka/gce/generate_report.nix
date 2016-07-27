with import <nixpkgs> {};
with lib;
let
  bench-settings =  import ./bench-settings.nix;
  kafka-benchmark = pkgs.callPackage ../kafka-benchmark { inherit bench-settings; };
  normalizeRunName = replaceStrings ["."] ["-"];
  mkRunReport = { cat, run }: stdenv.mkDerivation {
    name = "report-${cat}-${normalizeRunName run}";
    buildInputs = [ kafka-benchmark ];
    phases = "generateReport";

    src = ./bench-results + "/${cat}/${run}";

    generateReport = ''
      ${kafka-benchmark}/bin/create-kafka-report $src $out
    '';
  };

  # Read benchmark categories 
  categories  = attrNames (builtins.readDir ./bench-results);

  # Read runs of a benchmark, for some category.
  runs = cat: map (run: { inherit cat run; }) (attrNames (builtins.readDir (./bench-results + "/${cat}")));

  allRuns = flatten (map runs categories);

  report = 
  let
    catRunsHTML = concatStringsSep "\n" (map catRunHTML allRuns);
    catRunHTML = { cat, run }: ''<li><a href="${cat}/${normalizeRunName run}/index.html">${cat} - ${run}</a></li>'';

    catRunsLns= concatStringsSep "\n" (map catRunLn allRuns);
    catRunLn = { cat, run }: ''mkdir -p $out/${cat}; ln -s ${mkRunReport { inherit cat run; }} $out/${cat}/${normalizeRunName run}'';
    reportFile = builtins.toFile "index.html" catRunsHTML;
  in stdenv.mkDerivation rec {
    name = "category-report";
    phases = "generateReport";

    generateReport = ''
      mkdir -p $out
      ln -s ${reportFile} $out/index.html 
      ${catRunsLns}
      find $out
    '';
  };
in
{
  inherit report;
}
