#!/bin/sh

psql -U postgres -c 'create database privacydb' postgres
psql -U postgres -c 'create role api login PASSWORD NULL' postgres > /dev/null
psql -U postgres -c 'GRANT ALL ON DATABASE privacydb TO api' postgres
sem-apply --url postgresql://api@localhost/privacydb
