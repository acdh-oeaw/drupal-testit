#!/bin/bash

if [[ -f /opt/drupal/web/sites/default/settings.php ]]
then
  echo "settings.php found, using it"
else
  echo "no settings.php found, create a new one"
  cp /opt/drupal/web/sites/default/default.settings.php /opt/drupal/web/sites/default/settings.php
  # inject the correct values
  sed -i /opt/drupal-repo/docker/drupal_settings.php \
    -e "s/DBNAME/${DBNAME:-}/g" \
    -e "s/DBUSER/${DBUSER:-}/g" \
    -e "s/DBPSWD/${DBPSWD:-}/g" \
    -e "s/DBPREFIX/${DBPREFIX:-}/g" \
    -e "s/DBHOST/${DBHOST:-}/g" \
    -e "s/DBPORT/${DBPORT:-}/g" \
    -e "s/DRUPALHASH/${DRUPALHASH:-}/g"
  #  -e "s|DRUPALTRUSTEDHOST|$DRUPALTRUSTEDHOST/g"
  # temporary deactivate trustedhost - copied here to test how to get it to work - delete and only use the one above when it works
  # sed -i /opt/drupal-repo/docker/drupal_settings.php \
  #   -e "s|DRUPALTRUSTEDHOST|${DRUPALTRUSTEDHOST:-}|g"
  cat /opt/drupal-repo/docker/drupal_settings.php >> /opt/drupal/web/sites/default/settings.php
fi

echo "get config import status"
CONFIGEXIST=""
CONFIGDIR="/opt/drupal-repo/config/"
if [ -d "$CONFIGDIR" ]
then
  if [ "$(ls -A $CONFIGDIR)" ]; then
    echo "Configuration exists, will import it"
    CONFIGEXIST=" --existing-config"
  else
    echo "No configuration files to import."
  fi
else
  echo "Configuration directory $CONFIGDIR does not exist."
fi

# check if the database is already initialized (via https://drupal.stackexchange.com/a/317187)
echo "check database"
# we need to handle possible table prefixes
# for this would be drush sql-query --db-prefix "SELECT 1 from {config} LIMIT 0,1"
# but this needs ANSI_MODE enabled in mariadb which unfortunately is not on our cluster
# therefore use the not so fancy version with the environment variable
# alternative: use on our cluster the init_commands for drush, see https://github.com/drush-ops/drush/issues/2636
drush sql-query "SELECT 1 FROM ${DBPREFIX}config LIMIT 0,1" > /dev/null 2>&1
if [[ $? == 0 ]]; then
  echo "Database is up and initialized, running possible updates"

  # TODO: make a backup of the database before doing the updates
  # an upgrade must be done manually

  # run all the updates (maybe not necessary as we already did the install - this is the official way to run an update)
  composer update "drupal/*" --with-all-dependencies --no-interaction

  # run possible update scripts
  drush --no-interaction updatedb

  # if config-directory is not empty then import the configuration
  if [ -n "${CONFIGEXIST}" ]; then
    # if there is an uuid set then adapt the uuid every time 
    if [ -n "${DRUPALUUID}" ]; then
      # set the uuid otherwise import does not work
      drush --no-interaction config-set "system.site" uuid "${DRUPALUUID}"
    fi
    # import the configuration
    drush --no-interaction config:import
  fi

else
  echo "Database is not initialized, set up a new instance of Drupal"

  # TODO: should we create the database and the user? we expect that it is already there (at least docker-compose does this and other databases should be also prepared in this way)
  # otherwise use: `drush --no-interaction sql:create ...`

  # create a new Drupal instance
  # TODO: check the values
  # TODO: DBPREFIX missing here, can be added with --db-prefix (but only if set!)
  # DRUPALINSTALLMODE is either standard or minimal, using one of them means that all derived Drupals are also based on it, this is important for the import of configuration
  # if you use e.g. minimal at the original source and here install as standard, you won't be able to import the configuration, as both must match the install mode
  # update: standard will not work with configexist, as it has a hook_install, thus need to use minimal and to convert old ones to minimal
  drush site:install ${DRUPALINSTALLMODE} --no-interaction -vvv --db-url="${DBDRIVER}://${DBUSER}:${DBPSWD}@${DBHOST}:${DBPORT}/${DBNAME}" --site-name="${SITENAME}" --account-name="${DRUPALUSER}" --account-pass="${DRUPALPSWD}"${CONFIGEXIST}
fi

# clean and rebuild the cache
drush --no-interaction cache:rebuild

# check and update the translations
# only necessary if there is locale used and translations
# TODO: check if locale is in use
# drush --no-interaction locale:check
# drush --no-interaction locale:update

# TODO: the files directory is not set or has not the correct accessibility after initializing the system
# testing if running the status does correct the files directory settings
drush --no-interaction status

# there must be a running process that will restart the container, if this process ends
# TODO: we also have such a process running in the upper-root entrypoint, thus it is necessary to close both entrypoints - how to solve this?
apache2ctl -D FOREGROUND
# source /etc/apache2/envvars && sudo exec /usr/sbin/apache2 -D FOREGROUND
