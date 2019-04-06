# See also: https://github.com/mpneuried/docker_wawision/blob/master/Dockerfile
# We use ubuntu 17 because php-mcrypt is missing in ubuntu 18
# see: https://askubuntu.com/questions/1031921/php-mcrypt-package-missing-in-ubuntu-server-18-04-lts
FROM ubuntu:17.10

ENV XENTRAL_DOWNLOAD https://update.xentral.biz/download/19.1.1c1c4f2_oss_wawision.zip

# tzdata is needed for php-fpm
ENV TZ Europe/Berlin

# todo: needed?
ENV TERM=xterm

# install required system components
RUN apt-get update \
 && apt-get install -y wget unzip cron \
 && apt-get install -y apache2 \
 && apt-get install -y php libapache2-mod-php php-mcrypt php-mysql php-cli \
 && apt-get install -y php-mysql php-soap php-imap php-fpm php-zip php-gd php-xml php-curl php-mbstring php7.1-ldap \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# install apache
RUN echo "ServerName 0.0.0.0" >> /etc/apache2/apache2.conf
RUN apache2ctl configtest
RUN a2enmod rewrite

# install wawision deps
RUN phpenmod imap

# install ioncube
RUN wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
 && tar xfz ioncube_loaders_lin_x86-64.tar.gz && rm ioncube_loaders_lin_x86-64.tar.gz \
 && cp ./ioncube/loader-wizard.php /var/www/html/loader-wizard.php.bak \
 && cp ./ioncube/ioncube_loader_lin_7.1.so $(php -i | grep extension_dir | awk '{print $3}') \
 && rm -rf ./ioncube \
 && echo "zend_extension = \"$(php -i | grep extension_dir | awk '{print $3}')/ioncube_loader_lin_7.1.so\"" > /etc/php/7.1/apache2/conf.d/00-ioncube.ini \
 && chmod 777 /etc/php/7.1/apache2/conf.d/00-ioncube.ini \
 # zend extention for running PHP from bash e.g. for CRON
 && ln -s /etc/php/7.1/apache2/conf.d/00-ioncube.ini /etc/php/7.1/cli/conf.d/00-ioncube.ini

# Install Xentral (wawision)
WORKDIR /var/www/html/

RUN wget -O ./wawision.zip ${XENTRAL_DOWNLOAD} \
 && rm index.html \
 && unzip wawision.zip -d /var/www/html/ \
 && chown -R www-data: /var/www/html/
# in case of tar.gz use:
#RUN tar -xzf wawision.tar.gz -C /var/www/html/ --strip-components=1

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

VOLUME /var/www/html/conf
VOLUME /var/www/html/userdata

# Setup CRON
COPY crontab /etc/crontab
RUN chown root: /etc/crontab && chmod 644 /etc/crontab

# TODO:
# Bitte löschen Sie den Ordner www/setup!

EXPOSE 80

COPY entry.sh /usr/local/bin/entry.sh
RUN chmod +x /usr/local/bin/entry.sh
ENTRYPOINT ["sh", "/usr/local/bin/entry.sh"]

CMD ["apachectl", "-e", "info", "-D", "FOREGROUND"]


