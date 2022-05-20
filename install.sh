#!/bin/zsh

echo "Installing Rust..."; 
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh

packages=""
while read line
do
    cargo install $line
done < ~/.dotfiles/rust_modules
