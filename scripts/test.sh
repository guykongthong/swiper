#!/bin/sh
# Runs unit tests with only the Command Line Tools installed (no Xcode).
# If full Xcode is installed, plain `swift test` works and this script is not needed.
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
L=/Library/Developer/CommandLineTools/Library/Developer/usr/lib
exec swift test -Xswiftc -F$F -Xlinker -F$F -Xlinker -rpath -Xlinker $F -Xlinker -rpath -Xlinker $L "$@"
