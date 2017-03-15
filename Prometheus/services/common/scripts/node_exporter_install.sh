#!/bin/bash

EXP_URL='https://github.com/prometheus/node_exporter/releases/download/v0.13.0/node_exporter-0.13.0.linux-amd64.tar.gz'
PROM_DIR='/var/lib/prometheus'
COMMON_DIR='/tmp/common'
EXP_NAME='node_exporter'

if [[ ! -f ${PROM_DIR?}/${EXP_NAME?}/${EXP_NAME?} ]]
then
    cd /tmp
    wget -O /tmp/${EXP_NAME?}.tgz ${EXP_URL?} >/dev/null 2>&1
    tar -xzvf /tmp/${EXP_NAME?}.tgz >/dev/null 2>&1

    id -u prometheus >/dev/null 2>&1

    if [[ $? -ne 0 ]]
    then
        useradd prometheus -m -d ${PROM_DIR?}
    fi

    mkdir ${PROM_DIR?}/${EXP_NAME?}
    mv /tmp/${EXP_NAME?}*/* ${PROM_DIR?}/${EXP_NAME?}

    chown -R prometheus:prometheus ${PROM_DIR?}
    chmod 700 /var/lib/prometheus/

    cp ${COMMON_DIR?}/config/${EXP_NAME?}.service /usr/lib/systemd/system
    chown root:root /usr/lib/systemd/system/${EXP_NAME?}.service
    chmod 644 /usr/lib/systemd/system/${EXP_NAME?}.service

    systemctl daemon-reload
    systemctl enable ${EXP_NAME?}
    systemctl start ${EXP_NAME?}
    systemctl status ${EXP_NAME?}
fi

exit 0
