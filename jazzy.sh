#!/bin/bash
swift package generate-xcodeproj
mkdir docs
jazzy --clean \
      --output docs/ \
      -x -scheme,DBus-Package \
      -m DBus
