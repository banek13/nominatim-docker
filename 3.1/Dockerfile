FROM phusion/baseimage:0.11

MAINTAINER banek13

# Update image
RUN apt-get -qq update && apt-get -qq upgrade -y -o \
      Dpkg::Options::="--force-confold"

# Update locales
USER root
RUN apt-get install -y --no-install-recommends locales
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8


# Add postgresql sources
USER root
RUN apt-get install -y --no-install-recommends wget
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" >> \
      /etc/apt/sources.list && \
    wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | \
      apt-key add -
RUN apt-get -qq update

# Set build variables
ARG PGSQL_VERSION=11
ARG POSTGIS_VERSION=2.5

RUN apt-get -y update -qq && \
    apt-get -y install locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    apt-get install -y build-essential cmake g++ libboost-dev libboost-system-dev \
    libboost-filesystem-dev libexpat1-dev zlib1g-dev libxml2-dev\
    libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev \
    postgresql-server-dev-${PGSQL_VERSION} postgresql-${PGSQL_VERSION}-postgis-${POSTGIS_VERSION} postgresql-contrib-${PGSQL_VERSION} \
    apache2 php php-pgsql libapache2-mod-php php-pear php-db \
    php-intl git curl sudo \
    python-pip libboost-python-dev \
    osmosis && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/*

WORKDIR /app

# Configure postgres
RUN echo "host all  all    0.0.0.0/0  trust" >> /etc/postgresql/${PGSQL_VERSION}/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/${PGSQL_VERSION}/main/postgresql.conf && \
    
# Create nominatim user account
USER root
RUN useradd -d /app/nominatim -s /bin/bash -m nominatim
ENV USERNAME nominatim
ENV USERHOME /app/nominatim
RUN chmod a+x ${USERHOME}

# Nominatim install
USER nominatim
ARG REPLICATION_URL=https://planet.osm.org/replication/hour/
ENV NOMINATIM_VERSION v3.2.0
RUN git clone --recursive https://github.com/openstreetmap/Nominatim ./src
RUN echo $'<?php\n\
      # Paths
      @define('CONST_Postgresql_Version', '${PGSQL_VERSION}'); \n\
      @define('CONST_Postgis_Version', '${POSTGIS_VERSION}'); \n\
      @define('CONST_Osm2pgsql_Flatnode_File', '/srv/nominatim/flatnode'); \n\
      @define('CONST_Pyosmium_Binary', '/usr/local/bin/pyosmium-get-changes'); \n\
      # Website settings
      @define('CONST_Website_BaseURL', '/nominatim/'); \n\
      @define('CONST_Replication_Url', '${REPLICATION_URL}'); \n\
      @define('CONST_Replication_MaxInterval', '86400'); \n\
      @define('CONST_Replication_Update_Interval', '86400'); \n\
      @define('CONST_Replication_Recheck_Interval', '900'); \n'\
    > ./src/Nominatim/settings/local.php
RUN wget -O src/data/country_osm_grid.sql.gz \
      http://www.nominatim.org/data/country_grid.sql.gz
RUN cd .src && git checkout tags/$NOMINATIM_VERSION && git submodule update --recursive --init && \ 
    cd .. && mkdir -p ${USERHOME}/build && \
    cd ${USERHOME}/build && \
    cmake ${USERHOME}/src && \
    make

# Osmium install to run continuous updates
RUN pip install osmium

# Apache configure
USER root
COPY nominatim.conf /etc/apache2/conf-available/nominatim.conf
RUN a2enconf nominatim

EXPOSE 5432
EXPOSE 8080

COPY start.sh /app/start.sh
COPY startapache.sh /app/startapache.sh
COPY startpostgres.sh /app/startpostgres.sh
COPY init.sh /app/init.sh


