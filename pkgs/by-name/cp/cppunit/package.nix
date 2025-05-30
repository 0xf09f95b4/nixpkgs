{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "cppunit";
  version = "1.15.1";

  src = fetchurl {
    url = "https://dev-www.libreoffice.org/src/${pname}-${version}.tar.gz";
    sha256 = "19qpqzy66bq76wcyadmi3zahk5v1ll2kig1nvg96zx9padkcdic9";
  };

  # Avoid blanket -Werror to evade build failures on less
  # tested compilers.
  configureFlags = [ "--disable-werror" ];

  meta = with lib; {
    homepage = "https://freedesktop.org/wiki/Software/cppunit/";
    description = "C++ unit testing framework";
    mainProgram = "DllPlugInTester";
    license = licenses.lgpl21;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
