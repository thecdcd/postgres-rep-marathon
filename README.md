# postgres-rep-marathon

[PostgreSQL](http://www.postgresql.org/) replication on [Marathon](https://mesosphere.github.io/marathon/).

# Contents
The files:

1. `run_rep.sh` is the script for Marathon to execute to run the replication process.
1. `pg_hba.conf` is the `pg_hba.conf` file with the `replication` role added to the end. This is for example purposes.
1. `postgresql.conf` is a minimal configuration file for a postgresql replication node.
1. `marathon.json` contains an example Marathon app configuration.

# Node Setup
The rules for configuring a node.

## PostgreSQL Versioning
Each node that will be running postgres must have the system package installed. For debian and Ubuntu, this can be done with `apt-get -y install postgresql`. The postgresql version must match the master instance! If the master is running `9.3`, then all replication nodes must be running `9.3`.

postgresql versioning considers the first two numbers as the major version (`9.3`.11) and the third number as minor (9.3.`11`). As long as the major version matches, a master instance can be replicated by any minor version.

## ~/.pgpass
The script (`run_rep.sh`) assumes a valid and working [~/.pgpass file](http://www.postgresql.org/docs/9.4/static/libpq-pgpass.html) with the replication role's credentials. This should be in the home directory of the user that will run the postgresql instance.

Example:

```
*:*:*:replicationUser:mypassword
```

# Marathon
The Marathon piece is the shortest. Place the config and script files on a web host and point Marathon to the location for `run_rep.sh`

Example:

```
{
  "app": {
    "args": null,
    "cmd": "sh run_rep.sh",
    "cpus": 0.5,
    "disk": 10240,
    "env": {
      "CONFIG_URL": "http://web01/postgres/conf",
      "POSTGRES_MASTER": "postgres01",
      "POSTGRES_REPUSER": "replicator",
      "RUN_USER": "postgres"
    },
    "id": "/postgres-replication",
    "maxLaunchDelaySeconds": 3600,
    "mem": 512,
    "uris": [
      "http://web01/postgres/run_rep.sh"
    ]
  }
}
```

## Env Variables
The script takes the follow environment variables:

* `CONFIG_URL` - Full URL to a directory that has `pg_hba.conf` and `postgresql.conf` for when those files are not transfered through `pg_basebackup`
* `POSTGRES_MASTER` - hostname or IP address of the postgresql master instance
* `POSTGRES_REPUSER` - The replication username. This should match what is in `~/.pgpass`
* `RUN_USER` - The system user to use when running the postgresql instance. **postgresql will not run as root!**
