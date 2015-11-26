#!/bin/bash
#
# This requires .pgpass and postgres user
#
# POSTGRES_MASTER - IP address or hostname of postgres master
# POSTGRES_REPUSER - the database user to use for replication.
#						the password is expected in .pgpass
# CONFIG_URL 	- base URL to fetch configs, script will add file names
#					http://web01/path/to/configs
# RUN_USER		- local user to run postgres
set -e

#####################################################################
#
# Globals
#
#####################################################################
WHOAMI="$( id -un )"
PG_CONF="postgresql.conf"
PG_DATA="pgdata"
HBA_CONF="pg_hba.conf"

#####################################################################
#
# Functions
#
#####################################################################
perform_backup() {
	mkdir $PG_DATA && chmod 0700 $PG_DATA && chown -R $RUN_USER $PG_DATA
	su -c "pg_basebackup -D $PG_DATA -X stream -w -R --dbname=\"host=$POSTGRES_MASTER user=$POSTGRES_REPUSER\"" $RUN_USER
	cd $PG_DATA
}

fix_config_files() {
	# if it didn't copy over some files, it is probably
	# a debian system.
	if [ ! -f "$PG_CONF" ]; then
		curl -o "$PG_CONF" "$CONFIG_URL/$PG_CONF"
	fi

	if [ ! -f "$HBA_CONF" ]; then
		curl -o "$HBA_CONF" "$CONFIG_URL/$HBA_CONF"
	fi
}

write_inet_setting() {
	echo "listen_addresses = '*'" >> $PG_CONF
	echo "port = $PORT0" >> $PG_CONF
}

write_stats_setting() {
	mkdir -p "mesos.pg_stat_tmp"
	echo "stats_temp_directory = 'mesos.pg_stat_tmp'" >> $PG_CONF
}

write_sockets_setting() {
	# sockets
	mkdir -p pg_sockets
	echo "unix_socket_directories = 'pg_sockets'" >> $PG_CONF
}

write_log_setting() {
	# logging
	mkdir -p pg_log
	echo "log_directory = 'pg_log'" >> $PG_CONF
}

fix_ownership() {
	if [ "$WHOAMI" != "$RUN_USER" ]; then
		chown -R $RUN_USER .
	fi
}

run_postgres() {
	su -c "/usr/lib/postgresql/9.4/bin/postgres -D ." $RUN_USER
}

#####################################################################
#
# Run
# 1. Perform the postgres backup. **
# 2. Fix missing config files
# 3-6. Append settings to config file. Last value in file wins.
# 7. Fix ownership of files and directories to postgres user
# 8. Run postgres replicant **
#
# ** Requires a valid ~/.pgpass
#
#####################################################################
perform_backup
fix_config_files
write_inet_setting
write_stats_setting
write_sockets_setting
write_log_setting
fix_ownership
run_postgres
