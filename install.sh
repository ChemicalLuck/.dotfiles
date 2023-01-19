#!/bin/bash

echo "Installing Rust..."; 
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh

echo "Installing Crates..."
xargs cargo install <rust_modules

echo "Installing Packages..."
xargs sudo apt-get install <packages

