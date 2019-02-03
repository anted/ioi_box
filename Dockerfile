FROM ubuntu:18.04

# Update packages
RUN apt-get update

# Install tzdata first to avoid interactive questions
RUN apt-get -y install tzdata

# Install prerequisites
RUN apt-get -y install build-essential g++ openjdk-8-jdk-headless \
    postgresql-client python3.6 python3-pip cppreference-doc-en-html \
    cgroup-lite libcap-dev zip wget curl python3.6-dev libpq-dev \
    libcups2-dev libyaml-dev libffi-dev locales

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Get CMS
RUN wget https://github.com/cms-dev/cms/releases/download/v1.4.rc1/v1.4.rc1.tar.gz
RUN tar xvf v1.4.rc1.tar.gz

# Install dependencies
WORKDIR /cms
RUN pip3 install -r requirements.txt

# Build and install CMS
RUN python3 prerequisites.py --as-root build
RUN python3 prerequisites.py --as-root install
RUN python3 setup.py install

# Get the dockerize tool
ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Copy helper scripts
ADD scripts/ /scripts/

# Create an empty config file, we will mount the real one during startup
RUN touch /usr/local/etc/cms.conf

# Expose logs
VOLUME ["/var/local/log/cms"]

# Expose ports
EXPOSE 8888
EXPOSE 8889

# Run 
USER cmsuser
CMD ["/scripts/cms_start.sh"]
