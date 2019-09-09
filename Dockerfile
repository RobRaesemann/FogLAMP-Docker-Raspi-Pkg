FROM schachr/raspbian-stretch
#
# FogLAMP on Raspberry PI from Packages
#

# Install packages required for FogLAMP
RUN apt update && \
    apt -y install wget rsyslog python3-dbus python3-pip iputils-ping sysstat curl && \
    wget --quiet https://s3.amazonaws.com/foglamp/debian/armhf/foglamp-1.6.0-armhf.tgz && \
    tar -xzvf ./foglamp-1.6.0-armhf.tgz && \
    # Install dependencies of the base FogLAMP package
    apt -y install `dpkg -I ./foglamp-1.6.0-armhf/foglamp-1.6.0-armhf.deb | awk '/Depends:/{print$2}' | sed 's/,/ /g'` && \
    # Extract files from base FogLAMP package
    dpkg-deb -R ./foglamp-1.6.0-armhf/foglamp-1.6.0-armhf.deb foglamp-1.6.0-armhf && \
    # Extract files for Notification Service
    dpkg-deb -R ./foglamp-1.6.0-armhf/foglamp-service-notification-1.6.0-armhf.deb foglamp-service-notification-1.6.0-armhf && \
    # Notification plugins
    dpkg-deb -R ./foglamp-1.6.0-armhf/foglamp-notify-python35-1.6.0-armhf.deb foglamp-notify-python35-1.6.0-armhf && \
    # North
    dpkg-deb -R ./foglamp-1.6.0-armhf/foglamp-north-httpc-1.6.0-armhf.deb foglamp-north-httpc-1.6.0-armhf && \
    # South
    dpkg-deb -R ./foglamp-1.6.0-armhf/foglamp-south-sinusoid-1.6.0.deb foglamp-south-sinusoid-1.6.0 && \
    dpkg-deb -R ./foglamp-1.6.0-armhf/foglamp-south-benchmark-1.6.0-armhf.deb foglamp-south-benchmark-1.6.0-armhf && \
    dpkg-deb -R ./foglamp-1.6.0-armhf/foglamp-south-systeminfo-1.6.0.deb foglamp-south-systeminfo-1.6.0 && \
    # Copy extracted package files to destination directories
    cp -r ./foglamp-1.6.0-armhf/usr /. && \
    cp -r ./foglamp-service-notification-1.6.0-armhf/usr /. && \
    cp -r ./foglamp-notify-python35-1.6.0-armhf/usr /. && \
    cp -r ./foglamp-north-httpc-1.6.0-armhf/usr /. && \
    cp -r ./foglamp-south-sinusoid-1.6.0/usr /. && \
    cp -r ./foglamp-south-benchmark-1.6.0-armhf/usr /. && \
    cp -r ./foglamp-south-systeminfo-1.6.0/usr /. && \
    # move blank database to foglamp data directory
    mv /usr/local/foglamp/data.new /usr/local/foglamp/data && \
    cd /usr/local/foglamp && \
    ./scripts/certificates foglamp 365 && \
    chown -R root:root /usr/local/foglamp && \
    chown -R ${SUDO_USER}:${SUDO_USER} /usr/local/foglamp/data && \
    pip3 install -r /usr/local/foglamp/python/requirements.txt && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /foglamp* /usr/include/boost

ENV FOGLAMP_ROOT=/usr/local/foglamp 

WORKDIR /usr/local/foglamp
COPY foglamp.sh foglamp.sh
RUN chown root:root /usr/local/foglamp/foglamp.sh \
    && chmod 777 /usr/local/foglamp/foglamp.sh

RUN pip3 install pymodbus

VOLUME /usr/local/foglamp/data

# FogLAMP API port
EXPOSE 8081 1995 502

# start rsyslog, FogLAMP, and tail syslog
CMD ["bash","/usr/local/foglamp/foglamp.sh"]

LABEL maintainer="rob@raesemann.com" \
      author="Rob Raesemann" \
      target="Raspi" \
      version="1.6.0" \