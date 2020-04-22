# Pull base image.
FROM ubuntu:18.04

MAINTAINER Daigo Tanaka <daigo.tanaka@gmail.com>

# upgrade is not recommended by the best practice page
# RUN apt-get -y upgrade

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive

# Define locale
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

# Install dependencies via apt-get
# Note: Always combine apt-get update and install
RUN set -ex \
    && buildDeps=' \
        python-dev \
        python3-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libpq-dev \
    ' \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        sudo \
        apparmor-utils \
        python-setuptools \
        python-pip \
        python3-requests \
        python3-setuptools \
        python3-pip \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        wget \
        git \
        openssh-server \
        gdebi-core \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

#        vim \
#        libmysqlclient-dev \
#         postgresql postgresql-contrib \
#         mysql-client \
#        mysql-server \


#######
#  Add tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

########
# SSH stuff

RUN mkdir -p /var/run/sshd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
# Or do this?
# RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

########
# Additional installs
RUN apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
            libxi6 \
            libgconf-2-4 \
            gnupg2 \
            xvfb \
            unzip \
            vim

########
# Install Chromedriver

# Set up the Chrome PPA
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

# Update the package list and install chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list && \
    apt-get update -y && \
    apt-get install -y \
        google-chrome-stable \
        chromium-browser

# Set up Chromedriver Environment variables
ENV CHROMEDRIVER_DIR /selenium_driver
RUN mkdir -p $CHROMEDRIVER_DIR

# Download and install Chromedriver
RUN CHROMEVER=$(google-chrome --product-version | grep -o "[^\.]*\.[^\.]*\.[^\.]*") && \
    DRIVERVER=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROMEVER") && \
    wget -q --continue -P $CHROMEDRIVER_DIR "http://chromedriver.storage.googleapis.com/$DRIVERVER/chromedriver_linux64.zip" && \
    unzip $CHROMEDRIVER_DIR/chromedriver* -d $CHROMEDRIVER_DIR

# Put Chromedriver into the PATH
ENV PATH $CHROMEDRIVER_DIR:$PATH

RUN chmod a+x $CHROMEDRIVER_DIR/chromedriver

########
# Firefox

RUN apt-get update -y && \
    apt-get install -y \
        firefox
RUN wget -q --continue -P $CHROMEDRIVER_DIR "https://github.com/mozilla/geckodriver/releases/download/v0.26.0/geckodriver-v0.26.0-linux64.tar.gz" && \
    tar xvfz $CHROMEDRIVER_DIR/geckodriver* -C $CHROMEDRIVER_DIR

RUN chmod a+x $CHROMEDRIVER_DIR/geckodriver

# Actually, copy everything under $CHROMEDRIVER to /usr/bin because $PATH is not
# honored with python subprocess with shell=True that is required for Docker
# to run subprocess...
RUN cp -r $CHROMEDRIVER_DIR/* /usr/bin

########
# app installation

COPY . /app

RUN rm -fr /app/.env

RUN chmod 777 -R /app

WORKDIR /app

RUN pip3 install wheel
RUN pip3 install --no-cache-dir -e ./tap_webcrawl/json_schema_gen
RUN pip3 install --no-cache-dir -e ./tap_webcrawl
RUN pip3 install --no-cache-dir -e ./target-bigquery
RUN pip3 install -r requirements.txt

RUN chmod a+x /usr/local/bin/*

ENTRYPOINT [ "/tini", "--" ]
CMD python3 runner.py ${COMMAND:-default} -d ${DATA:-{}}
