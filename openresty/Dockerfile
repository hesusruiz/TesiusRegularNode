################################################
# OpenResty nginx flavour
################################################

FROM ubuntu:bionic

RUN \
    apt-get update && apt-get -y install \
        gnupg2 \
        wget \
        mc \
    && wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add - \
    && apt-get -y install software-properties-common \
    && add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        openresty

# Configure Midnight Commander to navigate with the arrow keys
RUN echo "sed -i 's/navigate_with_arrows=false/navigate_with_arrows=true/' /root/.config/mc/ini" > /root/mci.sh \
    && echo "/usr/share/mc/bin/mc.sh" >> /root/mci.sh 

RUN rm -f /etc/openresty/*

CMD ["openresty", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT