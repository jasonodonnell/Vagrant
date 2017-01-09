#!/bin/bash

HOME_DIR='/home/vagrant'
BASHRC="${HOME_DIR?}/.bashrc"
USER='vagrant'
GROUP='vagrant'
PG_DIR="${HOME_DIR?}/test"

source ${BASHRC?}

# Create Build Directory
echo "Create PG Directory.."
mkdir ${PG_DIR?}
chown ${USER?}:${GROUP?} ${PG_DIR?}

# Init DB
initdb -D ${PG_DIR?}

sudo chown -R vagrant:vagrant /home/vagrant/

exit 0
