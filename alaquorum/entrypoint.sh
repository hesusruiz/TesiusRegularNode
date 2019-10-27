#!/bin/bash

# This is the main entrypoint to the docker container

set -e

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "echo TRAPed signal" HUP INT QUIT TERM

if [ "$1" = 'start' ]; then

    # Create the data directory if it does not exist yet
    mkdir -p /root/alastria/data

    # Make sure we are in /root
    cd /root

    # Update the list of boot nodes every time that we start
    wget -q https://raw.githubusercontent.com/alastria/alastria-node/testnet2/data/boot-nodes.json

    # Create the JSON files with the boot nodes from the Alastria Git repository
    echo "[" > temporal.json
    cat /root/boot-nodes.json >> temporal.json
    sed '$ s/,//' temporal.json > /root/alastria/data/static-nodes.json
    echo "]" >> /root/alastria/data/static-nodes.json
    cp /root/alastria/data/static-nodes.json /root/alastria/data/permissioned-nodes.json
    rm -f temporal.json

    # Generate the nodekey and enode_address if it is not already generated
    if [ ! -e /root/alastria/data/ENODE_ADDRESS ]
    then

        # Create the nodekey in the /root/alastria/data/geth directory
        cd /root/alastria/data/geth
        bootnode -genkey nodekey

        # Get the enode key and write it in a local file for later starts of the docker
        ENODE_ADDRESS=$(bootnode -nodekey nodekey -writeaddress)
        echo $ENODE_ADDRESS > ENODE_ADDRESS
        echo $ENODE_ADDRESS > /root/alastria/data/ENODE_ADDRESS

        # Go back to /root
        cd /root

        echo "INFO [00-00|00:00:00.000|entrypoint.sh:46] ENODE_ADDRESS generated."

    fi


    # Perform one-time initialization if not already
    if [ ! -e /root/alastria/data/INITIALIZED ]
    then

        # Download the genesis block from the Alastria node repository
        wget -q https://raw.githubusercontent.com/alastria/alastria-node/testnet2/data/genesis.json
        echo "INFO [00-00|00:00:00.000|entrypoint.sh:57] Genesis block downloaded."

        # Initialize the Blockchain structure
        echo "INFO [00-00|00:00:00.000|entrypoint.sh:60] Initialize the Blockchain with the genesis block"
        geth --datadir /root/alastria/data init /root/genesis.json

        # Create a default account and set the password to Passw0rd
        echo "Passw0rd" > ./account_pass
        mkdir -p /root/alastria/data/keystore
        geth --datadir /root/alastria/data --password ./account_pass account new
        rm ./account_pass

        # Signal that the initialization process has been performed
        # Write the file INITIALIZED in the /root directory
        cd /root
        echo "INITIALIZED" > /root/alastria/data/INITIALIZED

    fi

    # Set the arguments to start geth
    cd /root

    GLOBAL_ARGS="--networkid $NETID \
--identity $NODE_NAME \
--permissioned \
$ENABLE_RPC \
--rpcaddr $RPCADDR \
--rpcapi $RPCAPI \
--rpcport $RPCPORT \
$ENABLE_WS \
--wsaddr $WSADDR \
--wsapi $WSAPI \
--wsport $WSPORT \
--port $P2P_PORT \
--istanbul.requesttimeout $ISTANBUL_REQUESTTIMEOUT \
--ethstats $NODE_NAME:$NETSTATS_TARGET \
--verbosity $VERBOSITY \
--emitcheckpoints \
--targetgaslimit $TARGETGASLIMIT \
--syncmode $SYNCMODE \
--gcmode $GCMODE \
--vmodule $VMODULE  "

    # Start the geth node
    echo "INFO [00-00|00:00:00.000|entrypoint.sh:101] Start geth --datadir /root/alastria/data $GLOBAL_ARGS $ADDITIONAL_ARGS"
    exec geth --datadir /root/alastria/data $GLOBAL_ARGS $ADDITIONAL_ARGS

fi

exec "$@"

