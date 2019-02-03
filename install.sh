#!/bin/bash

_=$(command -v docker);
if [ "$?" != "0" ]; then
  printf -- "You don\'t seem to have Docker installed.\n";
  printf -- "See README.md for installation instructions.\n";
  exit 127;
fi;

_=$(command -v docker-compose);
if [ "$?" != "0" ]; then
  printf -- "You don\'t seem to have docker-compose installed.\n";
  printf -- "See README.md for installation instructions.\n";
  exit 127;
fi;

_=$(command -v cgroups-mount);
if [ "$?" != "0" ]; then
  printf -- "You don\'t seem to have cgroups installed.\n";
  printf -- "See README.md for installation instructions.\n";
  exit 127;
fi;

set -e

DIR="$(dirname $0)"

mkdir -p cache

printf -- "Initializing cgroups...\n";
cgroups-mount

printf -- "Building the ioi_box_cms docker image...\n"
docker build -t ioi_box_cms .

printf -- "Fetching the postgres docker image...\n"
docker pull postgres

printf -- "Generating CMS configuration...\n"
PG_PASSWORD_FILE=${DIR}/config/pg_password.txt
CONF_TEMPLATE_FILE=${DIR}/config/cms.conf.template
CONF_FILE=${DIR}/config/cms.conf
POSTGRES_USER=cmsuser
POSTGRES_PASSWORD=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
CMS_TOKEN=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
cp "${CONF_TEMPLATE_FILE}" "${CONF_FILE}"
echo ${POSTGRES_PASSWORD} > "${PG_PASSWORD_FILE}"
sed -i -e "s/POSTGRES_USER/${POSTGRES_USER}/g" "${CONF_FILE}"
sed -i -e "s/POSTGRES_PASSWORD/${POSTGRES_PASSWORD}/g" "${CONF_FILE}"
sed -i -e "s/CMS_TOKEN/${CMS_TOKEN}/g" "${CONF_FILE}"

printf -- "Initializing the CMS database...\n"
docker-compose run cms /scripts/cms_init.sh

printf -- "Installation successful!\n"
printf -- "Admin username: admin, Admin password: admin\n"
printf -- "Dummy user username: user, Dummy user password: password\n"
printf -- "Please change the admin password at http://localhost:18889/admin/1 after starting the service\n"
printf -- "CMS admin interface: http://localhost:18889/\n"
printf -- "CMS contest interface: http://localhost:18888/\n"
