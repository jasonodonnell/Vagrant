#!/bin/bash

PGDG_REPO='https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm'
PGDG_DIR='/usr/pgsql-9.5/bin'

yum -y install ${PGDG_REPO?}

yum -y install postgresql95 postgresql95-server \
    postgresql95-contrib postgresql95-devel \
    postgresql95-docs postgresql95-libs

${PGDG_DIR?}/postgresql95-setup initdb

systemctl enable postgresql-9.5

exit 0
