{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools-scm,
  pytest,
  decopatch,
  makefun,
  six,
  pytestCheckHook,
  numpy,
  pandas,
  tabulate,
  pytest-cases,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "pytest-harvest";
  version = "1.10.5";
  pyproject = true;

  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "smarie";
    repo = "python-pytest-harvest";
    tag = version;
    hash = "sha256-s8QiuUFRTTRhSpLa0DHScKFC9xdu+w2rssWCg8sIjsg=";
  };

  # create file, that is created by setuptools_scm
  # we disable this file creation as it touches internet
  postPatch = ''
    echo "version = '${version}'" > pytest_harvest/_version.py

    substituteInPlace pytest_harvest/tests/test_lazy_and_harvest.py \
      --replace-fail "from distutils.version import LooseVersion" "from packaging.version import parse" \
      --replace-fail "LooseVersion" "parse"
  '';

  nativeBuildInputs = [
    setuptools-scm
  ];

  buildInputs = [ pytest ];

  propagatedBuildInputs = [
    decopatch
    makefun
    six
  ];

  nativeCheckInputs = [
    pytestCheckHook
    numpy
    pandas
    tabulate
    pytest-cases
  ];

  pythonImportsCheck = [ "pytest_harvest" ];

  meta = with lib; {
    description = "Store data created during your `pytest` tests execution, and retrieve it at the end of the session, e.g. for applicative benchmarking purposes";
    homepage = "https://github.com/smarie/python-pytest-harvest";
    changelog = "https://github.com/smarie/python-pytest-harvest/releases/tag/${version}";
    license = licenses.bsd3;
    maintainers = with maintainers; [ mbalatsko ];
  };
}
