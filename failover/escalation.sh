#!/bin/bash
# This script is run by wd_escalation_command to bring down the virtual IP on other pgpool nodes
# before bringing up the virtual IP on the new active pgpool node.

set -o xtrace

POSTGRESQL_STARTUP_USER=postgres
SSH_KEY_FILE=id_rsa_pgpool
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${SSH_KEY_FILE}"
SSH_TIMEOUT=5
PGPOOLS=(psql1 psql2)

VIP=172.23.3.15
DEVICE=ens192

for pgpool in "${PGPOOLS[@]}"; do
    [ "$HOSTNAME" = "${pgpool}" ] && continue

    timeout ${SSH_TIMEOUT} ssh -T ${SSH_OPTIONS} ${POSTGRESQL_STARTUP_USER}@${pgpool} "
        /usr/bin/sudo /sbin/ip addr del ${VIP}/24 dev ${DEVICE}
    "
    if [ $? -ne 0 ]; then
        echo ERROR: escalation.sh: failed to release VIP on ${pgpool}.
    fi
done
exit 0