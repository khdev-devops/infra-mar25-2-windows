#!/bin/bash

# CLoudShell saves the files you have created but not installed packages and software
# so you may need to run this after being inactive on CloudShell

sudo dnf update -y
sudo dnf install -y ansible
