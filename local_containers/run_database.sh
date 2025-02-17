#!/bin/bash

set -ux

function cleanup() {
  echo "Return ownership of bound directories back to container host."
  chown -R root:root /run_database.sh
  exit
}
trap cleanup SIGTERM SIGINT

apt-get update -y && apt-get install sudo

DATADIR='/var/lib/postgresql/data'


if [ -z "$(ls -A $DATADIR)" ]; then
	echo "Initializing PostgreSQL"
    su postgres -c "initdb -D /var/lib/postgresql/data" || true

    psql -U postgres -c "CREATE DATABASE women_in_tech_vic_dev;"

    # listen from all ips
	# this works as long as the database is on the same host as the app
	sed -i "/# - Connection Settings -/a listen_addresses = '*'" /var/lib/postgresql/data/postgresql.conf

	# accept all incoming connections
	echo "# IPv4 openqa:" | sudo tee -a /var/lib/postgresql/data/pg_hba.conf
	echo "host	all	all	0.0.0.0/0	trust" | sudo tee -a /var/lib/postgresql/data/pg_hba.conf


	# su postgres -c "bash -c '/usr/bin/initdb ${DATADIR}'"
	# if [ $? -ne 0 ]; then
	# 	echo "Initialization failed."
	# 	exit 1
	# fi
fi

su postgres -c "postgres -c max_connections=1000 -c shared_buffers=128MB" || true

# su postgres -c "bash -c '/usr/bin/pg_ctl -s -D ${DATADIR} start'"
# su postgres -c '/usr/bin/openqa-setup-db'

echo "hold open"
# keep container running while waiting for connections
tail -f /dev/null

# su postgres -c "bash -c '/usr/bin/pg_ctl -D ${DATADIR} stop'"
cleanup