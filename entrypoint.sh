#!/bin/bash

# Create a random string and use it for the postgres account password.
# The password is output to the screen or is available via docker logs.

if [ ! -s "$DATADIR/PG_VERSION" ]; then
    echo "initializing postgres data store for the first time..."

    if [ -z "$POSTGRES_PASSWORD" ]; then
        echo "no password specified, creating random password...."
        $POSTGRES_PASSWORD="$(date +%s | sha256sum | base64 | head -c 32 ; echo)"
        echo "postgres:$POSTGRES_PASSWORD"
    fi

    mkdir -p "$PGDATA"
    chmod 700 "$PGDATA"
    chown -R postgres "$PGDATA"

    PGBIN="/usr/lib/postgresql/$PG_VERSION/bin"

    echo "initializing..."
    su postgres sh -c "$PGBIN/initdb -E 'UTF-8'"

    rm $PGDATA/*.conf

    su postgres sh -c "postgres --single -c config_file="/etc/postgresql/postgresql.conf"" <<< "ALTER USER "postgres" WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';"

    echo "initialized"
else
    echo "Postgres Database already exists. Doing nothing."
fi

exec "$@"
