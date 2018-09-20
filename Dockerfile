# See also: https://github.com/mpneuried/docker_wawision/blob/master/Dockerfile
FROM ubuntu:17.10

RUN apt-get update

# install apache
RUN apt-get install -y apache2 wget
RUN echo "ServerName 0.0.0.0" >> /etc/apache2/apache2.conf
RUN apache2ctl configtest
RUN a2enmod rewrite

# install php
# TODO: php-mcrypt is missing in ubuntu 18: https://askubuntu.com/questions/1031921/php-mcrypt-package-missing-in-ubuntu-server-18-04-lts
RUN apt-get install -y php libapache2-mod-php php-mcrypt php-mysql php-cli

ENV TERM=xterm

# install wawision deps
# tzdata is needed for php-fpm
ENV TZ Europe/Berlin
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata

RUN apt-get install -y php-mysql php-soap php-imap php-fpm php-zip php-gd php-xml php-curl php-mbstring
RUN phpenmod imap

# Install Xentral (wawision)
WORKDIR /var/www/html/

#RUN ls
RUN wget -O ./wawision.tar.gz https://xentral.biz/download-files/openwawision-18-1-php-quelltext/18.1.1dd84a9_oss_wawision.tar.gz
RUN rm index.html
RUN tar -xzf wawision.tar.gz -C /var/www/html/ --strip-components=1

#RUN ls /var/www/html/

# redefine user
RUN chown -R www-data:www-data /var/www
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

VOLUME /var/www/html

# /var/www/html/userdata should be backed up

# TODO:
#Um den Prozessstarter nutzen zu können: Tragen Sie folgendes Script in ihrer crontab ein:
#php /var/www/html/cronjobs/starter.php
#
#oder lassen Sie die Seite
#https://172.18.0.22/www/index.php?module=welcome&action=cronjob
#regelmässig aufrufen. Am besten eignet sich ein Interval von einer Minute.
# Bitte löschen Sie den Ordner www/setup!

EXPOSE 80

## HERE WE ARE
RUN ls /var/www/html


CMD ["apachectl", "-e", "info", "-D", "FOREGROUND"]
