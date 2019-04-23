#!/bin/bash

service postgresql start
tail -f /var/log/postgresql/postgresql-%PGSQL_VERSION%-main.log
