################################################
# ALASTRIA REGULAR NODE
################################################

FROM ubuntu:18.04 AS builder

# Install basic dependencies and tools
RUN \
    apt-get update && apt-get -y install \
        git \
        curl \
        dnsutils \
        net-tools \
        nano \
        mc \
        logrotate \
        software-properties-common unzip wget git\
        make gcc libsodium-dev build-essential libdb-dev zlib1g-dev \
        libtinfo-dev sysvbanner psmisc libleveldb-dev\
        libsodium-dev libdb5.3-dev dnsutils \
    && apt-get autoremove \
    && apt-get clean

RUN echo "sed 's/navigate_with_arrows=false/navigate_with_arrows=true/' /root/.config/mc/ini" > /root/mci.sh \
    && echo "/usr/share/mc/bin/mc.sh" >> /root/mci.sh 

# Install Golang compiler in default path: /usr/local/go
ENV GOLANG_VERSION go1.9.5.linux-amd64.tar.gz
RUN wget https://storage.googleapis.com/golang/${GOLANG_VERSION} \
    && tar -C /usr/local -xvzf ${GOLANG_VERSION} \
    && rm -f ${GOLANG_VERSION}

# Set variables for the go installation
ENV PATH=".:${PATH}:/usr/local/go/bin"

# Install Quorum
WORKDIR /root
RUN git clone https://github.com/alastria/quorum.git \
    && cd quorum \
    && git checkout 775aa2f5a6a52d9d84c85d5ed73521a1ea5b15b3 \
    && make all \
    && cp build/bin/geth /usr/local/bin \
    && cp build/bin/bootnode /usr/local/bin \
    && cd /root

# We use multi-stage building to keep the final image as slim as possible
################################################
# PRODUCTION ALASTRIA REGULAR NODE
################################################

FROM ubuntu:18.04 AS production

# Install the minimum required tools in production
RUN \
    apt-get update && apt-get -y install \
        wget \
        nano \
        mc \
    && apt-get autoremove \
    && apt-get clean

# Configure Midnight Commander to navigate with the arrow keys
RUN echo "sed -i 's/navigate_with_arrows=false/navigate_with_arrows=true/' /root/.config/mc/ini" > /root/mci.sh \
    && echo "/usr/share/mc/bin/mc.sh" >> /root/mci.sh 

# Copy the Quorum/Geth executables from the previous stage
COPY --from=builder /root/quorum/build/bin/* /usr/local/bin/

# Set the volumes to share data with the host
VOLUME /root/alastria

WORKDIR /root

# This is the NETID for Alastria RedT
ENV NETID 83584648538

# The type of node. This Dockerfile only supports Regular nodes
ENV NODE_TYPE regular

# The identity of the node (will be publicly displayed in Ethstats)
ENV NODE_NAME REG_IN2_Telsius_2_4_00

# The P2P network listening port
ENV P2P_PORT 21000

# The Ethstats server where to send the info
ENV NETSTATS_TARGET bb98a0b6442386d0cdf8a31b267892c1@netstats.telsius.alastria.io:80

# Enable the JSON-RPC server, setting this to "--rpc"
ENV ENABLE_RPC "--rpc"

# The JSON-RPC network listening address. Only allow local calls
ENV RPCADDR 0.0.0.0

# The port to use for JSONRPC
ENV RPCPORT 22000

# Allowed protocols via JSON-RPC
ENV RPCAPI admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul

# Enable the WS-RPC server, setting this to "--ws"
ENV ENABLE_WS "--ws"

# WS-RPC server listening interface (default: "localhost")
ENV WSADDR 0.0.0.0

# WS-RPC server listening port (default: 8546)
ENV WSPORT 22001

# API's offered over the WS-RPC interface
ENV WSAPI admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul

# The timeout for the IBFT protocol execution (inactivity of the proposer)
ENV ISTANBUL_REQUESTTIMEOUT 10000

# Blockchain sync mode
ENV SYNCMODE full

# Blockchain garbage collection mode
ENV GCMODE full

# Target gas limit sets the artificial target gas floor for the blocks to mine
ENV TARGETGASLIMIT 8000000

# General logging verbosity: 0=silent, 1=error, 2=warn, 3=info, 4=debug, 5=detail
ENV VERBOSITY 3

# Per-module verbosity: comma-separated list of <pattern>=<level> (e.g. eth/*=5,p2p=4)
ENV VMODULE consensus/istanbul/core/core.go=5

# Any additional arguments
ENV ADDITIONAL_ARGS "--debug --vmdebug --nodiscover"

# Copy the entrypoint script from the build context
COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD ["start"]