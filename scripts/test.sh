#!/bin/bash
# Run swift test with CLT-only paths. Command Line Tools ship swift-testing in
# two directories that are not on any default search path, so bare `swift test`
# fails first to find the Testing module, then to dlopen Testing.framework, then
# to dlopen lib_TestingInterop.dylib. Passing all three closes that out.
set -euo pipefail
cd "$(dirname "$0")/.."
CLT_FRAMEWORKS=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
CLT_LIB=/Library/Developer/CommandLineTools/Library/Developer/usr/lib
exec swift test \
  -Xswiftc -F -Xswiftc "$CLT_FRAMEWORKS" \
  -Xlinker -rpath -Xlinker "$CLT_FRAMEWORKS" \
  -Xlinker -rpath -Xlinker "$CLT_LIB" \
  "$@"
