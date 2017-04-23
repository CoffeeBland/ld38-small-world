#!/usr/bin/env bash
set -e
if test ! -d love-0.10.2-win32; then
    wget -O love-0.10.2-win32.zip https://bitbucket.org/rude/love/downloads/love-0.10.2-win32.zip
    unzip love-0.10.2-win32.zip
    rm love-0.10.2-win32.zip
fi
