#!/bin/bash
set -e

sudo useradd cs_user
sudo mkdir -p /var/cs/cs_instance
sudo chown cs_user:cs_user /var/cs/cs_instance
sudo /opt/1C/1CE/x86_64/ring/ring cs instance create --dir /var/cs/cs_instance --owner cs_user
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance service create --username cs_user --java-home $JAVA_HOME --stopped

sudo useradd hc_user
sudo mkdir -p /var/cs/hc_instance
sudo chown hc_user:hc_user /var/cs/hc_instance
sudo /opt/1C/1CE/x86_64/ring/ring hazelcast instance create --dir /var/cs/hc_instance --owner hc_user
sudo /opt/1C/1CE/x86_64/ring/ring hazelcast --instance hc_instance service create --username hc_user --java-home $JAVA_HOME --stopped

sudo useradd elastic_user
sudo mkdir -p /var/cs/elastic_instance
sudo chown elastic_user:elastic_user /var/cs/elastic_instance
sudo /opt/1C/1CE/x86_64/ring/ring elasticsearch instance create --dir /var/cs/elastic_instance --owner elastic_user
sudo /opt/1C/1CE/x86_64/ring/ring elasticsearch --instance elastic_instance service create --username elastic_user --java-home $JAVA_HOME --stopped

sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc set-params --url jdbc:postgresql://db:5432/cs_db?currentSchema=public
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc set-params --username postgres
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc set-params --password postgres
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc-privileged set-params --url jdbc:postgresql://db:5432/cs_db?currentSchema=public
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc-privileged set-params --username postgres
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance jdbc-privileged set-params --password postgres

sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance websocket set-params --hostname cs
sudo /opt/1C/1CE/x86_64/ring/ring cs --instance cs_instance websocket set-params --port 8087