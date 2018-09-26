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

RUN apt-get install -y php-mysql php-soap php-imap php-fpm php-zip php-gd php-xml php-curl php-mbstring php7.1-ldap
RUN phpenmod imap
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# install ioncube
RUN wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
RUN tar xfz ioncube_loaders_lin_x86-64.tar.gz && rm ioncube_loaders_lin_x86-64.tar.gz
#RUN cp ./ioncube/loader-wizard.php /var/www/html/
RUN cp ./ioncube/ioncube_loader_lin_7.1.so $(php -i | grep extension_dir | awk '{print $3}')
RUN rm -rf ./ioncube
RUN echo "zend_extension = \"$(php -i | grep extension_dir | awk '{print $3}')/ioncube_loader_lin_7.1.so\"" > /etc/php/7.1/apache2/conf.d/00-ioncube.ini
RUN chmod 777 /etc/php/7.1/apache2/conf.d/00-ioncube.ini



# Install Xentral (wawision)
WORKDIR /var/www/html/

#RUN ls
RUN wget -O ./wawision.tar.gz https://xentral.biz/download-files/openwawision-18-1-php-quelltext/18.1.1dd84a9_oss_wawision.tar.gz
RUN rm index.html
RUN tar -xzf wawision.tar.gz -C /var/www/html/ --strip-components=1

#RUN ls /var/www/html/

# redefine user
RUN chown -R www-data:www-data /var/www/html/
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

VOLUME /var/www/html/conf
VOLUME /var/www/html/userdata

# TODO:
#Um den Prozessstarter nutzen zu können: Tragen Sie folgendes Script in ihrer crontab ein:
#php /var/www/html/cronjobs/starter.php
#
#oder lassen Sie die Seite
#https://172.18.0.22/www/index.php?module=welcome&action=cronjob
#regelmässig aufrufen. Am besten eignet sich ein Interval von einer Minute.
# Bitte löschen Sie den Ordner www/setup!

EXPOSE 80

CMD ["apachectl", "-e", "info", "-D", "FOREGROUND"]
