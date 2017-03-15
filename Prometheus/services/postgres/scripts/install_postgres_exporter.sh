#!/bin/bash

EXP_URL='https://github.com/wrouesnel/postgres_exporter/releases/download/v0.1.2/postgres_exporter'
PROM_DIR='/var/lib/prometheus'
COMMON_DIR='/tmp/common'
EXP_NAME='postgres_exporter'
PGSQL_DIR='/tmp/postgres'
USER='prometheus'
GROUP='prometheus'

if [[ ! -f ${PROM_DIR?}/${EXP_NAME?}/${EXP_NAME?} ]]
then
    cd /tmp
    wget -O /tmp/${EXP_NAME?} ${EXP_URL?} >/dev/null 2>&1
    
    id -u ${USER?} >/dev/null 2>&1

    if [[ $? -ne 0 ]]
    then
        useradd ${USER?} -m -d ${PROM_DIR?}
    fi

    mkdir ${PROM_DIR?}/${EXP_NAME?}
    mv /tmp/${EXP_NAME?} ${PROM_DIR?}/${EXP_NAME?}
    mv ${PGSQL_DIR?}/config/queries.yml ${PROM_DIR?}/${EXP_NAME?}

    chown -R ${USER?}:${GROUP?} ${PROM_DIR?}
    chmod 755 ${PROM_DIR?}
    chmod +x ${PROM_DIR?}/${EXP_NAME?}/${EXP_NAME?}

    cp ${PGSQL_DIR?}/config/${EXP_NAME?}.service /usr/lib/systemd/system
    chown root:root /usr/lib/systemd/system/${EXP_NAME?}.service
    chmod 644 /usr/lib/systemd/system/${EXP_NAME?}.service

    systemctl daemon-reload
    systemctl enable ${EXP_NAME?}
    systemctl start ${EXP_NAME?}
    systemctl status ${EXP_NAME?}
fi

exit 0
