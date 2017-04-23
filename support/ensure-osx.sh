#!/usr/bin/env bash
set -e
if test ! -d love.app; then
    wget -O love-0.10.2-macosx-x64.zip https://bitbucket.org/rude/love/downloads/love-0.10.2-macosx-x64.zip
    unzip love-0.10.2-macosx-x64.zip
    rm love-0.10.2-macosx-x64.zip
fi
