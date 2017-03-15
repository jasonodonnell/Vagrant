#!/bin/bash

PGSQL_VER='9.6'
PGSQL_SRC_DIR='/tmp/postgres'
COMMON_DIR='/tmp/common'
BIN_DIR="/usr/pgsql-${PGSQL_VER?}/bin"
PGDG='https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm'

yum install -y ${PGDG?} >/dev/null 2>&1


yum install -y postgresql96 \
               postgresql96-contrib \
               postgresql96-libs \
               postgresql96-server \
               postgresql96-docs \
               >/dev/null 2>&1

/usr/pgsql-${PGSQL_VER?}/bin/postgresql96-setup initdb
systemctl enable postgresql-${PGSQL_VER?}

cp ${PGSQL_SRC_DIR?}/config/postgresql.conf /var/lib/pgsql/${PGSQL_VER?}/data
cp ${PGSQL_SRC_DIR?}/config/pg_hba.conf /var/lib/pgsql/${PGSQL_VER?}/data

chown postgres:postgres /var/lib/pgsql/${PGSQL_VER?}/data/postgresql.conf
chown postgres:postgres /var/lib/pgsql/${PGSQL_VER?}/data/pg_hba.conf
chmod 600 /var/lib/pgsql/${PGSQL_VER?}/data/postgresql.conf
chmod 600 /var/lib/pgsql/${PGSQL_VER?}/data/pg_hba.conf

systemctl start postgresql-${PGSQL_VER?}

${COMMON_DIR?}/scripts/node_exporter_install.sh

su - postgres -c \
    "${BIN_DIR?}/psql -d postgres -f /tmp/postgres/scripts/statistics.sql"

${PGSQL_SRC_DIR?}/scripts/install_postgres_exporter.sh

exit 0
