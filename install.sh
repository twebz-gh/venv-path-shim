#!/bin/sh

mkdir -p ${HOME}/.local/bin
mkdir -p ${HOME}/.local/venv-path-shim
cp find-venv-executable.sh ${HOME}/.local/bin/
cp pip ${HOME}/.local/venv-path-shim/
cp python ${HOME}/.local/venv-path-shim/
chmod u+x ${HOME}/.local/venv-path-shim/pip
chmod u+x ${HOME}/.local/venv-path-shim/python
chmod u+x ${HOME}/.local/bin/find-venv-executable.sh

