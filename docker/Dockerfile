FROM drupal:10-apache

RUN apt-get update && \
    apt-get install -y vim mariadb-client unzip

# copy current structure into container
# todo: it is expected, that a Drupal was already set up otherwise run the initial dockerfile local and push the results - also there should be already a setup database instance (or a local container which is filled with data)
# for development we create bindings, whereas for deployment on the server we just copy the files
# for deployment not every directory is necessary, e.g. files/ and settings/ is bound as a volume, no need to copy it
# we also separate the repo-files from the drupal-directory (using /opt/drupal-repo/ for the files in the repository), especially is this necessary for deployment on the production server
# it is also necessary for the relative path of the custom themes/modules used in composer.json
RUN mkdir /opt/drupal-repo
COPY ./composer/ /opt/drupal-repo/composer/
COPY ./config/ /opt/drupal-repo/config/
# the README.txt is only a hint when the directory is empty, otherwise it is not part of the config and therefore is deleted (important as in the entrypoint-script it will check if the config-directory is empty or not and based on this will try to import the config)
RUN rm /opt/drupal-repo/config/README.txt
COPY ./custom/ /opt/drupal-repo/custom/

# install from the existing composer.json
RUN cd /opt/drupal \
    && rm composer.json composer.lock \
    && ln -s /opt/drupal-repo/composer/composer.json composer.json \
    && composer install

# prepare the entrypoint
COPY ./docker/start.sh /opt/drupal-repo/docker/start.sh
COPY ./docker/drupal_settings.php /opt/drupal-repo/docker/drupal_settings.php

# run the entrypoint
CMD ["bash", "-c", "/opt/drupal-repo/docker/start.sh"]
# ENTRYPOINT /opt/drupal-repo/docker/start.sh

