#!/bin/bash

#Update packages
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get \
-o Dpkg::Options::=--force-confold \
-o Dpkg::Options::=--force-confdef \
-y --allow-downgrades --allow-remove-essential --allow-change-held-packages

#Download and untar the agent installer
curl -L -O https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-8.3.2-linux-x86_64.tar.gz
tar xzvf elastic-agent-8.3.2-linux-x86_64.tar.gz
cd elastic-agent-8.3.2-linux-x86_64

#Install agent non-interactively
sudo ./elastic-agent install --url=$1 --enrollment-token=$2 --non-interactive