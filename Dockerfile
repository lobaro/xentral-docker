# See also: https://github.com/mpneuried/docker_wawision/blob/master/Dockerfile
# We used ubuntu 17 because php-mcrypt is missing in ubuntu 18
# see: https://askubuntu.com/questions/1031921/php-mcrypt-package-missing-in-ubuntu-server-18-04-lts
FROM ubuntu:20.04

#ENV XENTRAL_DOWNLOAD https://update.xentral.biz/download/19.1.1c1c4f2_oss_wawision.zip
ENV XENTRAL_INSTALLER_DOWNLOAD https://github.com/xentral-erp-software-gmbh/downloads/raw/master/installer.zip

# tzdata is needed for php-fpm
ENV TZ Europe/Berlin

# todo: needed?
ENV TERM=xterm

# install required system components
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata \
 && apt-get install -y wget unzip cron zip \
 && apt-get install -y nginx\
 && apt-get install -y php php-mysql php-cli \
 && apt-get install -y php-mysql php-soap php-imap php-fpm php-zip php-gd php-xml php-curl php-mbstring php-ldap php-intl php-ssh2 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# install wawision deps
RUN phpenmod imap

# install ioncube
RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
 && tar xfz ioncube_loaders_lin_x86-64.tar.gz && rm ioncube_loaders_lin_x86-64.tar.gz \
 && cp ./ioncube/loader-wizard.php /var/www/html/loader-wizard.php.bak \
 && cp ./ioncube/ioncube_loader_lin_7.4.so $(php -i | grep extension_dir | awk '{print $3}') \
 && rm -rf ./ioncube \
 && echo "zend_extension = \"$(php -i | grep extension_dir | awk '{print $3}')/ioncube_loader_lin_7.4.so\"" > /etc/php/7.4/mods-available/00-ioncube.ini \
 && chmod 777 /etc/php/7.4/mods-available/00-ioncube.ini \
 # zend extention for running PHP from bash e.g. for CRON
 && ln -s /etc/php/7.4/mods-available/00-ioncube.ini /etc/php/7.4/fpm/conf.d/00-ioncube.ini \
 && ln -s /etc/php/7.4/mods-available/00-ioncube.ini /etc/php/7.4/cli/conf.d/00-ioncube.ini

# Install Xentral (wawision)
WORKDIR /var/www/html/

RUN wget -O ./xentral.zip ${XENTRAL_INSTALLER_DOWNLOAD} \
 && rm index.html \
 && unzip xentral.zip -d /var/www/installer/ \
 && chown -R www-data: /var/www/installer/
# in case of tar.gz use:
#RUN tar -xzf wawision.tar.gz -C /var/www/html/ --strip-components=1

# TODO: Must be handled by a script
# ENV CONF_PATH /var/www/html/conf
# ENV USERDATA_PATH /var/www/html/userdata
# ENV DOWNLOADS_PATH /var/www/html/download


# /conf and  /userdata are important
# But also the application script are state that is updated, so we should keep the whole /html folder as a volume
VOLUME /var/www/html

COPY nginx/sites-available/default /etc/nginx/sites-available/default
COPY nginx/info.php /var/www/html/www/info.php

# Setup CRON
COPY cron.d/xentral /etc/cron.d/xentral
RUN chown root: /etc/cron.d/xentral && chmod 644 /etc/cron.d/xentral

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# TODO:
# Bitte löschen Sie den Ordner www/setup!

EXPOSE 80

COPY entry.sh /usr/local/bin/entry.sh
RUN chmod +x /usr/local/bin/entry.sh
ENTRYPOINT ["sh", "/usr/local/bin/entry.sh"]

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
