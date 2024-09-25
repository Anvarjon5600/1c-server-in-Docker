#!/bin/bash
set -e

sudo /opt/1C/1CE/x86_64/ring/ring hazelcast --instance hc_instance service restart
sudo /opt/1C/1CE/x86_64/ring/ring elasticsearch --instance elastic_instance service restart
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance service restart

echo "ALL START"
sh