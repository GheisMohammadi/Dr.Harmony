#!/bin/bash

# Dr.Harmony version
DrHarmony_Version=$(cat ./drharmony.v)

cat << "EOF"
 ____       _   _                                        
|  _ \ _ __| | | | __ _ _ __ _ __ ___   ___  _ __  _   _ 
| | | | '__| |_| |/ _` | '__| '_ ` _ \ / _ \| '_ \| | | |
| |_| | |  |  _  | (_| | |  | | | | | | (_) | | | | |_| |
|____/|_|  |_| |_|\__,_|_|  |_| |_| |_|\___/|_| |_|\__, |
                                                   |___/
EOF
echo "                 Version: $DrHarmony_Version"
echo " "

LOCAL_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(dig @resolver3.opendns.com myip.opendns.com +short)
HEIGHT=22
WIDTH=40
CHOICE_HEIGHT=10
BACKTITLE="Harmony Node Utilities - Dr.Harmony-V$DrHarmony_Version"
MENU="Choose one of the following options:"
menu_result="notready"

function checkVersion {
    RemoteVersion=$(curl --silent https://raw.githubusercontent.com/GheisMohammadi/Dr.Harmony/main/drharmony.v)
    if [ "$DrHarmony_Version" != "$RemoteVersion" ]; then
        echo "there is a new version:$RemoteVersion, let's update DrHarmony to newest version..."
        rm ./drharmony.sh
        curl --silent -O https://raw.githubusercontent.com/GheisMohammadi/Dr.Harmony/main/drharmony.sh && sudo chmod +x ./drharmony.sh
        rm ./drharmony.v
        curl --silent -O https://raw.githubusercontent.com/GheisMohammadi/Dr.Harmony/main/drharmony.v
        sudo ./drharmony.sh
        exit
    fi
}

checkVersion
#========================================================================
# init binaries
#========================================================================
HMY=$(which hmy)
if [ -z "$HMY" ]; then
    HMY=./hmy
    if [[ ! -f $HMY ]]; then
        HMY=/usr/sbin/hmy
        if [[ ! -f $HMY ]]; then
            HMY=~/hmy
            if [[ ! -f $HMY ]]; then
                # hmy is not installed
                HMY=""
                echo "hmy not found."
            fi
        fi
    fi
fi


HARMONY=$(which harmony)
LOGS_DIR="${a%/*}/latest"
if [ -z "$HARMONY" ]; then
    HARMONY=./harmony
    LOGS_DIR="./latest"
    if [[ ! -f $HARMONY ]]; then
        HARMONY=/usr/sbin/harmony
        LOGS_DIR="./usr/sbin"
        if [[ ! -f $HARMONY ]]; then
            HARMONY=~/harmony
            LOGS_DIR="~"
            if [[ ! -f $HARMONY ]]; then
                # harmony is not installed
                HARMONY=""
                LOGS_DIR=""
                echo "harmony not found."
            fi
        fi
    fi
fi

#========================================================================
# User Inputs
#========================================================================
function waitForAnyKey {
    echo "------------------------------------------"
    read -p "Hit enter to continue ..."
}

function getUserInput {
    exec 3>&1;
    user_input=$(dialog --inputbox $input_msg 0 0 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;
    echo $user_input $exitcode;
}

#========================================================================
# Requirements
#========================================================================
function checkRequirements {
    echo "Checking for dependencies..."
    REQUIRED_PKG="dialog"
    # check whether dialog is installed
    #APT_OK=$(dpkg-query -W --showformat='${Status}\n' apt|grep "install ok installed")
    #YUM_OK=$(dpkg-query -W --showformat='${Status}\n' yum|grep "install ok installed")
    if [ -z "$(command -v $REQUIRED_PKG)" ]; then
        if [ -n "$(command -v apt-get)" ]; then
            echo "installing $REQUIRED_PKG (apt) ..."
            sudo apt-get -y update
            sudo apt-get install -y $REQUIRED_PKG
        elif [ -n "$(command -v yum)" ]; then
            echo "installing $REQUIRED_PKG (yum) ..."
            sudo yum -y update
            sudo yum install -y $REQUIRED_PKG
        elif [ -n "$(command -v brew)" ]; then
            echo "installing $REQUIRED_PKG (brew) ..."
            sudo brew -y update
            sudo brew install -y $REQUIRED_PKG
        else 
            echo "install dependencies failed, it needs either apt, yum or brew"
        fi
    fi

    if [ -z "$(command -v jq)" ]; then
        if [ -n "$(command -v apt-get)" ]; then
            echo "installing jq (apt) ..."
            sudo apt-get -y update
            sudo apt-get install -y jq
        elif [ -n "$(command -v yum)" ]; then
            echo "installing jq (yum) ..."
            sudo yum -y update
            sudo yum install -y jq
        elif [ -n "$(command -v brew)" ]; then
            echo "installing jq (brew) ..."
            sudo brew -y update
            sudo brew install -y jq
        else 
            echo "install dependencies failed, it needs either apt, yum or brew"
        fi
    fi

    if [ -f $HMY ]; then
        echo "hmy command is ready"
    else
        unameOut="$(uname -s)"
        case "${unameOut}" in
            Linux*)     #machine=Linux
                curl -LO https://harmony.one/hmycli && mv hmycli hmy && chmod +x hmy
                HMY=./hmy
                ;;
            Darwin*)    #machine=Mac
                curl -O https://raw.githubusercontent.com/harmony-one/go-sdk/master/scripts/hmy.sh
                chmod u+x hmy.sh
                ./hmy.sh -d
                HMY=./hmy
                ;;
            CYGWIN*)    #machine=Cygwin
                curl -LO https://harmony.one/hmycli && mv hmycli hmy && chmod +x hmy
                HMY=./hmy
                ;;
            MINGW*)     #machine=MinGw
                curl -LO https://harmony.one/hmycli && mv hmycli hmy && chmod +x hmy
                HMY=./hmy
                ;;
            *)          
                HMY=""
                machine="UNKNOWN:${unameOut}"
                echo "not supported os ($machine)!"
        esac
    fi

}

#========================================================================
# Dependencies
#========================================================================
function askForNetwork {
    echo "setup new harmony validator "

    network_options=(1 "mainnet"
                     2 "testnet"
                     3 "devnet")

    new_node_network_id=$(dialog --clear \
                    --backtitle "$BACKTITLE" \
                    --title "Select network" \
                    --ok-label "Next" --nocancel \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${network_options[@]}" \
                    2>&1 >/dev/tty)
    clear
    new_node_network_name="unknown"
    
    case $new_node_network_id in
            1)
                new_node_network_name="mainnet"
                ;;
            2)
                new_node_network_name="testnet"
                ;;
            3)
                new_node_network_name="devnet"
                ;;
    esac

}

function installHarmonyDependenciesUsingApt {
    #install harmony deps
    sudo apt install -y git libgmp-dev  libssl-dev  make gcc g++ jq
}

function installHarmonyDependenciesUsingYum {
    sudo yum install -y git glibc-static gmp-devel gmp-static openssl-libs openssl-static gcc-c++ jq
}

function installHarmonyDependenciesUsingBrew {
    brew install gmp
    brew install openssl
    sudo ln -sf /usr/local/opt/openssl@1.1 /usr/local/opt/openssl
}

function installHarmonyDependencies {
    #APT_OK=$(dpkg-query -W --showformat='${Status}\n' apt|grep "install ok installed")
    #YUM_OK=$(dpkg-query -W --showformat='${Status}\n' yum|grep "install ok installed")
    if [ -n "$(command -v apt)" ]; then
        echo "installing dependencies (apt) ..."
        installHarmonyDependenciesUsingApt
    elif [ -n "$(command -v yum)" ]; then
        echo "installing dependencies (yum) ..."
        installHarmonyDependenciesUsingYum
    elif [ -n "$(command -v brew)" ]; then
        echo "installing dependencies (brew) ..."
        installHarmonyDependenciesUsingBrew
    else 
        echo "install dependencies failed, it needs either apt, yum or brew"
    fi
}

function installGo {
    GO_OK=$(go version|grep "go version")
    if [ "$GO_OK" = "" ]; then
        go_version="1.22.5"
        go_file_name="go$go_version.linux-amd64.tar.gz"
        go_url="https://storage.googleapis.com/golang/$go_file_name"
        wget $go_url
        #we have to remove current go folder, otherwise it creates a broken go
        rm -rf /usr/local/go
        sudo tar -C /usr/local -xzvf $go_file_name
        rm $go_file_name
        sudo ln -sfn /usr/local/go/bin/go /usr/bin/
        sudo ln -sfn /usr/local/go/bin/gofmt /usr/bin/
        echo "export PATH=\"/usr/local/go/bin:$PATH\"" >> ~/.bashrc
        source ~/.bashrc
    fi     

    CHECK_GO_INSTALL=$(go version|grep "go version")
    if [ "$CHECK_GO_INSTALL" = "" ]; then
        alias go=/usr/local/go/bin/go
        alias gofmt=/usr/local/go/bin/gofmt
    fi

    go version
}

function downloadAndBuildSourceCode {
    buildresult="FAIL"
    GO_OK=$(go version|grep "go version")
    if [ "$GO_OK" = "" ]; then
        echo "can't find go language or maybe go language is not installed yet"
        echo "please try  'source ~/.profile'  and try again"
    else
        mkdir -p $(go env GOPATH)/src/github.com/harmony-one
        cd $(go env GOPATH)/src/github.com/harmony-one
        git clone https://github.com/harmony-one/mcl.git
        git clone https://github.com/harmony-one/bls.git
        git clone https://github.com/harmony-one/harmony.git
        cd harmony
        #if not using harmony repo
        if [ $use_hmy_repo -eq 1 ]; then
            git remote rm origin2
            git remote add origin2 $repo
        fi
        git branch -vv
        if [ ${#branch_name} -ge 3 ]; then
            git checkout $branch_name
            if [ $use_hmy_repo -eq 0 ]; then
                git pull origin $branch_name
            else
                git pull origin2 $branch_name
            fi
        fi
        go mod tidy
        make
        make linux_static
        cp ./bin/harmony ~/
        cd ~
        chmod +x harmony
        buildresult="OK"
    fi
}

function buildHarmonyBinary {
    exec 3>&1;
    from_hmy_repo=$(dialog --yesno "build from harmony repository?" 0 0 2>&1 1>&3);
    use_hmy_repo=$?;
    exec 3>&-;

    #if not using harmony repo, then ask the repo
    if [ $use_hmy_repo -eq 1 ]; then
        exec 3>&1;
        repo=$(dialog --nocancel --ok-label "Next" --inputbox "please enter the repository url" 0 0 "https://github.com/GheisMohammadi/harmony.git" 2>&1 1>&3);
        exitstatus=$?;
        exec 3>&-;
        echo "build from harmony repo:$repo";
    fi

    exec 3>&1;
    branch_name=$(dialog --nocancel --ok-label "Next" --inputbox "build from which branch?" 0 0 "main" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;
    echo "build from branch:$branch_name";

    installHarmonyDependencies
    installGo
    downloadAndBuildSourceCode
    echo "done"
}

#========================================================================
# Install New Node
#========================================================================
function createBlsKeys {
    exec 3>&1;
    shard_num=$(dialog --nocancel --ok-label "Next" --inputbox "shard number?" 0 0 "0" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;
    echo "build validator key for shard: $shard_num";

    exec 3>&1;
    keys_count=$(dialog --nocancel --ok-label "Next" --inputbox "how many keys?" 0 0 "1" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;
    echo "number of keys: $keys_count";

    echo $shard_num > shard.txt
    echo $new_node_network_name > network.txt

    exec 3>&1;
    key_password=$(dialog --nocancel --ok-label "Next" --inputbox "enter passphrase for keys" 0 0 "123" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    echo $key_password > "./keypass.txt" 
    $HMY keys generate-bls-keys --count $keys_count --shard $shard_num --passphrase-file "./keypass.txt" 
    rm "./keypass.txt"
}

function setupSystemd {

    if [ -z "$new_node_network_name" ]; then 
        askForNetwork
    fi

    echo "
    [Unit]
    Description=Harmony daemon
    After=network-online.target

    [Service]
    Type=simple
    Restart=always
    RestartSec=1
    User=$USER
    WorkingDirectory=${HOME%/}
    ExecStart=${HOME%/}/harmony --network $new_node_network_name --config './harmony.conf'
    SyslogIdentifier=harmony
    StartLimitInterval=0
    LimitNOFILE=65536
    LimitNPROC=65536

    [Install]
    WantedBy=multi-user.target" | sudo tee /etc/systemd/system/harmony.service

    sudo chmod 755 /etc/systemd/system/harmony.service
    sudo systemctl enable harmony.service
}

function continueInstallNewNode {
    # create bls keys
    createBlsKeys

    # move bls keys to .hmy/blskeys folder
    mkdir -p ".hmy/blskeys"

    # create passphrase files
    for file in *.key; do 
        echo "$key_password" > "${file%.key}.pass"
    done

    mv *.key .hmy/blskeys
    mv *.pass .hmy/blskeys

    # download db for mainnet
    if [ $new_node_network_name == "mainnet" ]; then
        echo "install rclone and sync db using that, it may takes a couple of hours or a few days, so be patient plz ..."
        rclone
    fi

    echo "dump the config file ..."
    ./harmony config dump ./harmony.conf --network $new_node_network_name

    echo "run validator ..."
    setupSystemd
    sudo service harmony start

    echo "new node is up and running!" 
}

function installNewNodeFromBinaryFile {
    echo "install new harmony node from binary file ..."
    
    cd ~
    binary_name="binary"
    
    case $new_node_network_id in
            1)
                #"mainnet"
                binary_name="binary"
                ;;
            2)
                #"testnet"
                binary_name="binary_testnet"
                ;;
            3)
                #"devnet"
                binary_name="binary-arm64"
                ;;
    esac

    curl -LO "https://harmony.one/$binary_name"
    mv $binary_name harmony
    chmod +x harmony

    continueInstallNewNode
}

function installNewNodeFromSourceCode {
    # install golang
    # install deps
    # install node
    echo "install new harmony node from source code ..."
    buildHarmonyBinary
    if [ $buildresult == "OK" ]; then
        continueInstallNewNode
    else
        echo "new node installation failed. as you fix the issue, try again"
    fi
}

function installNewNode {
    echo "setup new harmony validator "

    install_options=(1 "build binary from source code"
                     2 "download binary"
                     3 "install rclone"
                     4 "create new bls key")

    clear
    new_node_menu_res="done"
    
    while [ $new_node_menu_res == "done" ]
    do
        
        selected_install_option=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "Run New Validator" \
                --ok-label "Install" --cancel-label "Back" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${install_options[@]}" \
                2>&1 >/dev/tty)

        clear
        
        case $selected_install_option in
            1)
                askForNetwork
                installNewNodeFromSourceCode 
                ;;
            2)
                askForNetwork
                installNewNodeFromBinaryFile
                ;;
            3)
                install_rclone
                ;;
            4)
                createBlsKeys
                ;;
            *)
                new_node_menu_res="back"
                ;;
        esac

        if [ $new_node_menu_res == "done" ]; then
            waitForAnyKey
        fi
    done

}

#========================================================================
# Snap DB
#========================================================================
function createSnapDB {
    ./harmony dumpdb /data/harmony_db_0 /root/data/snapdb/harmony_db_0
}

#========================================================================
# Blockchain & RPC
#========================================================================
function getTransactionsHistory {
    exec 3>&1;
    accAddress=$(dialog --nocancel --ok-label "Next" --inputbox "account address" 0 0 "one..." 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    curl --location --request POST  '0.0.0.0:9500' \
    --header 'Content-Type: application/json' \
    --data-raw "{
        \"jsonrpc\": "2.0",
        \"id\": 1,
        \"method\": \"hmyv2_getTransactionsHistory\",
        \"params\": [{
            \"address\": \"$accAddress\",
            \"pageIndex\": 0,
            \"pageSize\": 1000,
            \"fullTx\": true,
            \"txType\": \"ALL\",
            \"order\": \"DESC\"
        }]
    }"
    waitForAnyKey
}

# sample result
# {"jsonrpc":"2.0","id":1,"result":"0x0"}
function hmyGetBalance {
    exec 3>&1;
    accAddress=$(dialog --nocancel --ok-label "Next" --inputbox "account address" 0 0 "one..." 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    ADDR="0x320b3FedBaF5A15Ad50F5c2ff4A659cf4dB64B02"
    URL="0.0.0.0:9500"
    curl $URL -H "Content-Type: application/json" -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hmy_getBalance\",\"params\":[\"${accAddress}\", \"latest\"],\"id\":1}"
    
    waitForAnyKey
}

function getBlockByNumber {
    exec 3>&1;
    blknumber=$(dialog --nocancel --ok-label "Next" --inputbox "block number" 0 0 "123" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    blknum=0x$(printf "%x\n" $blknumber)

    URL="0.0.0.0:9500"
    curl $URL -H "Content-Type: application/json" -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hmy_getBlockByNumber\",\"params\":[\"${blknum}\", true],\"id\":1}"
    
    waitForAnyKey
}

function getBlockByHash {
    exec 3>&1;
    blkhash=$(dialog --nocancel --ok-label "Next" --inputbox "block hash" 0 0 "0x660fe701f580ffebfcfb4af1836c9929c1fd0014d8d79d60749fecf52df7a90d" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    URL="0.0.0.0:9500"
    curl $URL -H "Content-Type: application/json" -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hmy_getBlockByHash\",\"params\":[\"${blkhash}\", true],\"id\":1}"
    
    waitForAnyKey
}

function getTransactionByHash {
    exec 3>&1;
    txHash=$(dialog --nocancel --ok-label "Next" --inputbox "transaction hash" 0 0 "0x1dff358dad4d0fc95b11acc9826b190d8b7971ac26b3f7ebdee83c10cafaf86f" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    URL="0.0.0.0:9500"
    curl $URL -H "Content-Type: application/json" -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hmy_getTransactionByHash\",\"params\":[\"${txHash}\"],\"id\":1}"
    
    waitForAnyKey
}

function getTransactionByBlockNumber {
    exec 3>&1;
    blknumber=$(dialog --nocancel --ok-label "Next" --inputbox "block number" 0 0 "123" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    blknum=0x$(printf "%x\n" $blknumber)

    exec 3>&1;
    txindex=$(dialog --nocancel --ok-label "Next" --inputbox "transaction index" 0 0 "0x0" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    URL="0.0.0.0:9500"
    curl $URL -H "Content-Type: application/json" -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hmy_getTransactionByBlockNumberAndIndex\",\"params\":[\"${blknum}\",\"${txindex}\"],\"id\":1}"
    
    waitForAnyKey
}

function getTransactionByBlockHash {
    exec 3>&1;
    blkhash=$(dialog --nocancel --ok-label "Next" --inputbox "block hash" 0 0 "0x428ead93e632d5255ea3d1fb61b02ab8493cf562a398af2159c33ecd53c62c16" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    exec 3>&1;
    txindex=$(dialog --nocancel --ok-label "Next" --inputbox "transaction index" 0 0 "0x0" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    URL="0.0.0.0:9500"
    curl $URL -H "Content-Type: application/json" -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hmy_getTransactionByBlockHashAndIndex\",\"params\":[\"${blkhash}\",\"${txindex}\"],\"id\":1}"
    
    waitForAnyKey
}

function getTransactionReceipt {
    exec 3>&1;
    txHash=$(dialog --nocancel --ok-label "Next" --inputbox "transaction hash" 0 0 "0x2fa714e40389cbbceda0f77e707035c0ec8aa940e8e10c0d445813177ea71e7d" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    URL="0.0.0.0:9500"
    curl $URL -H "Content-Type: application/json" -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hmy_getTransactionReceipt\",\"params\":[\"${txHash}\"],\"id\":1}"
    
    waitForAnyKey
}

function getBlocksAndTxCount {
    exec 3>&1;
    nfrom=$(dialog --nocancel --ok-label "Next" --inputbox "from block number" 0 0 "123" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    exec 3>&1;
    nto=$(dialog --nocancel --ok-label "Next" --inputbox "to block number" 0 0 "456" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    URL="0.0.0.0:9500"

    for ((i = nfrom; i <= nto; i++))
    do
        blknum=0x$(printf "%x\n" $i)
        txxCount=$(curl $URL -H "Content-Type: application/json" -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hmy_getBlockTransactionCountByNumber\",\"params\":[\"${blknum}\"],\"id\":1}" 2>/dev/null | jq -r ".result")
        echo "blk: $i ($blknum) -> txs count: ${txxCount}" 
    done

    waitForAnyKey
}

function ethGetBalance {
    exec 3>&1;
    accAddress=$(dialog --nocancel --ok-label "Next" --inputbox "account address" 0 0 "one..." 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    curl --location --request POST '0.0.0.0:9500' \
    --header 'Content-Type: application/json' \
    --data-raw "{
        \"jsonrpc\": \"2.0\",
        \"id\": 1,
        \"method\": \"eth_getBalance\",
        \"params\": [\"${accAddress}\", \"latest\"]
    }"
    
    waitForAnyKey
}

function showGasPrice {
    curl -d '{
        "jsonrpc":"2.0",
        "method":"hmy_gasPrice",
        "params":[],
        "id":1
    }' -H 'Content-Type:application/json' -X POST  '0.0.0.0:9500'

    waitForAnyKey
}

function blockchain {

    blockchain_options=(1 "account transactions history"
                        2 "check account balance"
                        3 "eth get balance"
                        4 "gas price"
                        5 "block by number"
                        6 "block by hash"
                        7 "get transaction by hash"
                        8 "get transaction by block number and index"
                        9 "get transaction by block hash and index"
                        10 "get transaction receipt"
                        11 "get blocks and tx count")

    blockchain_menu_result="done"

    while [ $blockchain_menu_result == "done" ]
    do
        selected_bc_option=$(dialog --clear \
                    --backtitle "$BACKTITLE" \
                    --title "blockchain info" \
                    --ok-label "Next" --cancel-label "Back" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${blockchain_options[@]}" \
                    2>&1 >/dev/tty)
        
        clear
        
        case $selected_bc_option in
            1)
                getTransactionsHistory 
                ;;
            2)
                hmyGetBalance
                ;;
            3)
                ethGetBalance
                ;;
            4)
                showGasPrice
                ;;
            5)
                getBlockByNumber
                ;;
            6)
                getBlockByHash
                ;;
            7)
                getTransactionByHash
                ;;
            8)
                getTransactionByBlockNumber
                ;;
            9)
                getTransactionByBlockHash
                ;;
            10)
                getTransactionReceipt
                ;;
            11)
                getBlocksAndTxCount
                ;;
            *)  
                blockchain_menu_result="back"
        esac
    done
}
#========================================================================
# rclone
#========================================================================
function rclone {
    set -x

    FOLDER=${1:-mainnet.min}
    HMY_DB_DIR=${2:-data}
    NODE_TYPE=${3:-Validator}

    while :; do
    if command -v rclone; then
        break
    else
        echo waiting for rclone ...
        sleep 10
    fi
    done

    sleep 3

    # stop harmony service
    sudo systemctl stop harmony.service

    unset shard

    # determine the shard number
    shard=$(cat shard.txt)
    if [ $shard != 0 ]; then #applicable for non S0 validator and explorer
    rclone sync -P --checksum release:pub.harmony.one/${FOLDER}/harmony_db_${shard} ${HMY_DB_DIR}/harmony_db_${shard} --multi-thread-streams 4 --transfers=16
    rclone sync -P --checksum release:pub.harmony.one/mainnet.snap/harmony_db_0 ${HMY_DB_DIR}/harmony_db_0 --multi-thread-streams 4 --transfers=64
    else
    if [ $NODE_TYPE = "Explorer" ]; then
        rclone sync -P --checksum release:pub.harmony.one/${FOLDER}/harmony_db_0 ${HMY_DB_DIR}/harmony_db_0 --multi-thread-streams 4 --transfers=64
    else
        rclone sync -P --checksum release:pub.harmony.one/mainnet.snap/harmony_db_0 ${HMY_DB_DIR}/harmony_db_0 --multi-thread-streams 4 --transfers=64
    fi
    fi

    # restart the harmony service
    sudo systemctl start harmony.service
}

function install_rclone {
    # error codes
    # 0 - exited without problems
    # 1 - parameters not supported were used or some unexpected error occurred
    # 2 - OS not supported by this script
    # 3 - installed version of rclone is up to date
    # 4 - supported unzip tools are not available

    set -e

    #when adding a tool to the list make sure to also add its corresponding command further in the script
    unzip_tools_list=('unzip' '7z' 'busybox')

    usage() { echo "Usage: curl https://rclone.org/install.sh | sudo bash [-s beta]" 1>&2; exit 1; }

    #check for beta flag
    if [ -n "$1" ] && [ "$1" != "beta" ]; then
        usage
    fi

    if [ -n "$1" ]; then
        install_beta="beta "
    fi


    #create tmp directory and move to it with macOS compatibility fallback
    tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'rclone-install.XXXXXXXXXX')
    cd "$tmp_dir"


    #make sure unzip tool is available and choose one to work with
    set +e
    for tool in ${unzip_tools_list[*]}; do
        trash=$(hash "$tool" 2>>errors)
        if [ "$?" -eq 0 ]; then
            unzip_tool="$tool"
            break
        fi
    done
    set -e

    # exit if no unzip tools available
    if [ -z "$unzip_tool" ]; then
        printf "\nNone of the supported tools for extracting zip archives (${unzip_tools_list[*]}) were found. "
        printf "Please install one of them and try again.\n\n"
        exit 4
    fi

    # Make sure we don't create a root owned .config/rclone directory #2127
    export XDG_CONFIG_HOME=config

    #check installed version of rclone to determine if update is necessary
    version=$(rclone --version 2>>errors | head -n 1)
    if [ -z "$install_beta" ]; then
        current_version=$(curl -fsS https://downloads.rclone.org/version.txt)
    else
        current_version=$(curl -fsS https://beta.rclone.org/version.txt)
    fi

    if [ "$version" = "$current_version" ]; then
        printf "\nThe latest ${install_beta}version of rclone ${version} is already installed.\n\n"
        exit 3
    fi


    #detect the platform
    OS="$(uname)"
    case $OS in
    Linux)
        OS='linux'
        ;;
    FreeBSD)
        OS='freebsd'
        ;;
    NetBSD)
        OS='netbsd'
        ;;
    OpenBSD)
        OS='openbsd'
        ;;
    Darwin)
        OS='osx'
        ;;
    SunOS)
        OS='solaris'
        echo 'OS not supported'
        exit 2
        ;;
    *)
        echo 'OS not supported'
        exit 2
        ;;
    esac

    OS_type="$(uname -m)"
    case "$OS_type" in
    x86_64|amd64)
        OS_type='amd64'
        ;;
    i?86|x86)
        OS_type='386'
        ;;
    aarch64|arm64)
        OS_type='arm64'
        ;;
    arm*)
        OS_type='arm'
        ;;
    *)
        echo 'OS type not supported'
        exit 2
        ;;
    esac


    #download and unzip
    if [ -z "$install_beta" ]; then
        download_link="https://downloads.rclone.org/rclone-current-${OS}-${OS_type}.zip"
        rclone_zip="rclone-current-${OS}-${OS_type}.zip"
    else
        download_link="https://beta.rclone.org/rclone-beta-latest-${OS}-${OS_type}.zip"
        rclone_zip="rclone-beta-latest-${OS}-${OS_type}.zip"
    fi

    curl -OfsS "$download_link"
    unzip_dir="tmp_unzip_dir_for_rclone"
    # there should be an entry in this switch for each element of unzip_tools_list
    case "$unzip_tool" in
    'unzip')
        unzip -a "$rclone_zip" -d "$unzip_dir"
        ;;
    '7z')
        7z x "$rclone_zip" "-o$unzip_dir"
        ;;
    'busybox')
        mkdir -p "$unzip_dir"
        busybox unzip "$rclone_zip" -d "$unzip_dir"
        ;;
    esac

    cd $unzip_dir/*

    #mounting rclone to environment

    case "$OS" in
    'linux')
        #binary
        cp rclone /usr/bin/rclone.new
        chmod 755 /usr/bin/rclone.new
        chown root:root /usr/bin/rclone.new
        mv /usr/bin/rclone.new /usr/bin/rclone
        #manual
        if ! [ -x "$(command -v mandb)" ]; then
            echo 'mandb not found. The rclone man docs will not be installed.'
        else
            mkdir -p /usr/local/share/man/man1
            cp rclone.1 /usr/local/share/man/man1/
            mandb
        fi
        ;;
    'freebsd'|'openbsd'|'netbsd')
        #binary
        cp rclone /usr/bin/rclone.new
        chown root:wheel /usr/bin/rclone.new
        mv /usr/bin/rclone.new /usr/bin/rclone
        #manual
        mkdir -p /usr/local/man/man1
        cp rclone.1 /usr/local/man/man1/
        makewhatis
        ;;
    'osx')
        #binary
        mkdir -p /usr/local/bin
        cp rclone /usr/local/bin/rclone.new
        mv /usr/local/bin/rclone.new /usr/local/bin/rclone
        #manual
        mkdir -p /usr/local/share/man/man1
        cp rclone.1 /usr/local/share/man/man1/
        ;;
    *)
        echo 'OS not supported'
        exit 2
    esac


    #update version variable post install
    version=$(rclone --version 2>>errors | head -n 1)

    printf "\n${version} has successfully installed."
    printf '\nNow run "rclone config" for setup. Check https://rclone.org/docs/ for more details.\n\n'
    exit 0
}

#========================================================================
# Enable StagedSync
#========================================================================
function enableStagedDNSSync {
    configFile="./harmony.conf"
    stagedsync=$(cat $configFile 2>/dev/null | grep "StagedSync =\|StagedSync=")
    if [[ -z $stagedsync ]]
    then
    ./harmony config update $configFile
    fi
    
    newstagedsync=$(cat $configFile 2>/dev/null | grep "StagedSync =\|StagedSync=")
    if [[ $newstagedsync =~ "false" ]]; then
        stgstr='\bStagedSync[ \t]*=[ \t]*false\b'
        sed -i "s|$stgstr|StagedSync = true|g" $configFile
        echo "staged sync is enabled"
    else
        echo "staged sync already enabled"
    fi

    waitForAnyKey
}

function disableStagedDNSSync {
    configFile="./harmony.conf"
    stagedsync=$(cat $configFile 2>/dev/null | grep "StagedSync =\|StagedSync=")
    if [[ -z $stagedsync ]]
    then
    ./harmony config update $configFile
    fi

    newstagedsync=$(cat $configFile 2>/dev/null | grep "StagedSync =\|StagedSync=")
    if [[ $newstagedsync =~ "true" ]]; then
        stgstr='\bStagedSync[ \t]*=[ \t]*true\b'
        sed -i "s|$stgstr|StagedSync = false|g" $configFile
        echo "staged sync is disabled"
    else
        echo "staged sync already disabled"
    fi

    waitForAnyKey
}

function enableLegacyStreamSync {
    # TODO: enable legacy stream sync (not completed yet)
    waitForAnyKey
}

function enableStagedStreamSync {
    # TODO: enable staged stream sync (not completed yet)
    waitForAnyKey
}

function adjustSyncMethod {
    sync_options=(1 "enable DNS legacy sync"
                  2 "enable staged DNS sync"
                  3 "enable stream sync"
                  4 "enable staged stream sync")

    sync_menu_result="done"

    while [ $sync_menu_result == "done" ]
    do
        selected_sync_option=$(dialog --clear \
                        --backtitle "$BACKTITLE" \
                        --title "Sync Method" \
                        --ok-label "Apply" --cancel-label "Back" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${sync_options[@]}" \
                        2>&1 >/dev/tty)
        clear
        case $selected_sync_option in
                1)
                    disableStagedDNSSync 
                    ;;
                2)
                    enableStagedDNSSync
                    ;;
                3)
                    enableLegacyStreamSync
                    ;;
                4)
                    enableStagedStreamSync
                    ;;
                *)
                    sync_menu_result="back"
                    ;;
        esac
    done
}

#========================================================================
# Info
#========================================================================
function showBinariesInfo {
    echo ''
    echo '#################################'
    echo '#  Harmony One CLI Information  #'
    echo '#################################'
    echo ''
    echo "hmy cli path: " ${HMY}
    $HMY version
    echo ''
    echo "harmony binary path: " ${HARMONY}
    $HARMONY version
    waitForAnyKey
}

function showBlockInformation {
    echo '##################################'
    echo '#    Block Number Information    #'
    echo '##################################'
    echo ''
    local_shard_0=$(${HMY} blockchain latest-headers | jq '.["result"]["beacon-chain-header"]' | jq -r .number | xargs printf "%d\n")
    local_shard_1=$(${HMY} blockchain latest-headers | jq '.["result"]["shard-chain-header"]' | jq -r .number | xargs printf "%d\n")
    remote_shard_0=$(${HMY} blockchain latest-headers -n api.s0.t.hmny.io | jq '.["result"]["shard-chain-header"]' | jq -r .number | xargs printf "%d\n")
    remote_shard_1=$(${HMY} blockchain latest-headers -n api.s1.t.hmny.io | jq '.["result"]["shard-chain-header"]' | jq -r .number | xargs printf "%d\n")
    behind_shard_0="$((remote_shard_0-local_shard_0))"
    behind_shard_1="$((remote_shard_1-local_shard_1))"
    echo "local_shard_0 = $local_shard_0 | remote_shard_0 = $remote_shard_0 | different $behind_shard_0"
    echo "local_shard_1 = $local_shard_1 | remote_shard_1 = $remote_shard_1 | different $behind_shard_1"
    echo ''
    waitForAnyKey
}

function showEc2Info {
    EC2_IP="x.x.x.x"
    echo ''
    echo '#################################'
    echo '#      AWS EC2 Information      #'
    echo '#################################'
    echo ''
    echo "ID   :" $(curl --silent http://$EC2_IP/latest/dynamic/instance-identity/document | jq '.instanceId' | tr -d '\"')
    echo "Type :" $(curl --silent http://$EC2_IP/latest/dynamic/instance-identity/document | jq '.instanceType' | tr -d '\"')
    echo ''
    echo ''
    waitForAnyKey
}

function showDiskInfo {
    echo '##################################'
    echo '# Disk Space Information (/) #'
    echo '##################################'
    echo ''
    echo "Partition Type :" $(df -Th | grep "/" | awk '{print $2}')
    echo "Total          :" $(df -Th | grep "/" | awk '{print $3}')
    echo "Used           :" $(df -Th | grep "/" | awk '{print $4}')
    echo "Avail          :" $(df -Th | grep "/" | awk '{print $5}')
    echo ''
    echo '##################################'
    echo '# Disk Space Information (/data) #'
    echo '##################################'
    echo ''
    echo "Partition Type :" $(df -Th | grep "/data" | awk '{print $2}')
    echo "Total          :" $(df -Th | grep "/data" | awk '{print $3}')
    echo "Used           :" $(df -Th | grep "/data" | awk '{print $4}')
    echo "Avail          :" $(df -Th | grep "/data" | awk '{print $5}')
    echo ''
    waitForAnyKey
}

function showBlockNumber {
    echo "current block number:"
    $HMY utility metadata | grep current-block-number
    waitForAnyKey
}

function showMetaData {
    $HMY utility metadata
    waitForAnyKey
}

function showChainInfo {
    $HMY utility metadata | grep -E "\"chain-id\"|current-epoch|current-block-number|shard-id"
    waitForAnyKey
}

function showNodeKey {
    echo "=================[ node key ]===================="
    cat ~/.hmy/blskeys/*.key
    echo ''
    echo '================================================='
    waitForAnyKey
}

function showUbuntuRelease {
    cat /etc/lsb-release
    waitForAnyKey
}

function showNetworkInfo {
    echo "node public ip address: $PUBLIC_IP"
    echo "node local ip address: $LOCAL_IP"
    $HMY utility metadata | grep -E "network|shard-id|role|dns-zone|peerid|node-unix-start-time"
    waitForAnyKey
}

function showConsensusInfo {
    $HMY utility metadata | jq -e ".result.consensus"
    waitForAnyKey
}

function showHeaders {
    while true; do $HMY blockchain latest-headers ; sleep 1; done
    waitForAnyKey
}

function showFullHardwareInfo {
    sudo apt-get install lshw
    sudo lshw -short 
    waitForAnyKey
}

function showListeningPorts {
    echo "harmony listening ports"
    echo "====================================================="
    sudo lsof -i -P -n | grep -E harmony | grep LISTEN
    echo "====================================================="
    echo "other listening ports"
    echo "====================================================="
    sudo lsof -i -P -n | grep -v harmony | grep LISTEN

    waitForAnyKey
}

function nodeInfo {

    node_info_options=(1 "all meta data"
                  2 "node key"
                  3 "network info"
                  4 "chain info"
                  5 "block number"
                  6 "headers"
                  7 "consensus"
                  8 "disk info"
                  9 "OS info"
                  10 "binaries info"
                  11 "EC2 info"
                  12 "Full hardware info"
                  13 "listening ports")

    info_menu_result="done"

    while [ $info_menu_result == "done" ]
    do
        selected_node_option=$(dialog --clear \
                        --backtitle "$BACKTITLE" \
                        --title "Current Node Info" \
                        --ok-label "Next" --cancel-label "Back" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${node_info_options[@]}" \
                        2>&1 >/dev/tty)
        clear

        case $selected_node_option in
                1)
                    showMetaData 
                    ;;
                2)
                    showNodeKey
                    ;;
                3)
                    showNetworkInfo
                    ;;
                4)
                    showChainInfo
                    ;;
                5)
                    showBlockInformation
                    ;;
                6)
                    showHeaders
                    ;;
                7)
                    showConsensusInfo
                    ;;
                8)
                    showDiskInfo
                    ;;
                9)
                    showUbuntuRelease
                    ;;
                10)
                    showBinariesInfo
                    ;;
                11)
                    showEc2Info
                    ;;
                12)
                    showFullHardwareInfo
                    ;;
                13)
                    showListeningPorts
                    ;;
                *)
                    info_menu_result="back"
                    ;;
        esac

    done
}

function progressbar {
   local title=$1 
   local elapsed=$2
   local duration=$3

   printf "[ $title ]"
   already_done() { for ((done=0; done<$elapsed; done++)); do printf "▇"; done }
   remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf " "; done }
   percentage() { printf "| %s%%" $(( (($elapsed)*100)/($duration)*100/100 )); }
   clean_line() { printf "\r"; }

   already_done; remaining; percentage
}

function showCpuRamUsage {
    # run for 10 seconds
    for i in {1..10}
    do
        clear
        echo "$i seconds ..."
        harmony_service_resource_usages=$(top -i -n 1 2>/dev/null | grep harmony)
        cpu_usage=$(echo  $harmony_service_resource_usages | awk '{ print $10}')
        ram_usage=$(echo  $harmony_service_resource_usages | awk '{ print $11}')

        cpu_p=$(awk -v v="$cpu_usage" 'BEGIN{printf "%d", v}')
        ram_p=$(awk -v v="$ram_usage" 'BEGIN{printf "%d", v}')

        # watch --interval 1 --no-title 'top -i -b 2>/dev/null | grep -E "harmony|PID|total|Task|Cpu"'
        progressbar "cpu" ${cpu_p} 100
        echo ""
        progressbar "ram" ${ram_p} 100
        echo ""

        sleep 1
    done
    waitForAnyKey
}

function showAllProcesses {
    top -i
    waitForAnyKey
}

function showHarmonyResourceUsage {
    top -p $(pgrep -n harmony)  
    waitForAnyKey
}

function showLiveHarmonyLogs {
   tail -f -n 1000 latest/zerolog-harmony.log
   waitForAnyKey
}

function showLiveBlockNumber {
    # run for 10 seconds
    for i in {1..5}
    do
        clear
        echo "$i seconds ..."
        cur_bn=$(curl -d '{
            "jsonrpc":"2.0",
            "method":"hmyv2_blockNumber",
            "params":[],
            "id":1
        }' -H 'Content-Type:application/json' -X POST '0.0.0.0:9500' 2>/dev/null | jq -r ".result")
        echo "Block Number: $cur_bn"

        sleep 2
    done
    waitForAnyKey
}

#    "consensus": {
#      "blocknum": 22094253,
#      "finality": 62,
#      "mode": "Listening",
#      "phase": "Announce",
#      "viewChangeId": 22098940,
#      "viewId": 22099119
#    }
function showLiveConsensus {
    # run for 10 seconds
    for i in {1..5}
    do
        clear
        echo "$i seconds ..."
        $HMY utility metadata | jq -e ".result.consensus"
        sleep 2
    done
    waitForAnyKey
}

function serviceLiveLogs {
    sudo journalctl -u harmony -n 100 -q --no-pager --all -f
    waitForAnyKey
}

function nodeWatch {
 
    node_watch_options=(1 "all processes"
                        2 "memory usage" 
                        3 "harmony cpu/ram usage"
                        4 "harmony resource usages"
                        5 "harmony logs"
                        6 "harmony service logs"
                        7 "harmony block number"
                        8 "harmony live consensus")

    node_watch_menu_result="done"

    while [ $node_watch_menu_result == "done" ]
    do
        selected_watch_option=$(dialog --clear \
                        --backtitle "$BACKTITLE" \
                        --title "Node Watch Options" \
                        --ok-label "Next" --cancel-label "Back" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${node_watch_options[@]}" \
                        2>&1 >/dev/tty)
        clear

        case $selected_watch_option in
                1)
                    showAllProcesses
                    ;;
                2)
                    watch -n 5 free -m 
                    ;;
                3)
                    showCpuRamUsage
                    ;;
                4)
                    showHarmonyResourceUsage
                    ;;
                5)
                    showLiveHarmonyLogs
                    ;;
                6)
                    serviceLiveLogs
                    ;;
                7)
                    #while true; do $HMY utility metadata | grep current-block-number; sleep 2; clear; done
                    showLiveBlockNumber
                    ;;
                8)
                    showLiveConsensus
                    ;;
                *)
                    node_watch_menu_result="back"
                    ;;
        esac

    done
}

function currentNode {

    node_options=(1 "metadata and info"
                  2 "watch")

    current_node_menu_result="done"

    while [ $current_node_menu_result == "done" ]
    do
        selected_node_option=$(dialog --clear \
                        --backtitle "$BACKTITLE" \
                        --title "Current Node Options" \
                        --ok-label "Next" --cancel-label "Back" \
                        --menu "Node IP: $PUBLIC_IP\nSelect node option" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${node_options[@]}" \
                        2>&1 >/dev/tty)
        clear

        case $selected_node_option in
                1)
                    nodeInfo 
                    ;;
                2)
                    nodeWatch
                    ;;
                *)
                    current_node_menu_result="back"
        esac

    done
}

#========================================================================
# HARMONY SERVICE
#========================================================================
function restartHarmonyService {
    echo "restarting harmony service..."
    sudo systemctl restart harmony
    echo "done."
    waitForAnyKey
}

function startHarmonyService {
    echo "starting harmony service..."
    sudo systemctl start harmony
    echo "done."
    waitForAnyKey
}

function stopHarmonyService {
    echo "stopping harmony service..."
    sudo systemctl stop harmony
    echo "done."
    waitForAnyKey
}

function statusHarmonyService {
    sudo systemctl status harmony
    waitForAnyKey
}

function serviceLogs {
    sudo journalctl -u harmony -n 1000 -q --no-pager --all
    waitForAnyKey
}

function serviceDetails {
    sudo systemctl show harmony
    waitForAnyKey
}

function showServiceSystemd {
    sudo cat /etc/systemd/system/harmony.service 
    waitForAnyKey
}

function editServiceDetails {
    sudo nano /etc/systemd/system/harmony.service 
    sudo systemctl daemon-reload
    waitForAnyKey
}

function harmonyService {
    service_options=(1 "status"
            2 "restart"
            3 "start"
            4 "stop"
            5 "logs"
            6 "live logs"
            7 "details"
            8 "systemd details"
            9 "edit systemd details")

    service_menu_result="done"

    while [ $service_menu_result == "done" ]
    do
        selected_service_option=$(dialog --clear \
                        --backtitle "Harmony Service" \
                        --title "Harmony Service" \
                        --ok-label "Next" --cancel-label "Back" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${service_options[@]}" \
                        2>&1 >/dev/tty)
        clear
        case $selected_service_option in
                1)
                    statusHarmonyService 
                    ;;
                2)
                    restartHarmonyService
                    ;;
                3)
                    startHarmonyService
                    ;;
                4)
                    stopHarmonyService
                    ;;
                5)
                    serviceLogs
                    ;;
                6)
                    serviceLiveLogs
                    ;;
                7)
                    serviceDetails
                    ;;
                8)
                    showServiceSystemd
                    ;;
                9)
                    editServiceDetails
                    ;;
                *)
                    service_menu_result="back"
                    ;;
        esac

    done
}

#========================================================================
# BOOT NODE SERVICE
#========================================================================
function restartBootnodeService {
    echo "restarting bootnode service..."
    sudo systemctl restart bootnode
    echo "done."
    waitForAnyKey
}

function startBootnodeService {
    echo "starting bootnode service..."
    sudo systemctl start bootnode
    echo "done."
    waitForAnyKey
}

function stopBootnodeService {
    echo "stopping bootnode service..."
    sudo systemctl stop bootnode
    echo "done."
    waitForAnyKey
}

function statusBootnodeService {
    sudo systemctl status bootnode
    waitForAnyKey
}

function serviceBootnodeLogs {
    sudo journalctl -u bootnode -n 1000 -q --no-pager --all
    waitForAnyKey
}

function serviceBootnodeLiveLogs {
    sudo journalctl -u bootnode -n 100 -q --no-pager --all -f
    waitForAnyKey
}

function serviceBootNodeDetails {
    sudo systemctl show bootnode
    waitForAnyKey
}

function showBootnodeSystemd {
    sudo cat /etc/systemd/system/bootnode.service 
    waitForAnyKey
}

function editBootnodeServiceDetails {
    sudo nano /etc/systemd/system/bootnode.service 
    sudo systemctl daemon-reload
    waitForAnyKey
}

function bootnodeService {
    bootnode_service_options=(1 "status"
            2 "restart"
            3 "start"
            4 "stop"
            5 "logs"
            6 "live logs"
            7 "details"
            8 "systemd details"
            9 "edit systemd details")

    bootnode_service_menu_result="done"

    while [ $bootnode_service_menu_result == "done" ]
    do
        selected_service_option=$(dialog --clear \
                        --backtitle "Bootnode Service" \
                        --title "Bootnode Service" \
                        --ok-label "Next" --cancel-label "Back" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${bootnode_service_options[@]}" \
                        2>&1 >/dev/tty)
        clear
        case $selected_service_option in
                1)
                    statusBootnodeService 
                    ;;
                2)
                    restartBootnodeService
                    ;;
                3)
                    startBootnodeService
                    ;;
                4)
                    stopBootnodeService
                    ;;
                5)
                    serviceBootnodeLogs
                    ;;
                6)
                    serviceBootnodeLiveLogs
                    ;;
                7)
                    serviceBootNodeDetails
                    ;;
                8)
                    showBootnodeSystemd
                    ;;
                9)
                    editBootnodeServiceDetails
                    ;;
                *)
                    bootnode_service_menu_result="back"
                    ;;
        esac

    done
}

#========================================================================
# Adjustments
#========================================================================
function revertBeacon {

    cur_bn=$(curl -d '{
        "jsonrpc":"2.0",
        "method":"hmyv2_blockNumber",
        "params":[],
        "id":1
    }' -H 'Content-Type:application/json' -X POST '0.0.0.0:9500' 2>/dev/null | jq -r ".result")

    curShardBlock=$($HMY utility metadata | jq -r '.result["current-block-number"]')

    if [ $cur_bn -gt 10 ]; then
        def_revert_to_block=$((cur_bn-10))
        def_before_block=$((cur_bn+10))
    else
        def_revert_to_block=0
        def_before_block=$curShardBlock
    fi

    curDir=$PWD

    exec 3>&1;
    HARMONY_BINARY_PATH=$(dialog --nocancel --ok-label "Next" --inputbox "harmony binary file path" 0 0 /usr/sbin/harmony 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    # if harmony binary path is wrong or it doesn't exist
    if [ ! -f $HARMONY_BINARY_PATH ]; then
        echo "binary path is wrong or harmony binary doesn't exist in this path"
        waitForAnyKey
        return
    fi

    exec 3>&1;
    HARMONY_DB_PATH=$(dialog --nocancel --ok-label "Next" --inputbox "harmony database path" 0 0 $HOME 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    # if harmony database path is wrong or it doesn't exist
    # don't add "" to path, because "-d" flag only works if path doesn't have ""
    if [ ! -d $HARMONY_DB_PATH/harmony_db_0 ]; then
        echo "db path is wrong or harmony_db_0 doesn't exist in this path"
        waitForAnyKey
        return
    fi

    exec 3>&1;
    HARMONY_CONFIG_PATH=$(dialog --nocancel --ok-label "Next" --inputbox "harmony config file path" 0 0 $HOME/harmony.conf 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    # if harmony config file path is wrong or it doesn't exist
    if [ ! -f $HARMONY_CONFIG_PATH ]; then
        echo "config path is wrong or harmony.conf doesn't exist in this path"
        waitForAnyKey
        return
    fi

    exec 3>&1;
    REVERT_TO=$(dialog --nocancel --ok-label "Next" --inputbox "revert to what block number? (should be less than current height)" 0 0 "$def_revert_to_block" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    exec 3>&1;
    REVERT_DO_BEFORE=$(dialog --nocancel --ok-label "Revert" --inputbox "revert before block number? (should be bigger than current height)" 0 0 "$def_before_block" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    # if harmony service is running, stop it first, otherwise we can't get access to resources
    sudo systemctl stop harmony.service 

    cd $HARMONY_DB_PATH
    if [ ! -f ./harmony ]; then
        sudo cp $HARMONY_BINARY_PATH ./
    fi

    # a successfull sample on the node stuck on block 21964205
    # for beaconchain:
    # ./harmony --revert.beacon --revert.to 21964200 --revert.do-before 21964209 -c ~/harmony.conf
    # for shrdchain:
    # ./harmony --revert.to 16265110 --revert.do-before 16265120 -c ./harmony.conf
    ./harmony --revert.beacon --revert.to $REVERT_TO --revert.do-before $REVERT_DO_BEFORE -c $HARMONY_CONFIG_PATH

    cd $curDir

    waitForAnyKey

    exec 3>&1;
    start_harmony_service=$(dialog --yesno "start harmony service?" 0 0 2>&1 1>&3);
    run_harmony=$?;
    exec 3>&-;
    if [ $run_harmony -eq 1 ]; then
        sudo systemctl start harmony.service 
    fi

    waitForAnyKey
}

function revertShard {

    cur_bn=$(curl -d '{
        "jsonrpc":"2.0",
        "method":"hmyv2_blockNumber",
        "params":[],
        "id":1
    }' -H 'Content-Type:application/json' -X POST '0.0.0.0:9500' 2>/dev/null | jq -r ".result")

    curShardBlock=$($HMY utility metadata | jq -r '.result["current-block-number"]')

    if [ $cur_bn -gt 10 ]; then
        def_revert_to_block=$((cur_bn-10))
        def_before_block=$((cur_bn+10))
    else
        def_revert_to_block=0
        def_before_block=$curShardBlock
    fi

    curDir=$PWD

    exec 3>&1;
    HARMONY_BINARY_PATH=$(dialog --nocancel --ok-label "Next" --inputbox "harmony binary file path" 0 0 /usr/sbin/harmony 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    # if harmony binary path is wrong or it doesn't exist
    if [ ! -f $HARMONY_BINARY_PATH ]; then
        echo "binary path is wrong or harmony binary doesn't exist in this path"
        waitForAnyKey
        return
    fi

    exec 3>&1;
    HARMONY_DB_PATH=$(dialog --nocancel --ok-label "Next" --inputbox "harmony database path" 0 0 $HOME 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    exec 3>&1;
    TARGET_SHARD=$(dialog --nocancel --ok-label "Next" --inputbox "target shard number" 0 0 "1" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    HARMONY_DB_FULL_NAME="harmony_db_$TARGET_SHARD"

    # if harmony database path is wrong or it doesn't exist
    # don't add "" to path, because "-d" flag only works if path doesn't have ""
    if [ ! -d $HARMONY_DB_PATH/$HARMONY_DB_FULL_NAME ]; then
        echo "db path is wrong or harmony_db_$TARGET_SHARD doesn't exist in this path"
        waitForAnyKey
        return
    fi

    exec 3>&1;
    HARMONY_CONFIG_PATH=$(dialog --nocancel --ok-label "Next" --inputbox "harmony config file path" 0 0 $HOME/harmony.conf 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    # if harmony config file path is wrong or it doesn't exist
    if [ ! -f $HARMONY_CONFIG_PATH ]; then
        echo "config path is wrong or harmony.conf doesn't exist in this path"
        waitForAnyKey
        return
    fi

    exec 3>&1;
    REVERT_TO=$(dialog --nocancel --ok-label "Next" --inputbox "revert to what block number? (should be less than current height)" 0 0 "$def_revert_to_block" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    exec 3>&1;
    REVERT_DO_BEFORE=$(dialog --nocancel --ok-label "Revert" --inputbox "revert before block number? (should be bigger than current height)" 0 0 "$def_before_block" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    # if harmony service is running, stop it first, otherwise we can't get access to resources
    sudo systemctl stop harmony.service 

    cd $HARMONY_DB_PATH
    if [ ! -f ./harmony ]; then
        sudo cp $HARMONY_BINARY_PATH ./
    fi

    # a successfull sample on the node stuck on block 21964205
    # for beaconchain:
    # ./harmony --revert.beacon --revert.to 21964200 --revert.do-before 21964209 -c ~/harmony.conf
    # for shrdchain:
    # ./harmony --revert.to 16265110 --revert.do-before 16265120 -c ./harmony.conf
    ./harmony --revert.to $REVERT_TO --revert.do-before $REVERT_DO_BEFORE -c $HARMONY_CONFIG_PATH

    cd $curDir

    waitForAnyKey

    exec 3>&1;
    start_harmony_service=$(dialog --yesno "start harmony service?" 0 0 2>&1 1>&3);
    run_harmony=$?;
    exec 3>&-;
    if [ $run_harmony -eq 1 ]; then
        sudo systemctl start harmony.service 
    fi

    waitForAnyKey
}

function adjustments {
    adjustment_options=(1 "adjust sync method"
                        2 "revert beacon"
                        3 "revert shard")

    adjustments_menu_result="done"

    while [ $adjustments_menu_result == "done" ]
    do
        selected_adj=$(dialog --clear \
                        --backtitle "$BACKTITLE" \
                        --title "Adjustments" \
                        --ok-label "Next" --cancel-label "Back" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${adjustment_options[@]}" \
                        2>&1 >/dev/tty)
        clear
        case $selected_adj in
                1)
                    adjustSyncMethod
                    ;;
                2)
                    revertBeacon
                    ;;
                3)
                    revertShard
                    ;;
                *)
                    adjustments_menu_result="back"
        esac

    done
}

#========================================================================
# Trouble shooting
#========================================================================
function fixNodeStuckBehindManyBlocks {
    echo "issue: node stuck behind n blocks"
    echo "solution: restart harmony service"
    restartHarmonyService
    echo "done."
    waitForAnyKey
}

function fixNotEnoughSigningPower {
    echo "issue: not enough signing power"
    echo "solution: will be added soon"
    echo "done."
    waitForAnyKey
}

function fixStorageLimit {
    echo "issue: not enough signing power"
    echo "solution: will be added soon"
    echo "done."
    waitForAnyKey
}

function fixP2POutOfMemory {
    echo "issue: node using 100% memory because of mis-adjustment of p2p"
    echo "solution: will be added soon"
    echo "done."
    waitForAnyKey
}

function fixBlockedByHetzner {
    echo "issue: node keep getting blocked by hetzner"
    echo "solution: will be added soon"
    echo "done."
    waitForAnyKey
}

function troubleShooting {

    issues=(1 "node stuck behind n blocks"
            2 "not enough signing power"
            3 "storage limit"
            4 "p2p out of memory"
            5 "node is blocked by provider")

    troubleShooting_menu_result="done"

    while [ $troubleShooting_menu_result == "done" ]
    do
        selected_issue=$(dialog --clear \
                        --backtitle "$BACKTITLE" \
                        --title "Trouble Shooting" \
                        --ok-label "Next" --cancel-label "Back" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${issues[@]}" \
                        2>&1 >/dev/tty)

        clear
        case $selected_issue in
                1)
                    fixNodeStuckBehindManyBlocks 
                    ;;
                2)
                    fixNotEnoughSigningPower
                    ;;
                3)
                    fixStorageLimit
                    ;;
                4)
                    fixP2POutOfMemory
                    ;;
                5)
                    fixBlockedByHetzner
                    ;;
                *)  
                    troubleShooting_menu_result="back"
                    ;;
        esac

    done
}

#========================================================================
# Security 
#========================================================================
function checkSecurity {
    echo "checking securities ..."

    #ufw status
    ufw_status=$(sudo ufw status 2>/dev/null | grep "Status: active")
    if [ ! -z "$ufw_status" ]; then
        echo "[OK] firewall status "
        
        #check ufw open ports 
        num_open_ports=$(sudo ufw status 2>/dev/null | grep -c "ALLOW")
        num_harmony_listening_ports=$(sudo lsof -i -P -n 2>/dev/null | grep -E harmony | grep -c LISTEN)
        if [ "$num_open_ports" == "$num_harmony_listening_ports" ]; then
            echo "[OK] firewall ports should be matched with listening ports"
        else
            echo "[X ] firewall ports should be matched with listening ports [$num_harmony_listening_ports ports are open by harmony service and $num_open_ports ports are allowed by firewall]"
        fi
    else
        echo "[X ] firewall status [ firewall is not active ]"
    fi

    #open ports
    num_other_listening_ports=$(sudo lsof -i -P -n 2>/dev/null | grep -v harmony | grep -c LISTEN)
    if [ "$num_other_listening_ports" -gt 1 ]; then
        echo "[X ] open ports [ rather than harmony ports, other $num_other_listening_ports ports are open ]" 
    else
        echo "[OK] open ports"
    fi

    # check root access should be disable

    # check swap should be disable

    # check password login should be disabled


    waitForAnyKey
}


#========================================================================
# Inspect 
#========================================================================
function compareFloats {
    comp_res=$(awk 'BEGIN { print ($n1 >= $n2) ? "YES" : "NO" }')
    echo $comp_res
}

function inspect {
    echo "inspecting health and security"

    #how many errors in logs
    #how many syncing errors in logs
    exist=$(sudo ls -a ${LOGS_DIR}/zerolog-harmony.log) 
    if [ "$exist" == "${LOGS_DIR}/zerolog-harmony.log" ]; then
    #if [ -f ${LOGS_DIR}/zerolog-harmony.log ]; then       #reason for not using this:  some protected folder can't be checked by -f for file existence
        n_errors=$(sudo cat ${LOGS_DIR}/zerolog-harmony.log 2>/dev/null | grep -c "error")
        if [ $n_errors -eq 0 ]; then
        echo "[OK] errors in log"
        else 
        echo "[X ] errors in log [ there are ${n_errors} errors in log file ]"
        fi

        n_staged_sync_errors=$(sudo cat ${LOGS_DIR}/zerolog-harmony.log 2>/dev/null | grep -E "error" | grep -c "STAGED_SYNC" )
        if [ $n_staged_sync_errors -eq 0 ]; then
        echo "[OK] staged sync errors in log"
        else 
        echo "[X ] staged sync errors in log [ there are ${n_errors} staged sync errors in log file ]"
        fi
    else
        echo "[X ] errors in log [ checking errors in logs failed (log file not found) ]"
        echo "[X ] errors in log [ checking staged sync logs failed (log file not found) ]"
    fi

    #how many errors today
    
    #how many errors in service logs
    service_status=$(sudo systemctl status harmony.service 2>/dev/null | grep -c "active (running)")
    if [ $service_status -gt 0 ]; then
        service_errors=$(sudo journalctl -u harmony.service --no-pager -q -n 1000 | grep -c -E "error|fail")
        if [ $service_errors -eq 0 ]; then
            echo "[OK] harmony service status"
        else 
            echo "[X ] harmony service status [ got ${service_errors} errors in log ]"
        fi
    else
        echo "[X ] harmony service status [ is not running ]"
    fi

    #too many log files
    num_archived_log_files=$(sudo ls "${LOGS_DIR}" -a 2>/dev/null | grep ".log.gz" | wc -l) 
    if [ "$num_archived_log_files" -gt 10 ]; then
        echo "[X ] archived logs count [ too many archived logs ("$num_archived_log_files" log files) ]" 
    else
        echo "[OK] archived logs count"
    fi

    #ufw status
    ufw_status=$(sudo ufw status 2>/dev/null | grep "Status: active")
    if [ ! -z "$ufw_status" ]; then
        echo "[OK] firewall status "
        
        #check ufw open ports 
        num_open_ports=$(sudo ufw status 2>/dev/null | grep -c "ALLOW")
        num_harmony_listening_ports=$(sudo lsof -i -P -n 2>/dev/null | grep -E harmony | grep -c LISTEN)
        if [ "$num_open_ports" == "$num_harmony_listening_ports" ]; then
            echo "[OK] firewall ports should be matched with listening ports"
        else
            echo "[X ] firewall ports should be matched with listening ports [$num_harmony_listening_ports ports are open by harmony service and $num_open_ports ports are allowed by firewall]"
        fi
    else
        echo "[X ] firewall status [ firewall is not active ]"
    fi

    #open ports
    num_other_listening_ports=$(sudo lsof -i -P -n 2>/dev/null | grep -v harmony | grep -c LISTEN)
    if [ "$num_other_listening_ports" -gt 3 ]; then
        echo "[X ] open ports [ rather than harmony ports, other $num_other_listening_ports ports are open ]" 
    else
        echo "[OK] open ports"
    fi

    #check pprof is healthy
    pprof_top_output=$(go tool pprof -text http://localhost:6060/debug/pprof/heap 2>/dev/null | grep -c github.com)
    if [ "$pprof_top_output" -gt 1 ]; then
        echo "[OK] pprof health check" 
    else
        echo "[X ] pprof health check [ report is not available ]"
    fi

    #disk usage
    total_disk_usage=$(df -h --total | grep total | awk '{ print $5}')
    free_space=$(echo 100% $total_disk_usage | awk '{print $1 - $2}')
    fspace_ok=$(echo ${free_space} 20.0 | awk '{if ($1 >= $2) print "YES"; else print "NO"}')
    if [ "$fspace_ok" = "YES" ]; then
        echo "[OK] free storage space"
    else
        echo "[X ] free storage space [ only $free_space % disk space is remained ]"
    fi

    #cpu usage
        #   PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND 
        # 16388 pops      20   0 3518060 1.707g  40928 S  47.5 21.9   2814:20 harmony  
    harmony_service_resource_usages=$(top -i -n 1 2>/dev/null | grep harmony)
    cpu_usage=$(echo  $harmony_service_resource_usages | awk '{ print $10}')
    cpu_ok=$(echo ${cpu_usage} 60.0 | awk '{if ($1 <= $2) print "YES"; else print "NO"}')
    if [ "$cpu_ok" = "YES" ]; then
        echo "[OK] cpu usage"
    else
        echo "[X ] cpu usage [ it is $cpu_usage % which is more than 60% ]"
    fi

    #ram usage
    ram_usage=$(echo  $harmony_service_resource_usages | awk '{ print $11}')
    ram_ok=$(echo ${ram_usage} 60.0 | awk '{if ($1 <= $2) print "YES"; else print "NO"}')
    if [ "$ram_ok" = "YES" ]; then
        echo "[OK] ram usage"
    else
        echo "[X ] ram usage [ it is $ram_usage % which is more than 60% ]"
    fi

    #block is behind
    diff_to_sync=$(curl -d '{
        "jsonrpc":"2.0",
        "method":"hmy_syncing",
        "params":[],
        "id":1
    }' -H 'Content-Type:application/json' -X POST '0.0.0.0:9500' 2>/dev/null | jq -r ".result.difference")
    if [ $diff_to_sync -lt 9 ]; then
        echo "[OK] syncing status"
    else
        echo "[X ] syncing status [ node is not synced yet ($diff_to_sync blocks difference) ]"
    fi

    #service respond time -> send simple query and check time
    
    #number of connection to other nodes
    conns_hex=$(curl -d '{
        "jsonrpc":"2.0",
        "method":"net_peerCount",
        "params":[],
        "id":1
    }' -H 'Content-Type:application/json' -X POST '0.0.0.0:9500' 2>/dev/null | jq -r ".result")
    num_conns=$(printf "%d\n" "${conns_hex}")
    conns_ok=$(echo ${num_conns} 50.0 | awk '{if ($1 >= $2) print "YES"; else print "NO"}')
        if [ "$ram_ok" = "YES" ]; then
        echo "[OK] connected peers"
    else
        echo "[X ] connected peers [ only $num_conns connected peers ]"
    fi

    # date and time should be adjusted 


    waitForAnyKey
}
#========================================================================
# Logs and Profile 
#========================================================================
function showPprofProfile {
    go tool pprof http://localhost:6060/debug/pprof/heap
    waitForAnyKey
}

function showLogs {
    exec 3>&1;
    included=$(dialog --nocancel --ok-label "Next" --inputbox "words should be included (ex: wrd1|wrd2|..." 0 0 "" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    exec 3>&1;
    n_lines=$(dialog --nocancel --ok-label "Next" --inputbox "how many lines? (0=all)" 0 0 "0" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    lines_flag=""
    if [ "$n_lines" != "0" ]; then
        lines_flag="-n $n_lines"
    fi


    if [ -z "$included" ]; then
        tail $lines_flag latest/zero*.log
    else
        tail $lines_flag latest/zero*.log | grep -E "$included"
    fi
    
    waitForAnyKey
}

function getProfileAndLogs {
    pl_options=(1 "logs"
                2 "profile")

    profile_menu_result="done"

    while [ $profile_menu_result == "done" ]
    do
        selected_pl=$(dialog --clear \
                        --backtitle "$BACKTITLE" \
                        --title "Logs and Profile" \
                        --ok-label "Next" --cancel-label "Back" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${pl_options[@]}" \
                        2>&1 >/dev/tty)
        clear
        case $selected_pl in
                1)
                    showLogs
                    ;;
                2)
                    showPprofProfile
                    ;;
                *)  
                    profile_menu_result="back"
        esac

    done
}


#========================================================================
# Others 
#========================================================================
function others_1 {

    waitForAnyKey
}

function others_2 {

    waitForAnyKey
}

function compressDB {
    tar -zcvf db0.tar.gz harmony_db_0/

    for i in {1..4}
    do
        DB_PATH="harmony_db_$i"
        if [ -d "$DB_PATH" ]; then
            echo "compressing $DB_PATH ..."
            tar -zcvf "db$i.tar.gz" "$DB_PATH/"
        fi
    done

    waitForAnyKey
}

function decompressDB {

    for i in {0..4}
    do
        DB_FILE="db$i.tar.gz"
        if [ -f $DB_FILE ]; then
            echo "decompressing $DB_FILE ..."
            tar -zxvf "$DB_FILE"
        fi
    done

    waitForAnyKey
}

function askForNetworkEndpoint {
    network_endpoint_options=(1 "mainnet"
                     2 "testnet"
                     3 "devnet"
                     4 "localnet (0.0.0.0:9500)"
                     5 "custom")

    endpoint_network_id=$(dialog --clear \
                    --backtitle "$BACKTITLE" \
                    --title "Select network" \
                    --ok-label "Next" --nocancel \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${network_endpoint_options[@]}" \
                    2>&1 >/dev/tty)
    clear

    network_endpoint=""
    network_name=""

    case $endpoint_network_id in
            1)
                network_name="mainnet"
                network_endpoint="https://api.s0.t.hmny.io"
                ;;
            2)
                network_name="testnet"
                network_endpoint="https://api.s0.b.hmny.io"
                ;;
            3)
                network_name="devnet"
                network_endpoint="https://api.s0.ps.hmny.io"
                ;;
            4)
                network_name="localnet"
                network_endpoint="0.0.0.0:9500"
                ;;
            5)
                network_name="custom"
                exec 3>&1;
                network_endpoint=$(dialog --nocancel --ok-label "Next" --inputbox "network endpoint?" 0 0 "https://api.harmony.one" 2>&1 1>&3);
                exitcode=$?;
                exec 3>&-;
                ;;
    esac

}

function calculateHF {

    askForNetworkEndpoint

    exec 3>&1;
    n_epochs=$(dialog --nocancel --ok-label "Next" --inputbox "how many epochs?" 0 0 "20" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    exec 3>&1;
    block_secs=$(dialog --nocancel --ok-label "Next" --inputbox "block finality (seconds)?" 0 0 "2" 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;

    clear

    echo "selected network: $network_name -> $network_endpoint"

    echo "fetching block number ..."
    cur_bn=$(curl -d '{
        "jsonrpc":"2.0",
        "method":"hmyv2_blockNumber",
        "params":[],
        "id":1
    }' -H 'Content-Type:application/json' -X POST $network_endpoint 2>/dev/null | jq -r ".result") 

    echo "fetching epoch number ..."
    cur_epoch=$(curl -d '{
        "jsonrpc":"2.0",
        "method":"hmyv2_getEpoch",
        "params":[],
        "id":1
    }' -H 'Content-Type:application/json' -X POST $network_endpoint 2>/dev/null | jq -r ".result") 

    echo "Block Number: $cur_bn"
    echo "Epoch Number: $cur_epoch"

    curr_epoch_last_block=$(curl -d '{
        "jsonrpc":"2.0",
        "method":"hmy_epochLastBlock",
        "params":['$cur_epoch'],
        "id":1
    }' -H 'Content-Type:application/json' -X POST $network_endpoint 2>/dev/null | jq -r ".result") 

    curr_epoch_block_remains=$((curr_epoch_last_block-cur_bn))
    curr_epoch_seconds_to_last_block=$((curr_epoch_block_remains*block_secs))

    next_epoch_last_block=$(curl -d '{
        "jsonrpc":"2.0",
        "method":"hmy_epochLastBlock",
        "params":['$((cur_epoch+1))'],
        "id":1
    }' -H 'Content-Type:application/json' -X POST $network_endpoint 2>/dev/null | jq -r ".result") 

    echo "current epoch last block: $curr_epoch_last_block"
    echo "next epoch last block: $next_epoch_last_block"
    echo "blocks to end of current epoch: $curr_epoch_block_remains"

    epoch_blocks=$((next_epoch_last_block-curr_epoch_last_block))
    epoch_duration_secs=$((epoch_blocks*block_secs))
    echo "Epoch blocks: $epoch_blocks"
    # Get the current time in seconds since epoch
    current_time=$(date +%s)
    echo "current time: $current_time"
    echo "seconds to last block of current epoch: $curr_epoch_seconds_to_last_block"

    printf "%-20s %-20s %-20s %-20s\n" "--------" "--------" "--------" "--------"
    printf "%-20s %-20s %-20s %-20s\n" "epoch" "last block" "start time(UTC)" "end time(UTC)"
    printf "%-20s %-20s %-20s %-20s\n" "--------" "--------" "--------" "--------"

    for ((i = 0; i <= n_epochs; i++))
    do
        epoch=$((cur_epoch+i))
        epoch_bns=$((i*epoch_blocks))
        bns=$((epoch_bns+curr_epoch_block_remains))
        secs=$((bns*block_secs))
        epoch_last_block=$((curr_epoch_last_block+epoch_bns))
        last_block_time=$((current_time+secs))
        last_block_local_time=$(date -d @$last_block_time "+%Y-%m-%d %H:%M:%S")
        last_block_utc_time=$(date -u -d @$last_block_time "+%Y-%m-%d %H:%M:%S")
        first_block_time=$((last_block_time-epoch_duration_secs))
        first_block_local_time=$(date -d @$first_block_time "+%Y-%m-%d %H:%M:%S")
        first_block_utc_time=$(date -u -d @$first_block_time "+%Y-%m-%d %H:%M:%S")
        printf "%-20s %-20s %-20s %-20s\n" "$epoch" "$epoch_last_block" "$first_block_utc_time" "$last_block_utc_time"
    done

    printf "%-20s %-20s %-20s %-20s\n" "--------" "--------" "--------" "--------"

    waitForAnyKey
}

function others {
    others_options=(1 "install golang"
                    2 "restart node"
                    3 "compress database (to: db{0/1/2/3}.tar.gz)"
                    4 "decompress database (from: db{0/1/2/3}.tar.gz)"
                    5 "create a service for harmony binary"
                    6 "calculate hard fork date")

    others_menu_result="done"

    while [ $others_menu_result == "done" ]
    do
        selected_others_opts=$(dialog --clear \
                        --backtitle "$BACKTITLE" \
                        --title "Logs and Profile" \
                        --ok-label "Next" --cancel-label "Back" \
                        --menu "$MENU" \
                        $HEIGHT $WIDTH $CHOICE_HEIGHT \
                        "${others_options[@]}" \
                        2>&1 >/dev/tty)
        clear
        case $selected_others_opts in
                1)
                    installGo
                    waitForAnyKey
                    ;;
                2)
                    reboot
                    ;;
                3) 
                    compressDB
                    ;;
                4)
                    decompressDB
                    ;;
                5)
                    setupSystemd
                    ;;
                6)
                    calculateHF
                    ;;
                *)  
                    others_menu_result="back"
        esac

    done
}

#=========================================================================
# MAIN MENU
#=========================================================================
function showMainMenu {
    options=(1 "install new node"
             2 "monitor and info"
             3 "adjustments"
             4 "inspect"
             5 "trouble shooting"
             6 "logs and profile report (pprof)"
             7 "harmony service"
             8 "bootnode service"
             9 "blockchain"
             10 "security"
             11 "others")

    main_menu_result="done"

    while [ $main_menu_result == "done" ]
    do

        cmd=(dialog --keep-tite \
                --backtitle "$BACKTITLE" \
                --title "Main" \
                --ok-label "Next" \
                --cancel-label "Exit" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}")

        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        
        clear
        case $choice in
            1)
                installNewNode
                ;;
            2)
                currentNode
                ;;
            3)
                adjustments
                ;;
            4)
                inspect 
                ;;
            5)
                troubleShooting
                ;;
            6)
                getProfileAndLogs
                ;;
            7)
                harmonyService
                ;;
            8)
                bootnodeService
                ;;
            9)
                blockchain
                ;;
            10)
                checkSecurity
                ;;
            11)
                others
                ;;
            *)
                main_menu_result="exit"
                ;;
        esac

        case $main_menu_result in
            "exit") 
                exit
                ;;
            #${DIALOG_OK-0}) echo "Your username is harmony";;
            #${DIALOG_CANCEL-1}) echo "Cancel pressed.";;
            #${DIALOG_ESC-255}) echo "Esc pressed.";;
            #${DIALOG_ERROR-255}) echo "Dialog error";;
            #*) echo "Unknown error $retval"
            *)
                ;;
        esac
        #exec /bin/bash "$0" "$@"
    done
    #clear # clear after user pressed Cancel
}

#=========================================================================
# MAIN
#=========================================================================

checkRequirements

showMainMenu
