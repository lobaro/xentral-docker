# See also: https://github.com/mpneuried/docker_wawision/blob/master/Dockerfile
FROM ubuntu:17.10

ENV XENTRAL_DOWNLOAD=https://update.xentral.biz/download/19.1.1c1c4f2_oss_wawision.zip

# https://xentral.biz/download-files/openwawision-18-1-php-quelltext/18.1.1dd84a9_oss_wawision.tar.gz
# https://update.xentral.biz/download/19.1.1c1c4f2_oss_wawision.zip

RUN apt-get update

# install apache
RUN apt-get install -y apache2 wget unzip cron
RUN echo "ServerName 0.0.0.0" >> /etc/apache2/apache2.conf
RUN apache2ctl configtest
RUN a2enmod rewrite

# install php
# TODO: php-mcrypt is missing in ubuntu 18: https://askubuntu.com/questions/1031921/php-mcrypt-package-missing-in-ubuntu-server-18-04-lts
RUN apt-get install -y php libapache2-mod-php php-mcrypt php-mysql php-cli

ENV TERM=xterm

# php.ini with increased memory_limit for CRON runner
COPY php.ini /etc/php/7.1/apache2/php.ini
RUN chmod 644 /etc/php/7.1/apache2/php.ini

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
RUN cp ./ioncube/loader-wizard.php /var/www/html/loader-wizard.php.bak
RUN cp ./ioncube/ioncube_loader_lin_7.1.so $(php -i | grep extension_dir | awk '{print $3}')
RUN rm -rf ./ioncube
RUN echo "zend_extension = \"$(php -i | grep extension_dir | awk '{print $3}')/ioncube_loader_lin_7.1.so\"" > /etc/php/7.1/apache2/conf.d/00-ioncube.ini
RUN chmod 777 /etc/php/7.1/apache2/conf.d/00-ioncube.ini

# zend extention for running PHP from bash e.g. for CRON
RUN  ln -s /etc/php/7.1/apache2/conf.d/00-ioncube.ini /etc/php/7.1/cli/conf.d/00-ioncube.ini

# Install Xentral (wawision)
WORKDIR /var/www/html/

#RUN ls
RUN wget -O ./wawision.zip ${XENTRAL_DOWNLOAD}
RUN rm index.html
RUN unzip wawision.zip -d /var/www/html/
#RUN tar -xzf wawision.tar.gz -C /var/www/html/ --strip-components=1

#RUN ls /var/www/html/

# redefine user
RUN chown -R www-data:www-data /var/www/html/
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

VOLUME /var/www/html/conf
VOLUME /var/www/html/userdata

# Setup CRON
COPY crontab /etc/crontab
RUN chown root:root /etc/crontab
RUN chmod 722 /etc/crontab

# TODO:
# Bitte löschen Sie den Ordner www/setup!

EXPOSE 80

COPY entry.sh /usr/local/bin/entry.sh
RUN chmod +x /usr/local/bin/entry.sh
RUN ln -s usr/local/bin/entry.sh / # backwards compat
ENTRYPOINT ["sh", "/usr/local/bin/entry.sh"]

CMD ["apachectl", "-e", "info", "-D", "FOREGROUND"]


