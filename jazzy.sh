#!/bin/bash

if [ ! -d "./DBus.xcodeproj" ]; then
    swift package generate-xcodeproj
fi

if [ ! -d "./docs" ]; then
    echo "Creating docs directory for jazzy output."
    mkdir docs
fi

jazzy --clean \
      --output docs/ \
      -x -scheme,DBus-Package \
      -m DBus
