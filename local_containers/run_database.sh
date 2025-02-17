#!/bin/bash

set -eux


if [ -z "${DATADIR}" ]; then
	DATADIR='/var/lib/pgsql/data/'
fi

if [ -z "$(ls -A $DATADIR)" ]; then
	echo "Initializing PostgreSQL"
    su postgres -c "postgres -c max_connections=1000 -c shared_buffers=128MB"


	# su postgres -c "bash -c '/usr/bin/initdb ${DATADIR}'"
	# if [ $? -ne 0 ]; then
	# 	echo "Initialization failed."
	# 	exit 1
	# fi
fi

# su postgres -c "bash -c '/usr/bin/pg_ctl -s -D ${DATADIR} start'"
# su postgres -c '/usr/bin/openqa-setup-db'

echo "hold open"
# keep container running while waiting for connections
tail -f /dev/null

su postgres -c "bash -c '/usr/bin/pg_ctl -D ${DATADIR} stop'"
