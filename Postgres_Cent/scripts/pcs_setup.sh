#!/bin/bash

# PCS Vars
PCS_USER='hacluster'
PCS_PASS='test123'
VIP1='162.254.144.9'
VIP2='162.254.144.10'
NIC='eth0'
CIDR='24'

# Node 0
NODE0='192.168.60.4'
NODE0_HOST='orc-pgsql0.dev'
NODE0_ALIAS='orc-pgsql0'
# Node 1
NODE1='192.168.60.5'
NODE1_HOST='orc-pgsql1.dev'
NODE1_ALIAS='orc-pgsql1'
# Node 2
NODE2='192.168.60.6'
NODE2_HOST='orc-pgsql2.dev'
NODE2_ALIAS='orc-pgsql2'

# PG Vars
PG_PORT=5432
PG_BIN_DIR='/usr/pgsql-9.5/bin'
PG_DATA='/var/lib/pgsql-9.5/data'
NODE_LIST="orc-pgsql0 orc-pgsql1 orc-pgsql2"
RESTORE_COMMAND='cp /archive/%f %p'

# Install Packages
echo "Installing pcs packages.."
yum -y install pacemaker pcs psmisc policycoreutils­-python firewald

# Start firewalld and pcsd
echo "Starting firewalld/pcsd.."
systemctl enable firewalld pcsd
systemctl start firewalld pcsd

# Add firewall services
echo "Adding firewall service groups.."
firewall-cmd --permanent --add-service=high-availability
firewall-cmd --permanent --add-service=postgresql
firewall-cmd --reload

# Start pcsd
echo "Starting pcsd.."
systemctl start pcsd.service
systemctl enable pcsd.service

# Setup password for hacluster user (created by pcs)
echo "Setting ${PCS_USER?} password.."
echo "${PCS_PASS?}" | passwd --stdin hacluster

# Add /etc/hosts for other servers
echo "Adding /etc/hosts entries.."
if [[ $(uname -n) == "${NODE0_HOST?}" ]]
then
    echo "${NODE1?} ${NODE1_HOST?} ${NODE1_ALIAS?}" >> /etc/hosts
    echo "${NODE2?} ${NODE2_HOST?} ${NODE2_ALIAS?}" >> /etc/hosts
elif [[ $(uname -n) == "${NODE1_HOST?}" ]]
then
    echo "${NODE0?} ${NODE0_HOST?} ${NODE0_ALIAS?}" >> /etc/hosts
    echo "${NODE2?} ${NODE2_HOST?} ${NODE2_ALIAS?}" >> /etc/hosts
else
    echo "${NODE0?} ${NODE0_HOST?} ${NODE0_ALIAS?}" >> /etc/hosts
    echo "${NODE1?} ${NODE1_HOST?} ${NODE1_ALIAS?}" >> /etc/hosts
fi

# Add blank conf file
echo "Touching corosync.conf.."
touch /etc/corosync/corosync.conf

# Run these on the last server provisioned to ensure the other servers are ready
if [[ $(uname -n) == "${NODE2_HOST?}" ]]
then
    set -x
    echo "Authenticating pcs.."
    pcs cluster auth -u ${PCS_USER?} -p ${PCS_PASS?} \
        ${NODE0_ALIAS?} ${NODE1_ALIAS?} ${NODE2_ALIAS?}

    echo "Creating pcs cluster.."
    pcs cluster setup --name pgsql_cfg \
        ${NODE0_ALIAS?} ${NODE1_ALIAS?} ${NODE2_ALIAS?} --force

    echo "Starting cluster.."
    pcs cluster start --all -u ${PCS_USER?} -p ${PCS_PASS?}

    echo "Setting properties.."
    pcs cluster cib pgsql_cfg
    pcs -f pgsql_cfg property set no-quorum-policy="ignore"
    pcs -f pgsql_cfg property set stonith-enabled="false"
    pcs -f pgsql_cfg resource defaults resource-stickiness="INFINITY"
    pcs -f pgsql_cfg resource defaults migration-threshold="1"

    echo "Create Master VIP.."
    pcs -f pgsql_cfg resource create vip-master IPaddr2 \
        ip="${VIP1?}" \
        nic="${NIC?}" \
        cidr_netmask="${CIDR?}" \
        op start timeout="60s" interval="0s" on-fail="restart" \
        op monitor timeout="60s" interval="10s" on-fail="restart" \
        op stop timeout="60s" interval="0s" on-fail="block"

    echo "Create Replication VIP.."
    pcs -f pgsql_cfg resource create vip-rep IPaddr2 \
        ip="${VIP2?}" \
        nic="${NIC?}" \
        cidr_netmask="${CIDR?}" \
        meta migration-threshold="0" \
        op start timeout="60s" interval="0s" on-fail="stop" \
        op monitor timeout="60s" interval="10s" on-fail="restart" \
        op stop timeout="60s" interval="0s" on-fail="ignore"

    echo "Create PostgreSQL Servers.."
    pcs -f pgsql_cfg resource create pgsql pgsql \
        pgctl="${PG_BIN_DIR?}/pg_ctl" \
        psql="${PG_BIN_DIR?}/psql" \
        pgdata="${PG_DATA?}" \
        pgport=${PG_PORT?} \
        rep_mode="sync" \
        node_list="${NODE_LIST?}" \
        restore_command="${RESTORE_COMMAND?}" \
        primary_conninfo_opt="keepalives_idle=60 keepalives_interval=5 keepalives_count=5" \
        master_ip="${VIP2?}" \
        restart_on_promote='true' \
        op start timeout="60s" interval="0s" on-fail="restart" \
        op monitor timeout="60s" interval="4s" on-fail="restart" \
        op monitor timeout="60s" interval="3s" on-fail="restart" role="Master" \
        op promote timeout="60s" interval="0s" on-fail="restart" \
        op demote timeout="60s" interval="0s" on-fail="stop" \
        op stop timeout="60s" interval="0s" on-fail="block" \
        op notify timeout="60s" interval="0s"

    echo "Add Cluster Constraints.."
    pcs -f pgsql_cfg resource master msPostgresql pgsql \
        master-max=1 master-node-max=1 clone-max=3 clone-node-max=1 notify=true

    pcs -f pgsql_cfg resource group add master-group vip-master vip-rep
    pcs -f pgsql_cfg constraint colocation add master-group with Master msPostgresql INFINITY

    pcs -f pgsql_cfg constraint order promote msPostgresql then start master-group \
       symmetrical=false score=INFINITY

    pcs -f pgsql_cfg constraint order demote msPostgresql then stop master-group \
        symmetrical=false score=0

    echo "Push changes.."
    pcs cluster cib-push pgsql_cfg
    crm_mon -Afr -1
    pcs status
fi

echo "Done!"
exit 0
