#!/bin/bash

# Common Mac and Linux Bazzite stuff

## Command line tool
brew install nushell nvim starship zoxide

## Lang toolchain

if ! command -v volta 2>&1 >/dev/null
then
    echo "Volta exists"
else 
    curl https://get.volta.sh | bash
    
    # install latest LTS node
    volta install node
fi
