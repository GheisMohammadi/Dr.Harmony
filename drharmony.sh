#!/bin/bash

# Dr.Harmony version
DrHarmony_Version='0.2'

cat << "EOF"
 ____       _   _                                        
|  _ \ _ __| | | | __ _ _ __ _ __ ___   ___  _ __  _   _ 
| | | | '__| |_| |/ _` | '__| '_ ` _ \ / _ \| '_ \| | | |
| |_| | |  |  _  | (_| | |  | | | | | | (_) | | | | |_| |
|____/|_|  |_| |_|\__,_|_|  |_| |_| |_|\___/|_| |_|\__, | V0.2
                                                   |___/
EOF

LOCAL_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(dig @resolver3.opendns.com myip.opendns.com +short)
HEIGHT=22
WIDTH=40
CHOICE_HEIGHT=10
BACKTITLE="Harmony Node Utilities - Dr.Harmony-V$DrHarmony_Version"
MENU="Choose one of the following options:"
menu_result="notready"

#========================================================================
# init binaries
#========================================================================
HMY=$(which hmy)
if [ -z "$HMY" ]; then
    HMY=./hmy
    if [[ ! -f "$HMY" ]]; then
        HMY=/usr/sbin/hmy
        if [[ ! -f "$HMY" ]]; then
            HMY=~/hmy
            if [[ ! -f "$HMY" ]]; then
                # hmy is not installed
                HMY=""
                echo "hmy not found."
            fi
        fi
    fi
fi


HARMONY=$(which harmony)
if [ -z "$HARMONY" ]; then
    HARMONY=./harmony
    if [[ ! -f "$HARMONY" ]]; then
        HARMONY=/usr/sbin/harmony
        if [[ ! -f "$HARMONY" ]]; then
            HARMONY=~/harmony
            if [[ ! -f "$HARMONY" ]]; then
                # harmony is not installed
                HARMONY=""
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
    result=$(dialog --inputbox test 0 0 2>&1 1>&3);
    exitcode=$?;
    exec 3>&-;
    echo $result $exitcode;
}

function getUserInput2 {
    input=$(dialog --stdout --inputbox "What is your username?" 0 0)
    retval=$?

    case $retval in
    ${DIALOG_OK-0}) echo "Your username is '$input'.";;
    ${DIALOG_CANCEL-1}) echo "Cancel pressed.";;
    ${DIALOG_ESC-255}) echo "Esc pressed.";;
    ${DIALOG_ERROR-255}) echo "Dialog error";;
    *) echo "Unknown error $retval"
    esac
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

    if [ -f "$HMY" ]; then
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
    sudo apt install -y git libgmp-dev  libssl-dev  make gcc g++
}

function installHarmonyDependenciesUsingYum {
    sudo yum install -y git glibc-static gmp-devel gmp-static openssl-libs openssl-static gcc-c++
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
        go_version="1.19.1"
        go_file_name="go$go_version.linux-amd64.tar.gz"
        go_url="https://storage.googleapis.com/golang/$go_file_name"
        wget $go_url
        sudo tar -C /usr/local -xzvf $go_file_name
        rm $go_file_name
        echo "export PATH=\"/usr/local/go/bin:$PATH\"" >> ~/.bashrc
        source ~/.bashrc
    fi     

    CHECK_GO_INSTALL=$(go version|grep "go version")
    if [ "$CHECK_GO_INSTALL" = "" ]; then
        alias go=/usr/local/go/bin/go   
    fi

    go version
}

function downloadAndBuildSourceCode {
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
function installNewNodeFromBinaryFile {
    echo "install new harmony node from binary file ..."
    
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
}

function installNewNodeFromSourceCode {
    # install golang
    # install deps
    # install node
    echo "install new harmony node from source code ..."
    buildHarmonyBinary
}

function installNewNode {
    echo "setup new harmony validator "

    install_options=(1 "build binary from source code"
                     2 "download binary"
                     3 "install rclone")

    selected_install_option=$(dialog --clear \
                    --backtitle "$BACKTITLE" \
                    --title "Run New Validator" \
                    --ok-label "Install" --cancel-label "Back" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${install_options[@]}" \
                    2>&1 >/dev/tty)
    clear
    new_node_menu_res="done"
    
    # ask user for network type
    askForNetwork
    
    case $selected_install_option in
            1)
                installNewNodeFromSourceCode 
                ;;
            2)
                installNewNodeFromBinaryFile
                ;;
            3)
                install_rclone
                ;;
            *)
                new_node_menu_res="back"
                ;;
    esac

    if [ $new_node_menu_res == "done" ]; then
        waitForAnyKey
    fi
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

    curl --location --request POST 'https://api.s0.t.hmny.io/' \
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
function hmy_getBalance {
    ADD="0x320b3FedBaF5A15Ad50F5c2ff4A659cf4dB64B02"
    URL="http://localhost:9501"
    curl $URL -H "Content-Type: application/json" -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"hmy_getBalance\",\"params\":[\"${ADD}\", \"latest\"],\"id\":1}"
    waitForAnyKey
}

function eth_getBalance {
    curl --location --request POST 'https://api.s0.t.hmny.io' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "eth_getBalance",
        "params": ["0x320b3FedBaF5A15Ad50F5c2ff4A659cf4dB64B02", "latest"]
    }'
    waitForAnyKey
}

function blockchain {

    blockchain_options=(1 "account transactions history"
                        2 "check account balance"
                        3 "eth get balance")

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
                hmy_getBalance
                ;;
            3)
                eth_getBalance
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
    stagedsync=$(cat $configFile | grep "StagedSync =\|StagedSync=")
    if [[ -z $stagedsync ]]
    then
    ./harmony config update $configFile
    fi
    
    newstagedsync=$(cat $configFile | grep "StagedSync =\|StagedSync=")
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
    stagedsync=$(cat $configFile | grep "StagedSync =\|StagedSync=")
    if [[ -z $stagedsync ]]
    then
    ./harmony config update $configFile
    fi

    newstagedsync=$(cat $configFile | grep "StagedSync =\|StagedSync=")
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
    echo "hmy cli     :" ${HMY}
    $HMY version
    echo ''
    echo "harmony cli :" ${HARMONY}
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

function showHeaders {
    while true; do $HMY blockchain latest-headers ; sleep 1; done
    waitForAnyKey
}

function showFullHardwareInfo {
    sudo apt-get install lshw
    sudo lshw -short 
    waitForAnyKey
}

function nodeInfo {

    node_info_options=(1 "all meta data"
                  2 "node key"
                  3 "network info"
                  4 "chain info"
                  5 "block number"
                  6 "headers"
                  7 "disk info"
                  8 "OS info"
                  9 "binaries info"
                  10 "EC2 info"
                  11 "Full hardware info")

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
                    showDiskInfo
                    ;;
                8)
                    showUbuntuRelease
                    ;;
                9)
                    showBinariesInfo
                    ;;
                10)
                    showEc2Info
                    ;;
                11)
                    showFullHardwareInfo
                    ;;
                *)
                    info_menu_result="back"
                    ;;
        esac

    done
}

function nodeWatch {
 
    node_watch_options=(1 "memory usage"
                        2 "cpu usage"
                        3 "block number")

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
                    watch -n 5 free -m 
                    ;;
                2)
                    sudo systemctl status harmony
                    ;;
                3)
                    while true; do $HMY utility metadata | grep current-block-number; sleep 2; clear; done
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
    sudo journalctl -u harmony -n 1000 --no-pager --all
    waitForAnyKey
}

function harmonyService {
    service_options=(1 "status"
            2 "restart"
            3 "start"
            4 "stop"
            5 "logs")

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
                *)
                    service_menu_result="back"
                    ;;
        esac

    done
}

#========================================================================
# Adjustments
#========================================================================
function revertBeacon {
  REVERT_TO=26096624
  REVERT_DO_BEFORE=26096625
  sudo service harmony stop 
  ./harmony --revert.beacon --revert.to $REVERT_TO --revert.do-before $REVERT_DO_BEFORE -c harmony.conf
  sudo service harmony start
}

function adjustments {
    adjustment_options=(1 "adjust sync method"
                        2 "revert beacon")

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
                    echo "this feature is not completed yet, try again later"
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
# Inspect 
#========================================================================

function inspect {
    echo "inspecting health and security"
    echo "the inspect menu will be added later"
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
    tail -f latest/zero*.log
    waitForAnyKey
}

function getProfileAndLogs {
    pl_options=(1 "logs"
                2 "prfofile")

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
             8 "blockchain"
             9 "security")

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
                blockchain
                ;;
            9)
                echo "security options will be added later"
                waitForAnyKey
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
