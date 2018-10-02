#!/bin/bash
#set -x ;set -o functrace #//this for function debug
#####################
# Designed by Bala  #
#####################

{
#--------------------------
#variables
#--------------------------
declare -x -r gc_version="testversion  \t  ReleaseDate: 21-Sep-2018"
declare -x -r gc_tmpdir="/tmp/brexalogic/`whoami`/$2"
declare -x -r gc_tmptmp="${gc_tmpdir}/tmptmp"
declare -x -r gc_tmpfile="${gc_tmpdir}/tempfile"
declare -x -r gc_tmpfileNB=${gc_tmpfile}NB
declare -x -r gc_hostname=`hostname | awk -F \. '{print $1}'`
declare -x -r gc_message=${gc_tmpdir}/message
declare -x -r gc_tty=$(tty)
declare -x -r gc_argument1=$1

declare -x gv_argument2=$2
declare -x gv_currentpwd=$PWD
declare -x gv_componentlistfile=${gc_tmpdir}/componentlist
declare -x gv_ExitCode=0
declare -x gv_patchnumber=""
declare -x gv_sysenv=""
declare -x gv_patchlocation=""
declare -x gv_customungrep=" grep -v -e closed -e password: -e Password: -e X11  -e brcustpass"
declare -x gv_ilomsuffix="i"
declare -x gv_datetime=$(date +%F.%H.%M.%S)
declare -x gv_logfile="${gc_tmpdir}/$1_$2_$gv_datetime.log"


[[ -d /tmp/brexalogic ]] && sudo chmod -R 775 /tmp/brexalogic
mkdir -p $gc_tmpdir
echo "0" >$gc_tmpdir/ECODEFILE
[[ -d /tmp/brexalogic ]] && sudo chmod -R 775 /tmp/brexalogic
trap "TrapCtrlC" 2  
alias yes="echo :\)"
}

SetEnv(){                   #----- setting env for the script
umask 002

[[ -d $gc_tmptmp ]]&& rm -rf $gc_tmptmp
mkdir -p $gc_tmptmp
touch $gv_componentlistfile
touch $gc_message
echo $gv_datetime >>${gc_message}_OLD 2> /dev/null
cat  $gc_message >> ${gc_message}_OLD 2> /dev/null
echo >$gc_message

}

#-------------------------------------------------------------------
#PROCEDURE    : Ungrep Update
#DESCRIPTION  : this to updage common ungrep after password entry
#-------------------------------------------------------------------
UngrepUpdate(){             #----- default ungrep items
[[ $gv_sysenv == Virtual ]] && gv_customungrep="grep  -v  -e closed -e password -e Password -e X11  -e $CNP -e $CNIP -e $ZFSHEADP -e $ZFSILOMP -e $GWP -e $SSP  -e $OVMMECP -e BREAK-IN -e $WLP -e  bash: -e brcustpass "
[[ $gv_sysenv == Linux ]] && gv_customungrep="grep  -v  -e closed -e password -e Password -e X11  -e $CNP -e $CNIP -e $ZFSHEADP -e $ZFSILOMP -e $GWP -e $SSP  -e BREAK-IN -e  bash:  -e brcustpass"
}
#-------------------------------------------------------------------
#PROCEDURE    : Script Syntax
#DESCRIPTION  : this to display the script syntax
#-------------------------------------------------------------------
ScriptSyntax(){             #----- script syntax
EchoAndLog "\n Syntax wrong! \n Syntax : brexalogic.sh   <argument>   <node1 Name/IP> \n \n  Argument should  be : \n \n 
\t'passwd-check' \t \t #--> to check only the password entered correct or not .
\t'stage-psu' \t\t #--> to stage the patch only . it run  psuSetup.sh .
\t'send-logtoportal' \t #--> Just to send the log/files  to Oracle portal to the SR-Number. \n
\t'create-passkey' \t #--> To create Enctyped passwor key file . file  validity 10 days.\n
\t'pre-checkrack' \t #--> to do full precheck of the rack including expatch -a prePatchCheck.
\t'patch-components' \t #--> to patch component. it will list you the component to select it. \n
\t'patch-ecs' \t  \t #--> to patch only Exalogic Control Service.
\t'patch-ib' \t\t #--> to patch only IB switch.
\t'patch-Spine' \t\t #--> to patch only spine switch.
\t'patch-zfs' \t\t #--> to patch only ZFS-Storage-Head & its ILOM.
\t'patch-node' \t\t #--> to patch compute node. it will list the node. to chosse it. 
\t'patch-vtemplate' \t #--> to patch EC vServers Template "
#(\t'patch-nonrolling' \t #--> to do all component in Non-rolling method )"
EchoAndLog
Exit 10
}
#-------------------------------------------------------------------
#PROCEDURE    :  Using Command
#DESCRIPTION  : Command list that used while pre check
#-------------------------------------------------------------------
UsingCommand(){             #---- command with going to usin in this script
####command and file path
gc_CNODEFILEPATH="/opt/exalogic.tools/tools/cnodes_brexalogic"
gc_DCLI="/opt/exalogic.tools/tools/dcli -s '-q' "
[[ -z $1 ]] && gc_DCLIWCNODEFILE="$gc_DCLI -g $gc_CNODEFILEPATH "
gc_EXAPATCH="/exalogic-lctools/bin/exapatch  "
gc_EXABR="/exalogic-lctools/bin/exabr  "


#computenode command
c_CNCHECK1="$gc_DCLIWCNODEFILE '/opt/exalogic.tools/tools/CheckSWProfile'\;echo "
c_CNCHECK2="$gc_DCLIWCNODEFILE '/opt/exalogic.tools/tools/CheckHWnFWProfile | tail -1'\;echo "
c_CNCHECK3="$gc_DCLIWCNODEFILE 'df -Phm /'\; echo  "
c_CNCHECK4="$gc_DCLIWCNODEFILE 'df -Phm /boot'\;echo"
c_CNCHECK5="$gc_DCLIWCNODEFILE 'mount'\;echo "
c_CNCHECK6="$gc_DCLIWCNODEFILE 'cat /etc/fstab'\; echo "
c_CNCHECK7="/exalogic-lctools/bin/exapatch -a listVMs \; echo " 
c_CNCHECK8="$gc_DCLIWCNODEFILE  'xm list'\; echo "
c_CNCHECK9="$gc_DCLIWCNODEFILE 'uptime'\; echo "
c_CNCHECK10="\"find /OVS -wholename '*VirtualMachines/*/vm.cfg' -exec grep -H 'simple.*Exalogic' {} \\\; \" \; echo "


#ZFS-Storage-Head command
c_ZFSCHECK1="configuration cluster show"
c_ZFSCHECK2="maintenance problems show"
c_ZFSCHECK3="maintenance system updates show"
c_ZFSCHECK4="configuration services nfs show"
c_ZFSCHECK5="configuration services http show"
c_ZFSCHECK6="analytics settings show"
c_ZFSCHECK7="maintenance hardware select chassis-000 select memory show"
c_ZFSCHECK8="maintenance hardware select chassis-000 select cpu show"
c_ZFSCHECK9="maintenance hardware select chassis-000 select fan show"
c_ZFSCHECK10="maintenance hardware select chassis-000 select disk show"
c_ZFSCHECK11="configuration version show"
c_ZFSCHECK12="confirm shell fwflash -l -c IB |egrep 'Firmware revision|Product'"
c_ZFSCHECK13="$gc_DCLIWCNODEFILE 'service o2cb status'"

#Switch commands
c_SWCHECK1="ibswitches"
c_SWCHECK2="$gc_DCLIWCNODEFILE ibstat | grep -i state" 
c_SWCHECK3="$gc_DCLIWCNODEFILE  \"cat /etc/sysconfig/network-scripts/ifcfg-ib*|grep -i 'CONNECTED_MODE='\"  " 
c_SWCHECK4="$gc_DCLIWCNODEFILE 'chkconfig --list openibd'"

c_SWCHECK5="version|grep -i SUN" 
c_SWCHECK6="getmaster"
c_SWCHECK7="setsmpriority list"
c_SWCHECK8="smnodes list"
c_SWCHECK9="service partconfigd status" 
c_SWCHECK10="service opensmd status" 
c_SWCHECK11="service bxm status"
c_SWCHECK12="free -m"
c_SWCHECK13="showvlan"
c_SWCHECK14="df -Phm /var"
c_SWCHECK15="ls -ltrh /var/log/lumain.log"
c_SWCHECK16="hwclock"
c_SWCHECK17="showlag"
c_SWCHECK18="showunhealthy"
c_SWCHECK19="env_test"
c_SWCHECK20="listlinkup"
c_SWCHECK21="showgwports"
c_SWCHECK22="showvnics"

#OVMMECP -- pre and post check
c_OVMMCHECK2="df -Phm /" 
c_OVMMCHECK3="grep -e ecu-pc-IPoIB-admin-primary -e  ecu-pc-IPoIB-admin-secondary /etc/hosts"
c_OVMMCHECK4="ssh -q  -o PasswordAuthentication=no  root@ecu-pc-IPoIB-admin-primary uptime "
c_OVMMCHECK5="ssh -q  -o PasswordAuthentication=no  root@ecu-pc-IPoIB-admin-secondary uptime "
c_OVMMCHECK6="service ovmm status" 
c_OVMMCHECK6start="service ovmm start" 
c_OVMMCHECK7="/opt/sun/xvmoc/bin/ecadm status"
c_OVMMCHECK7start="/opt/sun/xvmoc/bin/ecadm start"
c_OVMMCHECK8="/opt/sun/xvmoc/bin/satadm status" 
c_OVMMCHECK8start="/opt/sun/xvmoc/bin/satadm start" 
c_OVMMCHECK9="/opt/sun/xvmoc/bin/proxyadm status " 
c_OVMMCHECK9start="/opt/sun/xvmoc/bin/proxyadm start " 
#COMMAND FOR ECS patching
c_OVMMCHECK11="$gc_EXAPATCH -a ecvserversshutdown"
c_OVMMCHECK12="$gc_EXABR backup control-stack"
c_OVMMCHECK13="$gc_EXABR list control-stack"
c_OVMMCHECK14="$gc_EXAPATCH -a ecvserversstartup"
c_OVMMCHECK15="$gc_EXAPATCH -a runExtension -p Exalogic_Control/emoc_patch_extension.py"

}
#-------------------------------------------------------------------
#PROCEDURE    : EchoAndLog
#DESCRIPTION  :  this to echo and log the information on the log file  based on arguemnt
#-------------------------------------------------------------------
EchoAndLog(){               #--- just for echo based on argument
local v_date_log=$(date +%F.%H.%M.%S)
local v_firstarg=$1
local v_fullmessage=$*
shift 1
local v_onlymessage=$*
local v_msgtype
local v_color
c_LIGHTBLUE='\033[1;36m'
c_PINK='\033[1;35m'
c_GREEN='\033[1;32m'
c_RED='\033[1;31m'
c_YELLOW='\033[1;33m'
c_WHITE='\033[1;0m'
c_BLINK='\033[5;34m'
c_UNDERLINE='\033[4;36m'

case $v_firstarg in 
    LINE) echo -e  "\n ----------------------------------------------------------------------------------  "
	    ;;
    DLINE) echo -e  "\n =================================================================================  "
	    ;;
    G) echo -e $v_date_log "[GATHERING] $v_onlymessage " 
	   ;;
    C) echo -e $v_date_log "[COLLECTING] $v_onlymessage " >>$gv_logfile
       echo -e $v_date_log "$c_PINK [COLLECTING]$c_WHITE $v_onlymessage " >$gc_tty
	   ;;
    I) echo -e $v_date_log  "[INFORMATION] $v_onlymessage " >> $gv_logfile
       echo -e $v_date_log  "$c_LIGHTBLUE [INFORMATION]$c_WHITE $v_onlymessage   " > $gc_tty
	   ;;
    P) echo -e "[PASS] $v_onlymessage " | tee -a $gc_message
       ;;
    F) echo -e "[FAIL] $v_onlymessage " | tee -a $gc_message 
	   ;;
    A) echo -e $v_date_log  "[ATTENTION  ] $v_onlymessage " >>  $gc_message
       echo -e $v_date_log  "[ATTENTION  ] $v_onlymessage " >> $gv_logfile
       echo -e $v_date_log  "$c_YELLOW [ATTENTION  ]$c_WHITE $v_onlymessage  " > $gc_tty
	   ;;
    E) echo -e $v_date_log  "[ERROR      ] $v_onlymessage " >>  $gc_message
       echo -e $v_date_log  "[ERROR      ] $v_onlymessage " >>  $gv_logfile
       echo -e $v_date_log  "$c_RED [ERROR      ]$c_WHITE $v_onlymessage  " > $gc_tty
	   ;;
    CK) echo -e $v_date_log "[CHECKING] $v_onlymessage " 
	   ;;
    EC) echo -e $v_date_log "[EXECUTING] COMMAND: $v_onlymessage \n " >>$gv_logfile
        echo -e $v_date_log "$c_GREEN [EXECUTING]$c_WHITE COMMAND: $v_onlymessage \n " >$gc_tty    
		;;
    UI) echo -e "[USER INPUT] $v_onlymessage "
	    ;;
    *) echo -e "$v_fullmessage" 
	    ;;
esac

}
#-------------------------------------------------------------------
#PROCEDURE    : RemoveTmpFiles
#DESCRIPTION  : remove temporary created file by this script
#-------------------------------------------------------------------
RemoveTmpFiles(){
[[ $gc_tmpdir =~ brexalogic ]] && EchoAndLog I "Removing temporary created files" ||  return
[[ -d /tmp/brexalogic ]] && sudo chmod -R 775 /tmp/brexalogic
for i in $( ls -d  ${gc_tmpdir}/*  | grep -v -e - -e message -e ENCRYPTEDPASSFILE  )
do
    [[ -f $i ]] &&  /bin/rm  $i
done 
[[ -d $gc_tmptmp ]] && /bin/rm -rf $gc_tmptmp
}
#-------------------------------------------------------------------
#PROCEDURE    : Exit
#DESCRIPTION  : Exit command call inbetween script.  update ecodef file and remove \r on the log file
#-------------------------------------------------------------------
Exit(){                     #--- to exit the script
echo $1 >$gc_tmpdir/ECODEFILE
[[ $1 -eq 66 ]] && EchoAndLog A "Something not correct. Inform to Script developer to fix it"
sed -i -e 's/\r//g' $gv_logfile
RemoveTmpFiles
[[ -z $1 ]] && ECODE=6 || ECODE=$1
exit $ECODE
}
#-------------------------------------------------------------------
#PROCEDURE    : TrapCtrlC
#DESCRIPTION  : Trap the control  + c  and will update that to log file
#-------------------------------------------------------------------
TrapCtrlC (){               #--- trap for control + c

   EchoAndLog ;echo -e  "$BLINK [INFORMATION]$WHITE Control+C pressed. So stopping the script"
   stty echo 
   sed -i -e 's/\r//g' $gv_logfile
   [[ -e $gv_logfile ]] && echo -e "$RED LogFile : $YELLOW $gv_logfile $WHITE \n "
   EchoAndLog 99 >$gc_tmpdir/ECODEFILE
   Exit 99
}
#-------------------------------------------------------------------
#PROCEDURE    : ValueChecker
#DESCRIPTION  : check input value is greater or lesser. Arguemnet - "Component" "ip" "whatcheck" "requriedsize" "currentsize"
#-------------------------------------------------------------------
ValueChecker(){             #---- arguemnt - component IP whatcheck requriedsize currentsize
local components=$1;local IP=$2;local WHAT=$3;local requriedsize=$4;local currentsize=$5
local v_matter="${components}: $IP $WHAT requriedsize is $requriedsize but there is only $currentsize "
rsize=`echo $requriedsize | tr -d "[:alpha:]|[:space:]"|awk -F "." '{print $1}'`
csize=`echo $currentsize  | tr -d "[:alpha:]|[:space:]"|awk -F "." '{print $1}'`

if [[ $csize -lt $rsize ]]; then 
 [[ $components =~ "Switch" ]] && EchoAndLog E "$v_matter" || EchoAndLog A "$v_matter"
fi
}

#-------------------------------------------------------------------
#PROCEDURE    : DoubleEnter
#DESCRIPTION  : this used for doubleconfirmation before proceeding to next step. if there is value in message it will show messages file
#-------------------------------------------------------------------
DoubleEnter(){              #---- argument which component to filter. if argument is there. it will read message file and display
grep -i -e ERROR -e ATTENTION  $gc_message  >/dev/null
[[ $? -ne 0 ]] && return 0

    if [[ -n  $1 ]]
    then
        EchoAndLog  "\n\n\n **************************************************************************\n Fix the following Error before proceeding \n "
        grep -i -e ERROR -e ATTENTION  $gc_message 
    fi
    date +%F.%H.%M.%S >>${gc_tmpdir}/allmessagesofar
    strings $gc_message >>${gc_tmpdir}/allmessagesofar
    EchoAndLog > $gc_message
    EchoAndLog  " \n Please fix above issue then Hit Enter and press yes  to continue next step: \c";read;
    YesOrNo "Hope you fixed above issue. press 'Yes' to continue or  'No' for stop the script: "
    [[ $? -eq   0 ]] && return 0 ||  Exit 10
}
#-------------------------------------------------------------------
#PROCEDURE    : EmptyNB
#DESCRIPTION  : used to Empty the non-binary file
#-------------------------------------------------------------------
EmptyNB(){                  #----- to empty the binary file
echo "">$gc_tmpfileNB
}
#-------------------------------------------------------------------
#PROCEDURE    :  YesOrNo
#DESCRIPTION  :  prompt yes or not  question and provide exit code based on input
#-------------------------------------------------------------------
YesOrNo(){                  #---- prompt yes or no question
    local v_outcode
    EchoAndLog "\n \n $*  (yes/no) : \c"
    read answer 
    while [[ "$answer" != "yes" ]] && [[ "$answer" != "no"  ]] 
    do
        EchoAndLog  "  Enter  (yes/no)?  : \c "
    read answer
    done
    if [ $answer == "yes" ]
    then
        EchoAndLog UI  "You have typed  'yes'. \n "
        echo 0  >${gc_tmptmp}/closecode
        v_outcode=0
    else
        EchoAndLog UI "You have typed 'no'. \n  "
        echo 1  >${gc_tmptmp}/closecode
        v_outcode=1     
        
    fi
    return $v_outcode
}
#-------------------------------------------------------------------
#PROCEDURE    : SleepCount
#DESCRIPTION  : to display how much second completed on sleep
#-------------------------------------------------------------------
SleepCount(){               #--- show dots while sleep command in progress
local v
for (( i =  0 ; i <= $1  ; i = i+2 ))
do
let "v=$1-$i"
EchoAndLog "-$v\c"
sleep 2
done
EchoAndLog 
}
#-------------------------------------------------------------------
#PROCEDURE    : ExpectTool
#DESCRIPTION  : this to check whether component connectivity   path and run the main expecttoolNb based on that 
#-------------------------------------------------------------------
ExpectTool(){               #---- expecttool -- for convert binary to nonbinary
local v_outcode
local v_output
if [[ $(grep "$1\ " $gv_componentlistfile ) =~ vianode ]] ; then
    ExapatchExpect $*
    return $?
else
    EchoAndLog >$gc_tmpfile
    EchoAndLog >$gc_tmpfileNB
    v_output=$(ExpectToolNB $*)
    v_outcode=$?
    echo "$v_output" | $gv_customungrep   | sed "s/\[4m//g;s/\[m//g;s/\[24m//g;s/\r//g"
        if [[ $* =~ exapatch ]] && [[ $* =~ -a  ]];then 
            [[ $v_outcode -eq 9 ]] && Exit 9
        fi
    gv_ExitCode=$v_outcode
    return $v_outcode
fi

}
#-------------------------------------------------------------------
#PROCEDURE    : ExpectToolNB
#DESCRIPTION  :  this is main expect script which send the password based on query. 
#-------------------------------------------------------------------
ExpectToolNB(){             #---- expecttool  -- IP/HN  password  command
[[ $TIMEOUT ]] && local ETIMEOUT=$TIMEOUT || local ETIMEOUT=900
trap "TrapCtrlC" 2  
username="root"
hostname="$1"
password="$2"
shift 2
command="$@"
SSH="ssh  -t -o StrictHostKeyChecking=no -o CheckHostIP=no -o NumberOfPasswordPrompts=1 "
[[ $command == 'set' ]] && SSH="ssh -o StrictHostKeyChecking=no -o CheckHostIP=no -o NumberOfPasswordPrompts=1 "
[[ $command =~ 'dcli' ]] && SSH="ssh -q -o StrictHostKeyChecking=no -o CheckHostIP=no -o NumberOfPasswordPrompts=1 "
MCMD="$SSH  $username@$hostname $command "
echo $command |grep -v expect | grep   -e "exapatch" -e "exabr" >/dev/null
    if [[ $? -eq "0" ]] 
    then
        if [[ $gc_argument1 != "passwd-check" ]];then
            [[ $EXABR_REPO ]] && PP="cd /exalogic-lcdata/patches/${gv_sysenv}/${gv_patchnumber}/Infrastructure\;export EXABR_REPO=$EXABR_REPO\;"
            [[ -z $EXABR_REPO ]] && PP="cd /exalogic-lcdata/patches/${gv_sysenv}/${gv_patchnumber}/Infrastructure\;"
        fi
        ETIMEOUT=5400
        MCMD="$SSH   $username@$hostname ${PP}$command" 
    fi


echo $command | grep -i scp >/dev/null
if [[ $? -eq "0" ]] && [[ $RUNENV == "jumpgate" ]]
then
    MCMD=$command
fi
[[ $command =~ hostname ]] && ETIMEOUT=30
[[ $command =~ hwclock ]] && ETIMEOUT=60
/usr/bin/expect << BREOFFOREXPECT

    log_user 0  
    set timeout $ETIMEOUT
    log_user 1
    spawn -noecho $MCMD
    
    expect {
        -timeout $ETIMEOUT

        "Permission denied" {send_user "\n\n Wrong  password Entered for the $hostname !\n\n";exit 8}
        "password invalid" {send_user "\n\n Wrong  password Entered for the $hostname !\n\n";exit 8}
        "Too many authentication failure" {send_user "\n\n Wrong  password Entered for the $hostname !\n\n";exit 8}
        "Connection timed out" {send_user "\n\n Not able reach  $hostname ! \n \n  Chance:  wrong ip/hostname or  rackconfiguration.py IP not able to reach from jumpgate. modify the rackconfiguration IP  as per /etc/hosts on jumpgate\n\n";exit 9}
        "Inappropriate ioctl for device" {send_user "\n\n rackconfiguration.py not having \'Defaultpassword\\' entry for all components ! Or password Less ssh between CN01 and Storage is not configured\n\n";exit 8}
        "No route to host" {send_user "\n\n Not able to reach $hostname !\n\n";exit 9}
        "Could not resolve hostname*Name or service not known" {send_user "\n\n Not able to reach $hostname !\n\n";exit 9}
        "brcustpass" {send "$brcustpass\r";exp_continue}
        "connecting*yes/no" {send  "yes\r";exp_continue}
        "root@*cn*ilo*password" {send "$CNIP\r";exp_continue}
        "root@*sn*ilo*password" {send "$ZFSILOMP\r";exp_continue}
        "root@${gv_argument2}'s password" {send "$CNP\r";exp_continue}
        "root@*cn*${gv_ilomsuffix}'s password" {send "$CNIP\r";exp_continue}
        "root@*gw*assword" {send "$GWP\r";exp_continue}
        "root@*sn*assword" {send "$ZFSHEADP\r";exp_continue}
        "root@*assword" {send "$password\r";exp_continue}
        "Password:" {send "$password\r";exp_continue}
        timeout {send_user "\n\n\n connection to $hostname timed out\n";exit 9}
    
        "Enter Compute-Node *root password" {send "$CNP\r";exp_continue}
        "Enter ILOM-ComputeNode *root password" {send "$CNIP\r";exp_continue}
        "Enter ILOM-ZFS *root password" {send "$ZFSILOMP\r";exp_continue}
        "Enter ZFS-Storage-Head *root password" {send "$ZFSHEADP\r";exp_continue}
        "Enter NM2-GW-IB-Switch *root password" {send "$GWP\r";exp_continue}
        "Enter NM2-36p-IB-Switch *root password" {send "$SSP\r";exp_continue}
        "Enter common Exalogic Control vServer password" {send "$OVMMECP\r";exp_continue}
        "Enter vServer-EC-EMOC-PC *root password" {send "$OVMMPCP\r";exp_continue}
        "Enter EMOC-PC-service *root password" {send "$OVMMPCP\r";exp_continue}
        "Enter common rack password" {send "$CNP\r";exp_continue}
        "Enter the weblogic password" {send "$WLP\r";exp_continue}
        "*assword:" {send "$password\r";exp_continue}
        eof {send_user " \n";exit}
    }   
BREOFFOREXPECT
    gv_ExitCode=$?
    
    if [[ $command =~ exapatch ]] && [[ ! $command =~ $EXAPATCHVERSION ]] ;then 
         [[ $gv_ExitCode -eq 9 ]] && EchoAndLog A " TIMEOUT while making the running $command  on $1"
    fi
    return $gv_ExitCode
}
#-------------------------------------------------------------------
#PROCEDURE    : ExapatchExpect
#DESCRIPTION  : this to run the command using the exapatch expect script
#-------------------------------------------------------------------
ExapatchExpect(){           #---- to run the command  through  exapatch
local v_ip=$1
local v_passwd=$2
local brcustpass=$v_passwd
shift 2
local v_command=$@
ExpectTool $gv_argument2 $CNP "sh  /exalogic-lctools/lib/exapatch/${EXAPATCHVERSION}/expect/brcustexpect.sh  $v_ip  \' $v_command \'" 
return $?
}

#-------------------------------------------------------------------
#PROCEDURE    : ValidateEncryptedPassKey
#DESCRIPTION  : this is to check and validate the pass key and will assign  the value to variables
#-------------------------------------------------------------------
ValidateEncryptedPassKey(){ #--- to check and validate the key and assing the variables
local v_LASTCREATEDENCFILE=$(ls -rt /tmp/brexalogic/*/$gv_argument2/ENCRYPTEDPASSFILE* 2>/dev/null  | tail -1 |  grep ENCRYPTEDPASSFILE )
local v_FILECREATEDDATE=$(echo $v_LASTCREATEDENCFILE | awk -F "_" '{print $2}')
local v_TODAYDATE=$(date)
local v_CDATE=$(date -d "$v_TODAYDATE - 10 days"  +%Y%m%d)

if [[ -z $v_FILECREATEDDATE ]] || [[ $v_FILECREATEDDATE -lt $v_CDATE ]]
then
    EchoAndLog I " No valid pass key file found to get the information. "
    v_ENCPASSKEYFILE=no
else
    EchoAndLog $v_LASTCREATEDENCFILE
    if [[ $retry -ne  1 ]] ; then 
        if [[ -z $DPASS ]] ;then  YesOrNo "Valid pass key file found. would like to use it ?"
        [[ $? -ne 0 ]] && return ; fi
    fi
    if [[ -z $DPASS ]] ; then  ReadPassword " Enter the pass key to please: " ;local  DPASS=$v_enteredpassword;EchoAndLog ; fi
    v_output=$(openssl enc -d -aes-256-cbc -a -salt -pass pass:$DPASS  <$v_LASTCREATEDENCFILE  2>&1 )
    if [[ $? -eq 0 ]]
    then 
        EchoAndLog I " Passkey is valid"
        for i in $(echo "$v_output" | grep =  )
        do
            local v_item=$(echo $i | awk -F = '{print $1}')
            local v_pass=$(echo $i | awk -F ${v_item}= '{print $2}' | sed 's/\$/\\\\x24/g;s/\=/\\\\x3D/g;s/\#/\\\\x23/g;s/\@/\\\\x40/g')
            eval ${v_item}=${v_pass}
        done    
        EchoAndLog  "\n \n Customer Name : $cuname \n SR-Number : $srnumber \n Environment : $gv_sysenv \n PATCH-NUMBER : $gv_patchnumber  \n">${gc_tmpdir}/passwdcheck.out
        cat ${gc_tmpdir}/passwdcheck.out  
        #YesOrNo " Was the above Information correct ?  "
        #[[ $? -eq  0 ]] && v_ENCPASSKEYFILE=yes || v_ENCPASSKEYFILE=no
        v_ENCPASSKEYFILE=yes 
    else
        if [[ $(echo $v_output) =~ error ]] ; then  
            unset DPASS
            YesOrNo "Entered Password is Wrong. would  you like to retry with  new/correct password"
            if [[ $? -eq 0 ]]; then
                local retry=1
                ValidateEncryptedPassKey; return
            else
                v_ENCPASSKEYFILE=no
                return
            fi
            
        elif [[ $(echo $v_output) =~ magic ]]; then
            EchoAndLog A "Some  one modifed the  file"      
        else
            EchoAndLog A " Something wrong we cant use this file. file need to be recreated"
        fi
    fi
fi
 [[ $v_ENCPASSKEYFILE == no ]] && unset cuname srnumber  gv_sysenv

}
#-------------------------------------------------------------------
#PROCEDURE    : GetSRPatchSysEnv
#DESCRIPTION  : this is to get SR , Patch  number and System environment detail
#-------------------------------------------------------------------
GetSRPatchSysEnv(){         #---- requesting customer name sr number and System envroinment
if [[ $gc_argument1 == "pre-checkrack" ]] || [[ $gc_argument1 == "create-passkey" ]]
then
    EchoAndLog  " \n Enter the Customer name :  \c "
    read Cuname;echo $Cuname | tr -d "[:punct:]" | sed "s/ /-/g;s/,//g" | tr -d "[:space:]"  >$gc_tmpfileNB;strings $gc_tmpfileNB >$gc_tmpfile;cuname=$(cat $gc_tmpfile)
    EchoAndLog "\n Enter SR number : \c  "
    read Srnumber;srnumber=`echo $Srnumber | tr -d "[:blank:]"`
fi


    EchoAndLog "\n select ENVIRONMENT  \n \t 1. Virtual \n \t 2. Physical \n \t" # 3. Solaris \n"
    EchoAndLog "\n Enter the Environment number : \c "
    read envnumber
    
    while  ! [[ "$envnumber" =~ ^[0-9]+$ ]] || [[ $envnumber -gt 2 ]]
    do
        EchoAndLog  " Please  Enter the Number Correctly : \c"
        read   envnumber
    done
    
    case $envnumber in
        1)gv_sysenv="Virtual";;
        2)gv_sysenv="Linux";;
        #3)gv_sysenv="Solaris"; echo -e " \n This script not yet tested with Solaris ..  Sorry... :(  "; Exit 8;;
        *)EchoAndLog "Please enter the number correctly \n";Exit 8;;
    esac

if [[ $gc_argument1 != "passwd-check" ]]
then    
    [[ $gv_sysenv == Virtual ]] && EchoAndLog " 
    Release \t Virtual \n
    APR2018 \t 27454844
    JUL2018 \t 28044580
    OCT2018 \t 28428820
    " || EchoAndLog "
    Release \t Physical  \n 
    APR2018  \t 27454750
    JUL2018  \t 28044575
    OCT2018  \t 28428801"
    
    
    read  -p " Enter Patch Number : " patchnumber
    while ! [[ "$patchnumber" =~ ^[0-9]+$ ]] || [[ $(echo -n $patchnumber | wc -c) -ne 8 ]]
    do
        EchoAndLog  " Please  Enter the Patch Number Correctly : \c"
        read  patchnumber
    done
    
    gv_patchnumber=`echo $patchnumber | tr -d "[:space:]"`
fi
EchoAndLog 
}
#-------------------------------------------------------------------
#PROCEDURE    : ReadPassword
#DESCRIPTION  : this is to read password from user in CLI
#-------------------------------------------------------------------
ReadPassword(){             #---- get password from user without null value
local v_password
[[ $1 == "P" ]] && read -r  -p "$*" v_password || read  -s -r  -p "$*" v_password
if [[ -z $v_password ]];then echo -e "\n Cannot be empty - \c "; ReadPassword $* ;fi
echo 
[[ $1 == "P" ]] && v_enteredpassword=$v_password || v_enteredpassword=$(echo $v_password  |sed  's/\$/\\x24/g;s/\=/\\x3D/g;s/\#/\\x23/g;s/\@/\\x40/g')
}
#-------------------------------------------------------------------
#PROCEDURE    : AskPassword
#DESCRIPTION  : this is to ask password from  based on the system envroinment
#-------------------------------------------------------------------
AskPassword(){              #---- this to collect the password and assing to variable

  if [[ $1 != "onlycomputenode" ]]
        then
        YesOrNo "Common  password  for the Rack ? "
        if [[ $? -eq 0 ]]; then
             ReadPassword  "  Enter Common-Rack  password : " ;CRP=$v_enteredpassword
        fi
        EchoAndLog
   else
     [[ $RUNENV == jumpgate ]] &&   ReadPassword  " Enter Compute-Node root password:" ;CNP=$v_enteredpassword
   fi

    
    if [[ $1 != "onlycomputenode" ]]  && [[ -z $CRP ]] 
    then
        ReadPassword  " Enter Compute-Node root password:" ;CNP=$v_enteredpassword
        ReadPassword  " Enter ILOM-ComputeNode root password:";CNIP=$v_enteredpassword
        ReadPassword  " Enter ZFS-Storage-Head root password:";ZFSHEADP=$v_enteredpassword
        ReadPassword  " Enter ILOM-ZFS root password:";ZFSILOMP=$v_enteredpassword
        ReadPassword  " Enter NM2-GW-IB-Switch root password:";GWP=$v_enteredpassword
        ReadPassword  " Enter NM2-36p-IB-Switch root password:";SSP=$v_enteredpassword
    
    fi
    
    if [[ -n $CRP ]];then CNP=$CRP;CNIP=$CNP;ZFSILOMP=$CNP;ZFSHEADP=$CNP;GWP=$CNP;SSP=$CNP;fi
    
    
    if [[ $1 != "onlycomputenode" ]] && [[ $gv_sysenv == "Virtual" ]] ;then
        ReadPassword  " Enter common Exalogic Control vServer password:";OVMMECP=$v_enteredpassword
        ReadPassword  " Enter vServer-EC-EMOC-PC password:";OVMMPCP=$v_enteredpassword
        ReadPassword  " Enter weblogic password :";WLP=$v_enteredpassword
    fi

    if [[ $1 != "onlycomputenode" ]] ; then
        until [[ -n $DERP ]]
        do  
            ReadPassword  "Enter  Default  Exalogic Rack password $wl :";DERP=$v_enteredpassword
            v_output=$(echo "U2FsdGVkX19i+g6GtZfOhypO8F8wpUVOwrwrlwW9oVQ=" | openssl enc -d -aes-256-cbc -a -salt -pass pass:$DERP  2>/dev/null)
            [[ $v_output != karthi ]] &&  unset DERP    
                wl="stars with w and end with one "
        done
        unset wl
    fi
if [[ $gc_argument1 != "passwd-check" ]] 
then
    echo  -e "\n \n Customer Name : $cuname \n SR-Number : $srnumber \n Environment : $gv_sysenv \n PATCH-NUMBER : $gv_patchnumber  \n">${gc_tmpdir}/passwdcheck.out
    cat ${gc_tmpdir}/passwdcheck.out  
    YesOrNo " Was the above Information correct ?  "
    if [[ $? -ne 0 ]];then  GetSRPatchSysEnv;return ;fi
fi
UngrepUpdate
}
#-------------------------------------------------------------------
#PROCEDURE    : CreateAndCopyCustomScript
#DESCRIPTION  : create and copy the customer expect script to the computenode one
#-------------------------------------------------------------------
CreateAndCopyCustomScript(){ #---- create and copy custom expect
echo " 
echo -n brcustpass
stty -echo
read -r -s brcustpass
stty echo
export brcustpass
echo
HNS=/exalogic-lctools/lib/exapatch/${EXAPATCHVERSION}/expect/br_ilom_get_hostname.exp
SSS=/exalogic-lctools/lib/exapatch/${EXAPATCHVERSION}/expect/br_ssh_command.exp

if [[ \`echo \$2\` =~ 'show /SP/ hostname' ]]
then 
    [[ ! -f  \$HNS ]] && sed s/'\[lindex \$argv 2\]'/'\$::env\(brcustpass\)'/g /exalogic-lctools/lib/exapatch/${EXAPATCHVERSION}/expect/ilom_get_hostname.exp >\$HNS
    expect \$HNS  \$1 root hidden 
else
    [[ ! -f \$SSS ]] && sed s/'\[lindex \$argv 2\]'/'\$::env\(brcustpass\)'/g /exalogic-lctools/lib/exapatch/${EXAPATCHVERSION}/expect/ssh_command.exp > \$SSS
    expect \$SSS  \$1 root hidden \" \$2 \"
fi
">$gc_tmpdir/brcustexpect.sh

CMD="scp $gc_tmpdir/brcustexpect.sh  root@${gv_argument2}:/exalogic-lctools/lib/exapatch/${EXAPATCHVERSION}/expect/brcustexpect.sh"
v_output=$(ExpectToolNB $gv_argument2 $CNP $CMD )
if [[ $? -ne 0 ]] ; then  EchoAndLog A "Error occured while copying the customer script"; Exit 10 ; fi
}
#-------------------------------------------------------------------
#PROCEDURE    : PatchBasicDetail
#DESCRIPTION  : collect patching basic detail and setup the  environment to run the script 
#-------------------------------------------------------------------
PatchBasicDetail(){         #---- to collect patch basic detail
local v_ENCPASSKEYFILE

    [[ $gc_argument1 != create-passkey ]] && ValidateEncryptedPassKey
    [[ $v_ENCPASSKEYFILE != yes ]] && GetSRPatchSysEnv
    [[ $v_ENCPASSKEYFILE != yes ]] && AskPassword $1
    UsingCommand
    ExpectTool $gv_argument2 $CNP "hostname"  >/dev/null 
    if [[ $gv_ExitCode -eq 8 ]] ;then EchoAndLog  "\n [ ATTENTION] Password Entered for the node $gv_argument2 is wrong \n ";Exit 8 ;fi
    if [[ $gv_ExitCode -eq 9 ]] ;then EchoAndLog " $gv_argument2 node Not reachable : Enter correct IP address  or Nodename  as per /etc/hosts file !";Exit 8;fi
    v_output=$(ExpectTool $gv_argument2 $CNP "ls  -t /exalogic-lctools/lib/exapatch/ | awk 'NR==1' ")
    EXAPATCHVERSION=$(echo "$v_output" | grep 1.2)
    CreateAndCopyCustomScript
    v_output=$(ExpectTool $gv_argument2 $CNP 'set')
    EXABR_REPO=$(echo "$v_output"| grep EXABR_REPO= |awk -F = '{print $2}')
    
    EchoAndLog;EchoAndLog C " Components list using exaptch -a listComponents"
    ExpectTool $gv_argument2 $CNP "$gc_EXAPATCH -a listComponents" >$gv_componentlistfile 
    
    [[ $(cat  $gv_componentlistfile) =~ vServer-EC-OVMM ]] && local  AUENV=Virtual || local AUENV=Linux
    [[ $gv_sysenv != $AUENV ]] && EchoAndLog A " Select Environment is $gv_sysenv . but as per Rackconfiguration.py it is $AUENV . please correct it and start script"
    [[ $gv_sysenv != $AUENV ]] && Exit 99
    

    
    if [[ $gc_argument1 != "passwd-check" ]] && [[ $gc_argument1 != "stage-psu" ]]   && [[ $gc_argument1 != "create-passkey" ]]
    then
        CheckStaging 
        CheckCnodesFile 
        ZfsPassLessSSHCheck
        
        v_output=$(ExpectTool $gv_argument2 $CNP 'echo \"hostname = `hostname`\"' )
        CN01=`echo "$v_output" | grep  "hostname =" |awk '{print $3}' |awk -F "." '{print $1}'`
        local c_PATCHDESFILE=${gc_tmpdir}/${gv_patchnumber}_exapatch_descriptor.py 
        if [[ -f $c_PATCHDESFILE ]]; then 
                EchoAndLog LINE
                local swichversion=$(awk "/getNm2_gwVersion/ {getline;print;exit 0}" $c_PATCHDESFILE | awk '{print $2}' )
                SWITCHVERSION=`awk "/getNm2_gwVersion/ {getline;print;exit 0}" $c_PATCHDESFILE | awk '{print $2}'  | tr -d " [:punct:]"`
                local psuno=`sed -n '/getCnInfo/{n;n;p}' $c_PATCHDESFILE  | awk '{print $8}' | awk -F . '{print $5}' | tr -d "[:punct:]"`
                PSUNAME=`date -d $psuno +"%b-%Y"`
                local currentpsu=$(ExpectTool $gv_argument2 $CNP 'imageinfo' | grep 'Image version'  | awk -F . '{print $5}')
                local CURRENTPSU=`date -d $currentpsu +"%b-%Y"`
                echo  -e "\n \n Customer Name : $cuname \n SR-Number : $srnumber \n Environment : $gv_sysenv \n PATCH-NUMBER : $gv_patchnumber \n Current CN01 PSU : $CURRENTPSU \n Target PSU-NAME : $PSUNAME \n Target IB Switch Version : $swichversion \n "
        fi
    fi
    EchoAndLog LINE
}
#-------------------------------------------------------------------
#PROCEDURE    : ZfsPassLessSSHCheck
#DESCRIPTION  :  this will do password less  ssh check from cn01 to zfs head
#-------------------------------------------------------------------
ZfsPassLessSSHCheck(){      #---- this is to check password less ssh between zfs and cn01
local v_outcode=0 
unset v_output
EchoAndLog CK "Password less ssh between CN01 and ZFS head ... \c  "
for i in $(grep ZFS-Storage-Head $gv_componentlistfile |grep -v Enter | awk '{print $2}')
do
    EchoAndLog " $i - \c"
    v_output=$(ExapatchExpect $i  nopass 'configuration cluster show')
    if [[ ! $v_output =~ "peer_state" ]] ; then 
        EchoAndLog ; EchoAndLog A "Password less ssh between CN01 and ZFS head $i  is not set. \n set it to proceed:- Make sure its using RSA key. if RSA key not there. use 'ssh-keygen' to generate \n Step: #$gc_EXABR init-ssh $i "
        DoubleEnter
        v_outcode=$?
        if [[ $v_outcode -eq 0 ]];then
           ZfsPassLessSSHCheck
           v_outcode=$?
           return $v_outcode
        else
           Exit 9
        fi
    fi
    local value=`echo "$v_output" | grep description | grep = | awk  'NR==1'`
    [[ $value =~ Active ]] && v_activezfsip=$i
done
EchoAndLog " - Passed "
return $v_outcode
}
#-------------------------------------------------------------------
#PROCEDURE    : CheckStaging    
#DESCRIPTION  : this is to check whether patch staged or not
#-------------------------------------------------------------------
CheckStaging(){             #---- check whether staging done or not
EchoAndLog LINE
EchoAndLog CK "Whether PSU $gv_patchnumber  staged or not.. \c "
v_output=$(ExpectTool $gv_argument2 $CNP "ls -ld /exalogic-lcdata/patches/${gv_sysenv}/${gv_patchnumber}/Infrastructure/exapatch_descriptor.py")
err=$(echo "$v_output" | grep directory)
if [[ -n $err ]]
then
    YesOrNo "Note: PSU $gv_patchnumber not yet staged . Without staging script will not proceed.\n \n Do you want me to stage it ? "
    if [[ $? -eq 0 ]]
    then
        StagePatch
    else
        Exit 8  
    fi
    
else    
    if [[ ! -f ${gc_tmpdir}/${gv_patchnumber}_exapatch_descriptor.py  ]] ; then 
        CMD="scp root@${gv_argument2}:/exalogic-lcdata/patches/${gv_sysenv}/${gv_patchnumber}/Infrastructure/exapatch_descriptor.py ${gc_tmpdir}/${gv_patchnumber}_exapatch_descriptor.py"
        ExpectToolNB $gv_argument2 $CNP $CMD >/dev/null 2>&1
    fi
        
    EchoAndLog   ".. Staged "
fi
}
#-------------------------------------------------------------------
#PROCEDURE    : ZipFileConsistencyCheck
#DESCRIPTION  : This is to check patch zip file consistency. check download is proper or not.
#-------------------------------------------------------------------
ZipFileConsistencyCheck(){  #---- check patch consistency
local v_patchison=$1
local v_out
EchoAndLog I "Checking Patch .zip file consistency"
[[ $v_patchison == local ]] && v_output=$(ls $gv_patchlocation/p${gv_patchnumber}*.zip ) && v_output=$(ExpectTool $gv_argument2 $CNP "ls $gv_patchlocation/p${gv_patchnumber}*.zip")
for i in $(echo "$v_output" | grep .zip )
do
    [[ $v_patchison == local ]] &&  v_out=$(unzip -l $i 2>&1;echo v_exitcode=$?)
    [[ $v_patchison == remote ]] && v_out=$(ExpectTool $gv_argument2 $CNP \"unzip -l $i 2>&1 \; echo v_exitcode=\$?\")
    v_exitcode=$(echo $v_out | awk -F  v_exitcode= '{print $2}')
    [[ $v_exitcode -ne 0 ]] && ( echo $i >>  ${gc_tmptmp}/consistency )
done

[[ ! -f ${gc_tmptmp}/consistency ]] && EchoAndLog  I "Patch zip file Consistency  Success" ||   EchoAndLog  E "Patch zip file Consistency  Failed. need to download following zip file again"
[[ -f ${gc_tmptmp}/consistency ]] && cat ${gc_tmptmp}/consistency 
[[ -f ${gc_tmptmp}/consistency ]] &&  Exit 10  

}
#-------------------------------------------------------------------
#PROCEDURE    : StagePatch
#DESCRIPTION  :  this is to stage the patch
#-------------------------------------------------------------------
StagePatch(){               #---- stage the patch 
local v_activezfsip
ZfsPassLessSSHCheck #----------- check password less ssh between CN and ZFS
EchoAndLog I "Active ZFS Head = $v_activezfsip"

EchoAndLog  " \n Enter the *.zip file location : \c"
read gv_patchlocation
EchoAndLog 
EchoAndLog $gv_patchlocation >>$gv_logfile
v_output=$(ls $gv_patchlocation/p${gv_patchnumber}*.zip 2>&1 | head -1)

if [[ -e $v_output ]] ; then
    EchoAndLog I "Patch Zip file found on $RUNENV"
    if  [[ -r $v_output ]];then
        v_patchison=localpath
    else
        EchoAndLog E "Patch Zip not having read permission : run this to fix 'sudo chmod 644 $gv_patchlocation/*'"
        DoubleEnter
        StagePatch
        return $?   
    fi
    
elif [[ $RUNENV == jumpgate ]] ;then
    EchoAndLog I "Patch Zip file not found on Jumpgate. so checking  on Compute node"
    v_output=$(ExpectTool $gv_argument2 $CNP "ls $gv_patchlocation/p${gv_patchnumber}*.zip")
    if [[ $v_output =~ x86 ]] ; then 
       EchoAndLog I "Patch Zip file found on Compute node"
       v_patchison=remote
    else
        EchoAndLog A "Patch file not found on Jumpgate and  Compute node. please enter correct path."
        StagePatch
        return $?
    fi
else
    EchoAndLog  A " Patch *.zip file missing or incorrect patch location \n"
    StagePatch
    return $?   
fi

ZipFileConsistencyCheck $v_patchison
    
#------ Runenv node and   patch location on local.
if [[ $RUNENV == node ]] && [[ $v_patchison == localpath ]]
then
    EchoAndLog I "Going to verify /exalogic-lcdata mountpoint size and  then it will start ... \n"
    csize=`df -Phm /exalogic-lcdata |grep common |awk '{print $4}'`
    IPOIBzfsip=`df -Ph /exalogic-lcdata | grep common | awk -F ":" '{print $1}'`
    EchoAndLog LINE;
            
    if  [[ -z $csize ]] || [[ $csize -le 21840 ]] 
    then
        let "Csize=$csize/1024"
        EchoAndLog I" fix the follwing issue and hit enter to stagepatch"
        EchoAndLog A " There is not Sufficent  space on  /exalogic-lcdata. need is 21GB. but there is only $Csize GB  "
        DoubleEnter 
        [[ $? -eq 0 ]] && StagePatch
    else
        cd $gv_patchlocation
        for i in $(ls p${gv_patchnumber}*.zip)
        do              
            unzip -o $i
        done
        chmod u+x psuSetup.sh
        EchoAndLog DLINE; EchoAndLog I " Going to run psuSetup.sh $v_activezfsip \n"
        EmptyNB;./psuSetup.sh $v_activezfsip  -f  | tee -a $gc_tmpfileNB
        if [[ ! $(cat $gc_tmpfileNB) =~ "PSU extracted successfully at " ]] ; then EchoAndLog  "A psuSetup failed !!! stoping script." ;Exit 8 ;fi
        v_output=$(ExpectTool $gv_argument2 $CNP "ls  -t /exalogic-lctools/lib/exapatch/ | awk 'NR==1' ")
        EXAPATCHVERSION=$(echo "$v_output" | grep 1.2)
        CreateAndCopyCustomScript
        
        cd $gv_currentpwd
    fi
            
elif [[ $RUNENV == "jumpgate" ]] && [[ $v_patchison == localpath ]]
then
    
    EchoAndLog I "Going to verify /exalogic-lcdata mountpoint size and  then it will start ... \n"
    v_output=$(ExpectTool $gv_argument2 $CNP "df -Phm /exalogic-lcdata ")
    echo "$v_output" | tee -a $gc_tmpfile
    csize=`grep \: $gc_tmpfile | grep common |awk '{print $4}'`
    IPOIBzfsip=`grep \: $gc_tmpfile |grep common | awk -F ":" '{print $1}'`
    
    if  [[ -z $csize ]] || [[ $csize -le 35840 ]] 
    then
        let "Csize=$csize/1024"
        EchoAndLog I " fix the follwing issue and hit enter to stagepatch \n"
        EchoAndLog A " There is not Sufficent  space on  /exalogic-lcdata. need is 35GB. but there is only $Csize GB "
        DoubleEnter 
        [[ $? -eq 0 ]] && StagePatch 
    else
        TIMEOUT=3600
        ExpectTool $gv_argument2 $CNP "mkdir -p  /exalogic-lcdata/${gv_patchnumber}"
        sudo  chmod g+r,o+r  ${gv_patchlocation}/*.zip
        EchoAndLog I " copying file from jumpgate to compute node Location : /exalogic-lcdata/${gv_patchnumber} "
        CMD="scp ${gv_patchlocation}/*.zip root@${gv_argument2}:/exalogic-lcdata/${gv_patchnumber}"
        ExpectToolNB $gv_argument2 $CNP $CMD
        cd $gv_patchlocation
        EchoAndLog I "Going to patch file unzip the file"
        for i in $(ls p${gv_patchnumber}*.zip)
        do              
            ExpectToolNB $gv_argument2 $CNP "unzip -o -d /exalogic-lcdata/${gv_patchnumber} /exalogic-lcdata/${gv_patchnumber}/${i}"
        done
        EchoAndLog DLINE; EchoAndLog I " Going to run psuSetup.sh $v_activezfsip \n" 
        EmptyNB;ExpectToolNB $gv_argument2 $CNP  "cd /exalogic-lcdata/${gv_patchnumber}\;sh ./psuSetup.sh $v_activezfsip -f " |tee -a $gc_tmpfileNB
        if [[ ! $(cat $gc_tmpfileNB) =~ "PSU extracted successfully at " ]] ; then EchoAndLog  "A psuSetup failed !!! stoping script." ;Exit 8;fi
        v_output=$(ExpectTool $gv_argument2 $CNP "ls  -t /exalogic-lctools/lib/exapatch/ | awk 'NR==1' ")
        EXAPATCHVERSION=$(echo "$v_output" | grep 1.2)
        CreateAndCopyCustomScript
        gv_patchlocation="/exalogic-lcdata/${gv_patchnumber}"
    fi
elif [[ $RUNENV == jumpgate ]] && [[ $v_patchison == remote ]]
then
    EchoAndLog I "Going to verify /exalogic-lcdata mountpoint size and  then it will start ... \n"
    v_output=$(ExpectTool $gv_argument2 $CNP "df -Phm /exalogic-lcdata ")
    echo "$v_output" | tee -a $gc_tmpfile
    csize=`grep \: $gc_tmpfile | grep common |awk '{print $4}'`
    IPOIBzfsip=`grep \: $gc_tmpfile |grep common | awk -F ":" '{print $1}'`
    
    if  [[ -z $csize ]] || [[ $csize -le 21840 ]] 
    then
        let "Csize=$csize/1024"
        EchoAndLog I " fix the follwing issue and hit enter to stagepatch \n"
        EchoAndLog A " There is not Sufficent  space on  /exalogic-lcdata. need is 35GB. but there is only $Csize GB "
        DoubleEnter 
        [[ $? -eq 0 ]] && StagePatch 
    else
        TIMEOUT=3600
        
        v_output=$(ExpectTool $gv_argument2 $CNP "ls $gv_patchlocation/p${gv_patchnumber}*.zip")
        EchoAndLog I "Going to patch file unzip the file"
        for i in $(echo "$v_output" | grep x86 )
        do              
            ExpectToolNB $gv_argument2 $CNP "unzip -o -d /${gv_patchlocation}/ $i"
        done
        EchoAndLog DLINE; EchoAndLog I " Going to run psuSetup.sh $v_activezfsip \n" 
        EmptyNB;ExpectToolNB $gv_argument2 $CNP  "cd /exalogic-lcdata/${gv_patchnumber}\;sh ./psuSetup.sh $v_activezfsip -f " |tee -a $gc_tmpfileNB
        if [[ ! $(cat $gc_tmpfileNB) =~ "PSU extracted successfully at " ]] ; then EchoAndLog  "A psuSetup failed !!! stoping script." ;Exit 8;fi
        v_output=$(ExpectTool $gv_argument2 $CNP "ls  -t /exalogic-lctools/lib/exapatch/ | awk 'NR==1' ")
        EXAPATCHVERSION=$(echo "$v_output" | grep 1.2)
        CreateAndCopyCustomScript
        gv_patchlocation="/exalogic-lcdata/${gv_patchnumber}"
    fi

else 
        EchoAndLog A " RUNENV is not set. so stoping scrit";Exit 8  
fi
}
#-------------------------------------------------------------------
#PROCEDURE    : CheckCnodesFile
#DESCRIPTION  :  check and create custom cnode file
#-------------------------------------------------------------------
CheckCnodesFile(){          #---- check cnode file present or not
EchoAndLog CK "whether $gc_CNODEFILEPATH file present or not.. used  by this script \c"
v_output=$(ExpectTool $gv_argument2 $CNP "cat  $gc_CNODEFILEPATH")
v_output=$(echo "$v_output" | $gv_customungrep )
tc=`grep -c Compute-Node $gv_componentlistfile`;cc=`echo "$v_output" | wc -l | awk '{print $1}'`
if [[ -z $v_output ]] || [[ $v_output =~ directory ]]  || [[ $tc -gt $cc ]]
then
    #YesOrNo "\n $gc_CNODEFILEPATH  file missing or incorrect ! do you want me to create it ? "
    if [[ $? -eq 0 ]]
    then
        echo -e "\n Creating  $gc_CNODEFILEPATH file .. "
        ExpectTool $gv_argument2 $CNP "rm $gc_CNODEFILEPATH" >/dev/null
        for i in $(grep Compute-Node  $gv_componentlistfile | awk '{print $2}')
        do
        ExpectTool $gv_argument2 $CNP "echo $i >>$gc_CNODEFILEPATH" >/dev/null
        echo $i >>${gc_tmptmp}/cnodes
        done
        ExpectTool $gv_argument2 $CNP "cat $gc_CNODEFILEPATH" | $gv_customungrep 
        EchoAndLog I "cnodes file created. proceeding next step "
    else
        EchoAndLog A "Create it manually and start the script again ";Exit 8 
    fi
else 
    EchoAndLog "present "
    echo "$v_output" >${gc_tmptmp}/cnodes
    NODECOUNT=$(grep -c Compute-Node $gv_componentlistfile)
fi

}

#-------------------------------------------------------------------
#PROCEDURE    : LogPasswordCheck
#DESCRIPTION  : Log the password check output to the file
#-------------------------------------------------------------------
LogPasswordCheck(){         #--- log the password check fuction output
    if [ $gv_ExitCode  == 8 ]
        then
               EchoAndLog  "$1 \t $2 = $3 = $RED Wrong-password $WHITE " >>${gc_tmptmp}/passwdcheck.out_suffled
        elif [ $gv_ExitCode == 9 ]
        then
              EchoAndLog   "$1 \t $2 = $3 = $RED Not-reachable $WHITE"  >>${gc_tmptmp}/passwdcheck.out_suffled
        elif [ $gv_ExitCode == 0 ]
        then
            EchoAndLog   "$1 \t $2 = $3 = $GREEN Successful $WHITE = $4 = $5 " >>  ${gc_tmptmp}/passwdcheck.out_suffled
    fi
    touch ${gc_tmptmp}/$1_$2_checkdone
}
#-------------------------------------------------------------------
#PROCEDURE    : PasswordCheckFunction
#DESCRIPTION  :  check the password of all component
#-------------------------------------------------------------------
PasswordCheckFunction(){    #--- to verify password of all components
        TIMEOUT=30
        local   CV=''
        local problem=''
        local totalcomponent=$(grep root $gv_componentlistfile  |  grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'  | uniq | wc -l )
        EchoAndLog "\n Going to verify the Component password... Will take  Near to 40 Seconds : Total Components = $totalcomponent" 
        EchoAndLog >${gc_tmpdir}/passwdcheck.out
        
        for Component in Compute-Node NM2-GW-IB-Switch  NM2-36p-IB-Switch vServer-EC-OVMM  vServer-EC-EMOC-PC
        do
            [[ $Component == Compute-Node ]] && cpass=$CNP
            [[ $Component == NM2-GW-IB-Switch ]] && cpass=$GWP
            [[ $Component == NM2-36p-IB-Switch ]] && cpass=$SSP
            [[ $Component == vServer-EC-OVMM  ]] && cpass=$OVMMECP
            [[ $Component == vServer-EC-EMOC-PC ]] && cpass=$OVMMPCP
                
            for i in $(grep $Component $gv_componentlistfile |grep -v Enter| awk '{print $2}')
            do  
                
                ( v_output=$(ExpectTool $i $cpass 'echo \"hostname = `hostname`\"' );gv_ExitCode=$?
                if [[ $gv_ExitCode -ne  "0" ]] ;then [[ $gv_ExitCode  -eq 8  ]] && problem="Wrong-password" || problem="Not-reachable"
                    v_output=$(ExapatchExpect $i $cpass 'echo hostname = \`hostname\`');gv_ExitCode=$?;CV="vianode" 
                fi
                [[ $gv_ExitCode -eq 0 ]] && hn=`echo "$v_output" | grep  "hostname =" |awk '{print $3}' |awk -F "." '{print $1}'`
        
                LogPasswordCheck $Component "$i" "$hn" "$CV" "$problem" ; unset hn CV problem gv_ExitCode ) & 
            done    
        done
        
        for Component in ILOM-ComputeNode  ILOM-ZFS
        do
            [[ $Component == ILOM-ComputeNode ]] && cpass=$CNIP
            [[ $Component == ILOM-ZFS ]] && cpass=$ZFSILOMP
            for i in $(grep $Component $gv_componentlistfile |grep -v Enter | awk '{print $2}')
            do
                ( v_output=$(ExpectTool $i $cpass 'show /SP/ hostname');gv_ExitCode=$?
                [[ $gv_ExitCode -eq 0 ]] && hn=`echo "$v_output"| grep  "hostname =" | awk '{print $3}'`
                if [[ $gv_ExitCode -ne  "0" ]]  || [[ -z $hn ]] ;then [[ $gv_ExitCode  -eq 8  ]] && problem="Wrong-password" || problem="Not-reachable"
                    v_output=$(ExapatchExpect $i $cpass 'show /SP/ hostname');gv_ExitCode=$?;CV="vianode" 
                fi
                [[ $gv_ExitCode -eq 0 ]] && hn=`echo "$v_output"| grep  "hostname =" | awk '{print $3}'`
                if [[ $gv_ExitCode -eq 0 ]] && [[ -z $hn ]] ;then   problem="failed to get hostname due to $v_output";fi
                LogPasswordCheck $Component "$i" "$hn" "$CV" "$problem" ; unset hn CV problem gv_ExitCode ) &
            done
        
        done
    
        for i in $(grep ZFS-Storage-Head $gv_componentlistfile |grep -v Enter | awk '{print $2}')
        do
            ( v_output=$(ExpectTool $i $ZFSHEADP 'configuration version show');gv_ExitCode=$?
            if [[ $gv_ExitCode -ne  "0" ]] ;then [[ $gv_ExitCode  -eq 8  ]] && problem="Wrong-password" || problem="Not-reachable"
                 v_output=$(ExapatchExpect $i $ZFSHEADP 'configuration version show');gv_ExitCode=$?;CV="vianode" 
            fi
            [[ $gv_ExitCode -eq 0 ]] && hn=`echo "$v_output" | grep  "Appliance Name:" | awk '{print $3}'`
            LogPasswordCheck ZFS-Storage-Head "$i" "$hn" "$CV" "$problem" ; unset  hn CV problem gv_ExitCode ) &
        done

        
        local Component="Compute-Node ILOM-ComputeNode  ILOM-ZFS  ZFS-Storage-Head NM2-GW-IB-Switch NM2-36p-IB-Switch vServer-EC-OVMM  vServer-EC-EMOC-PC   "

        EchoAndLog "\n So far completed : \c"
        unset running
        until [[ $running == no ]] 
        do
        sleep 3
            for i in $Component
            do
                ccount=$(ls ${gc_tmptmp}/*_checkdone  2>$gc_tmpfile | wc -l )  > /dev/null 2>&1 
                [[ $totalcomponent -eq $ccount ]] && running=no || running=yes
            done 
        EchoAndLog "-${ccount}\c "  
        done
         
         
    for i  in $Component
    do  
            for ip in $(grep $i $gv_componentlistfile  |  grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'  | uniq)
            do
                grep $ip ${gc_tmptmp}/passwdcheck.out_suffled >> $gc_tmpdir/passwdcheck.out
            done
            EchoAndLog "" >> $gc_tmpdir/passwdcheck.out 
    done
        
        
    if [[ $gv_sysenv == Virtual ]] && [[ $(cat $gc_tmpdir/passwdcheck.out | grep vServer-EC-OVMM) =~ Successful ]];then 
        EchoAndLog "- Checking weblogic-password"
         
        local v_output=$(local gv_componentlistfile="$gc_tmpdir/passwdcheck.out";CheckWebLogicPassword passcheckfunction)
        [[  $v_output =~ "RUNNING" ]] && ( EchoAndLog "weblogic Password =   Entered Passwd Correct   = Successful " >> $gc_tmpdir/passwdcheck.out )|| ( EchoAndLog "weblogic Password =  Entered Passwd: $WLP  = Wrong Password" >> $gc_tmpdir/passwdcheck.out )
    elif [[ $gv_sysenv == Virtual ]];then
        EchoAndLog "weblogic Password = Failed = due to not able to connect EC OVMM" >> $gc_tmpdir/passwdcheck.out
    fi
    
    unset Component;unset i;unset ip
    cat ${gc_tmpdir}/passwdcheck.out
    
    [[ $gc_argument1 == create-passkey ]] && return
    
    grep = ${gc_tmpdir}/passwdcheck.out| grep -v Successful >${gc_tmpdir}/passwdcheck.error
    if [[ $gc_argument1 != "passwd-check" ]]
    then
        if [[ $(cat ${gc_tmpdir}/passwdcheck.error) =~ Wrong ]] || [[ $(cat ${gc_tmpdir}/passwdcheck.error) =~ reachable ]]
        then
        
            if [[ $gc_argument1 == "pre-checkrack" ]];then
                unsc=$(grep = ${gc_tmpdir}/passwdcheck.out | grep -v Successful)
                YesOrNo "Password check Failed  !!! . Please  validate password. 
                \n Note: Script will  collect Only from  Successful component. 
                \n Still if you want to continue type ? "
                [[ $? -ne 0 ]] && Exit 10
                gv_ExitCode=0
            else
                unsc=$(grep = ${gc_tmpdir}/passwdcheck.out | grep -v Successful)
                YesOrNo "Password check Failed!! . please validate password.
                \n NOte: Script will do patching only if all component password success or able to reach vianode.
                \n Do you want me  to restart script and  enter the password again ? "
                if [[ $? -eq 0 ]];then
                    AskPassword 
                    PasswordCheckFunction
                    return
                else
                    Exit 10
                fi
            fi
                
        fi
        EchoAndLog DLINE
    fi
    
    grep Successful ${gc_tmpdir}/passwdcheck.out >${gc_tmpdir}/passwdcheck.Successful
    gv_componentlistfile="${gc_tmpdir}/passwdcheck.Successful"
    cp $gv_componentlistfile ${gc_tmptmp}/noask_$gv_datetime

    local nnf=$(grep Compute-Node $gv_componentlistfile | head -1 |awk '{print $4}')
    local nnil=$(grep ILOM-ComputeNode $gv_componentlistfile | head -1 |awk '{print $4}')
    gv_ilomsuffix=$(echo $ilomname | sed s/$nnf//g)
    unset nnf;unset nnil
    
}
#-------------------------------------------------------------------
#PROCEDURE    : CheckWebLogicPassword
#DESCRIPTION  : check weblogic password
#-------------------------------------------------------------------
CheckWebLogicPassword(){    #--- to check weblogic password
[[ $gv_sysenv == "Linux" ]] && return 0
local ovmip=$(grep vServer-EC-OVMM  $gv_componentlistfile  | awk '{print $2}')
if [[ ! $(cat $gv_componentlistfile)  =~ vServer-EC-OVMM  ]] ; then EchoAndLog  A " Not able to check weblogic. Due to OVMM password was wrong ";return;fi

local v_checkweblogicpasswd="source /u01/app/oracle/ovm-manager-3/machine1/base_adf_domain/bin/setDomainEnv.sh && java weblogic.Admin -url localhost:7001 -username weblogic -password $WLP GETSTATE" 

[[ $1 == passcheckfunction ]] &&  ExpectTool  $ovmip $OVMMECP $v_checkweblogicpasswd 
[[ $1 == passcheckfunction ]] &&  return

EchoAndLog LINE; EchoAndLog C " Going to verify weblogic password  ";EchoAndLog EC $v_checkweblogicpasswd 
v_output=$(ExpectTool  $ovmip $OVMMECP $v_checkweblogicpasswd)
EchoAndLog "$v_output"
[[ $v_output =~ "RUNNING" ]] && EchoAndLog I "weblogic password is what you enter is correct" || EchoAndLog E "weblogic is password entered is wrong - get it from customer "
}
#-------------------------------------------------------------------
#PROCEDURE    : CreateEncryptedPassKeyFile
#DESCRIPTION  :  create the encrypted pass key file
#-------------------------------------------------------------------
CreateEncryptedPassKeyFile(){       #--- this is to create Enctyped pass file
local PASSFILENAME=ENCRYPTEDPASSFILE_$(date +%Y%m%d)
local epocode=1

YesOrNo "Shall I create passkey with above  Information  ?"
if [[ $? -eq  0 ]] ;then
until [[ $epocode -eq 0 ]];do
    EchoAndLog " Enter the  passkey twice to confirm: \n "
    echo -e "
BREXALOGIC 
cuname=$cuname 
srnumber=$srnumber
gv_sysenv=$gv_sysenv
gv_patchnumber=$gv_patchnumber
CRP=$CRP
CNP=$CNP
CNIP=$CNIP
ZFSHEADP=$ZFSHEADP
ZFSILOMP=$ZFSILOMP
GWP=$GWP
SSP=$SSP
OVMMECP=$OVMMECP
OVMMPCP=$OVMMPCP
WLP=$WLP
DERP=$DERP " | openssl enc -e -aes-256-cbc -a -salt >${gc_tmpdir}/$PASSFILENAME
    epocode=$?
    [[ $epocode -eq  1 ]] && EchoAndLog E " Password mismatch "
done
    EchoAndLog I " Enctyped Password file created : ${gc_tmpdir}/$PASSFILENAME"
else
    EchoAndLog A "Password key file is not created.  Start the script again to create it. " 
    
fi

}

#-------------------------------------------------------------------
#PROCEDURE    : ComputeNodeDetail
#DESCRIPTION  : this is to collect compute node detail and analysis
#-------------------------------------------------------------------
ComputeNodeDetail(){        #--- to collect compute node detail and analysis
ip=$gv_argument2
passwd=$CNP
EchoAndLog LINE ; EchoAndLog C " verifying password less ssh between CN01 to other compute node"
[[ -f ${gc_tmptmp}/cnodes ]] || EchoAndLog E "cnodes file not collected . re-run the script"
[[ -f ${gc_tmptmp}/cnodes ]] || Exit 10
unset issue

for i in $(grep Compute-Node $gv_componentlistfile | awk '{print $4}')
do
    v_output=$(ExapatchExpect $i  nopass uptime )   
    if [[ ! $v_output =~ average ]];then    EchoAndLog E "Password less ssh between  CN01  & $i  is no there. correct it";local  issue=yes
    else EchoAndLog I "CN01 to $i passed " ;fi
done
if [[ $issue =~ "yes" ]] && [[ $gc_argument1 == "pre-checkrack" ]] ;then EchoAndLog E " Password less ssh between CN01 and some nodes are not there. correct it and re-run the script ";Exit 10 ;fi

EchoAndLog LINE; EchoAndLog C " SW profile from  all compute node" ; EchoAndLog EC "$c_CNCHECK1";v_output=$(ExpectTool $ip $passwd $c_CNCHECK1);EchoAndLog "$v_output"
err=$(echo "$v_output" | grep \: | grep '\['| grep -v -i SUCCESS);[[ $err ]] && EchoAndLog E " SW profile verification found issue"


EchoAndLog LINE; EchoAndLog C " HW profile from  all compute node" ; EchoAndLog EC "$c_CNCHECK2";v_output=$(ExpectTool $ip $passwd $c_CNCHECK2);EchoAndLog "$v_output"
tc=$(echo "$v_output" | grep  -c 'Firmware verification succeeded' );sleep 1; [[ $tc -ne $NODECOUNT ]] && EchoAndLog E "Check HW profile of some node failed"
 
EchoAndLog LINE; EchoAndLog C " ROOT filesystem size  from  all compute node" ; EchoAndLog EC "$c_CNCHECK3";v_output=$(ExpectTool $ip $passwd $c_CNCHECK3);EchoAndLog "$v_output";v_output=$(echo "$v_output" | grep : | grep dev)

case $gv_sysenv in
    Virtual) v_Min_Root_free_m_required=700 ;v_Min_Boot_free_m_required=30;;
    Linux)  v_Min_Root_free_m_required=4096 ;v_Min_Boot_free_m_required=50;;
    Solaris) v_Min_Root_free_m_required=4096 ;;
esac 

local v_AllCn_IP_n_root_free_m=$(echo -e "$v_output"| awk '$0 !~ /Filesystem/ {print $1" "$5}' )
while IFS=':' read CN CN_Root_free_m ; do
[[ $CN_Root_free_m -ge $v_Min_Root_free_m_required ]]|| EchoAndLog A "$CN: Free space required on root filesystem: ${v_Min_Root_free_m_required}MB but  Available is  ${CN_Root_free_m}MB"
done <<< "${v_AllCn_IP_n_root_free_m}"

EchoAndLog LINE; EchoAndLog C " /boot filesystem  size from   all compute node" ; EchoAndLog EC "$c_CNCHECK4";v_output=$(ExpectTool $ip $passwd $c_CNCHECK4);EchoAndLog "$v_output";v_output=$(echo "$v_output" | grep : | grep dev)

local v_AllCn_IP_n_boot_free_m=$(echo -e "$v_output"| awk '$0 !~ /Filesystem/ {print $1" "$5}' )
while IFS=':' read CN CN_Boot_free_m ; do
[[ $CN_Boot_free_m -ge $v_Min_Boot_free_m_required ]] || EchoAndLog A "$CN: Free space required on /boot filesystem: ${v_Min_Boot_free_m_required}MB but  Available is  ${CN_Boot_free_m}MB"
done <<< "${v_AllCn_IP_n_boot_free_m}"


EchoAndLog LINE; EchoAndLog C " Currently mounted filesystem from   compute node" ; EchoAndLog EC "$c_CNCHECK5"
ExpectTool $ip $passwd $c_CNCHECK5
EchoAndLog LINE; EchoAndLog C " fstab entry   compute node" ; EchoAndLog EC "$c_CNCHECK6"
ExpectTool $ip $passwd $c_CNCHECK6
EchoAndLog LINE; EchoAndLog C " ListVMs from  all compute node" ; EchoAndLog EC "$c_CNCHECK7"
>${gc_tmptmp}/listvms 
ExpectTool $ip $passwd $c_CNCHECK7   | tee -a ${gc_tmptmp}/listvms 
EchoAndLog LINE; EchoAndLog C " xm list from   compute node" ; EchoAndLog EC "$c_CNCHECK8"
ExpectTool $ip $passwd $c_CNCHECK8 
EchoAndLog LINE; EchoAndLog C " server uptime  from  all compute node" ; EchoAndLog EC "$c_CNCHECK9"
ExpectTool $ip $passwd $c_CNCHECK9

if [[ $1 != selectednode ]]; then 
EchoAndLog LINE; EchoAndLog C " listing EC and PC configuration file" ; EchoAndLog EC "$c_CNCHECK10"
ExpectTool $ip $passwd $c_CNCHECK10

fi

}
#-------------------------------------------------------------------
#PROCEDURE    : ZFSHeadDetail
#DESCRIPTION  :  this is to collect ZFS head detail and analysis
#-------------------------------------------------------------------
ZFSHeadDetail(){            #--- this to collect and analysis the ZFS head
EchoAndLog LINE;grep ZFS-Storage-Head $gv_componentlistfile >/dev/null
if [[ ! $(cat $gv_componentlistfile) =~  ZFS-Storage-Head ]];then  EchoAndLog A "ZFS-Storage-Head detail not collected due to wrong passwd";return 1; fi

EchoAndLog LINE;EchoAndLog I "Started collecting information from ZFS-Storage-Head \n"
    if [[ $gv_sysenv == "Virtual" ]];then
            EchoAndLog LINE ; EchoAndLog I " Collecting O2CB status from all compute node";EchoAndLog EC "$c_ZFSCHECK13"
            v_output=$(ExpectTool $gv_argument2 $CNP $c_ZFSCHECK13) ; v_output=$(echo "$v_output" | grep : );EchoAndLog "$v_output"
            v_output=$(echo "$v_output" | egrep 'O2CB|threshold' | grep -v Online | grep -v 43201 | grep -v Active | grep -v  Nodes)
            if [[ -n $v_output  ]]
            then
                    EchoAndLog E "O2CB Status  has wrong value  on : "
                    EchoAndLog E "$v_output"
            fi
            
    fi

for i in $(grep ZFS-Storage-Head $gv_componentlistfile |grep -v Enter| awk '{print $2}')
do
local ip=$i
local passwd=$ZFSHEADP
EchoAndLog LINE; EchoAndLog C "configuration cluster show from the storage head $i ";EchoAndLog EC $c_ZFSCHECK1;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK1);EchoAndLog "$v_output"
[[ ! $v_output =~ ("description = Ready") ]] && echo  E "Ready head not found on the ZFS-Storage-Head $ip" 
EchoAndLog LINE; EchoAndLog C " problems show from the storage head $i ";EchoAndLog EC $c_ZFSCHECK2;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK2);EchoAndLog "$v_output"
[[ $v_output =~ "problem-" ]] && EchoAndLog A "found problem on maintenance problem show on $i" 
EchoAndLog LINE; EchoAndLog C "system updates list  from the storage head $i ";EchoAndLog EC $c_ZFSCHECK3;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK3);EchoAndLog "$v_output"
uplist=$(echo "$v_output" | grep -c previous);[[ $uplist -ge  2 ]] && EchoAndLog E " $ip Contains 2 or more available software versions, you can clear before  patching "
[[ $v_output =~ "Hardware Updates" ]] && EchoAndLog E "Hardware updates going on $i "
EchoAndLog LINE; EchoAndLog C "NFS service status  from the storage head $i ";EchoAndLog EC $c_ZFSCHECK4;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK4);EchoAndLog "$v_output"
[[ ! $v_output =~ "<status> = online" ]] && EchoAndLog E "NFS service is not online on $i "
EchoAndLog LINE; EchoAndLog C "HTTP service status  from the storage head $i ";EchoAndLog EC $c_ZFSCHECK5;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK5);EchoAndLog "$v_output"
[[ ! $v_output =~ "<status> = online" ]] && EchoAndLog E "HTTP service is not online on $i "
EchoAndLog LINE; EchoAndLog C "analytics settings  from the storage head $i ";EchoAndLog EC $c_ZFSCHECK6;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK6);EchoAndLog "$v_output"
[[ ! $v_output =~ "retain_hour_data" ]] && EchoAndLog E "Retain hour data is not there. correct it before patching"
EchoAndLog LINE; EchoAndLog C "MEMORY status  from the storage head $i ";EchoAndLog EC $c_ZFSCHECK7;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK7);EchoAndLog "$v_output"
uplist=$(echo "$v_output" | grep -i memory- | egrep -vwc  'ok|absent|^$');[[ $uplist -gt 0 ]] && EchoAndLog A "MEMORY issue found on $i"
EchoAndLog LINE; EchoAndLog C "CPU status  from the storage head $i ";EchoAndLog EC $c_ZFSCHECK8;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK8);EchoAndLog "$v_output"
uplist=$(echo "$v_output" | grep cpu- | grep -vcw ok);[[ $uplist -gt 0 ]] && EchoAndLog A "CPU  issue found on $i"
EchoAndLog LINE; EchoAndLog C "FAN status  from the storage head $i ";EchoAndLog EC $c_ZFSCHECK9;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK9);EchoAndLog "$v_output"
uplist=$(echo "$v_output" | grep fan- | egrep -vcw 'ok|absent|^$');[[ $uplist -gt 0 ]] && EchoAndLog A "FAN   issue found on $i"
EchoAndLog LINE; EchoAndLog C "DISK status from the storage head $i ";EchoAndLog EC $c_ZFSCHECK10;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK10);EchoAndLog "$v_output"
uplist=$(echo "$v_output" | grep disk- | egrep -vcw 'ok|absent|^$');[[ $uplist -gt 0 ]] && EchoAndLog A "DISK  issue found on $i"
EchoAndLog LINE; EchoAndLog C "configuration version show from the storage head $i ";EchoAndLog EC $c_ZFSCHECK11;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK11);EchoAndLog "$v_output"
[[ ! $v_output =~ "Appliance Version: 2013" ]] && EchoAndLog A "Failed to collect the current version of ZFS-Storage-Head $i "
EchoAndLog LINE; EchoAndLog C "IB card firmware version from the storage head $i ";EchoAndLog EC $c_ZFSCHECK12;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK12);EchoAndLog "$v_output"
if [[ "$v_output" =~ 375-3696 ]]; then [[ ! $v_output =~ '2.11.2010' ]] && EchoAndLog E "ZFS-Storage-Head: $ip Need to install Latest IB-Card firmware for 375-3696 - Latest version 2.11.2010  " ; fi
if [[ "$v_output" =~ 7046442 ]]; then [[ ! $v_output =~ '2.35.5532' ]] && EchoAndLog E "ZFS-Storage-Head: $ip Need to install Latest IB-Card firmware for 7046442 -  Latest verison = 2.35.5532 " ; fi

done
}
#-------------------------------------------------------------------
#PROCEDURE    : IBSwitchDetail
#DESCRIPTION  :  this is to collect IB switch  and spine switch detail  and analysis
#------------------------------------------------------------------- 
IBSwitchDetail(){           #---- this to collect and analysis the IB switch and spine switch
if [[ "$1" == "Spine-Switch" ]] ;then   
    v_switch=NM2-36p-IB-Switch;local passwd=$SSP;local LSM="Local SM not enabled"
else  
    v_switch=NM2-GW-IB-Switch;local passwd=$GWP;local LSM="Local SM enabled and running" 
fi

[[ ! $(cat ${gc_tmpdir}/componentlist) =~ $v_switch ]] && return 0 

if [[ ! $(cat $gv_componentlistfile) =~  "$v_switch" ]];then  EchoAndLog A "$1 $v_switch detail not collected due to wrong passwd";return 1; fi

EchoAndLog LINE;EchoAndLog I " Staring data collection for  $1 "



if [[ "$1" != "Spine-Switch" ]]
then
>${gc_tmpdir}/ibswitches
EchoAndLog LINE;EchoAndLog C "list of switch connected to node";EchoAndLog EC $c_SWCHECK1; ExpectTool $gv_argument2 $CNP $c_SWCHECK1 |tee -a ${gc_tmpdir}/ibswitches
EchoAndLog LINE;EchoAndLog C " ibstat from all nodes";EchoAndLog EC $c_SWCHECK2;v_output=$(ExpectTool $gv_argument2 $CNP $c_SWCHECK2);EchoAndLog "$v_output";v_output=`echo "$v_output" | grep :`
ERR=$(echo "$v_output" | egrep -v 'LinkUp|Active') ;[[ $ERR ]] && EchoAndLog A "issue found on ibstat verfiy it  on compute node"
EchoAndLog LINE;EchoAndLog C " connected mode  from all nodes";EchoAndLog EC $c_SWCHECK3;v_output=$(ExpectTool $gv_argument2 $CNP $c_SWCHECK3);EchoAndLog "$v_output"
ERR=$(echo "$v_output" | grep ': CONNECTED_MODE=' | grep -v yes) ;[[ $ERR ]] && EchoAndLog E "connected mode is not set to yes for some compute node "
EchoAndLog LINE;EchoAndLog C " openibd start up setting  from all nodes";EchoAndLog EC $c_SWCHECK4;v_output=$(ExpectTool $gv_argument2 $CNP $c_SWCHECK4);EchoAndLog "$v_output"
ERR=$(echo "$v_output" |egrep '2:off|3:off|4:off|5:off');[[ $ERR ]] && EchoAndLog E  "openbid must be ON on  2,3,4,5 runlevel. but on some compute node it off "
fi


for i in $(grep $v_switch $gv_componentlistfile |grep -v Enter | awk '{print $2}')
do
local ip=$i
EchoAndLog LINE;EchoAndLog I " Starting  data collection for  $1 on  $ip  "
EchoAndLog LINE;EchoAndLog C " version detail from $ip ";EchoAndLog EC $c_SWCHECK5;v_output=$(ExpectTool $ip $passwd $c_SWCHECK5);EchoAndLog "$v_output" | tee -a ${gc_tmptmp}/${i}:version-getmaster-priority
vnumber=$(echo "$v_output" | grep 'SUN.*version' | awk -F ":" '{print $2}' | sed "s/\.//g" | sed "s/\-//g");
VNUMBER=$(echo "$v_output" | grep 'SUN.*version' | awk -F ":" '{print $2}' )
if [[ $vnumber -lt 2227 ]]; then
        EchoAndLog E " Switch: $1 $ip  need to install the patch 2.2.4-3 (p25747868) and then  use -d nm2_2.2.7-2_descriptor.py "   
    elif [[ $vnumber -lt 2272 ]];   then
        EchoAndLog I " Switch: $1 $ip  need to install the patch descriptor -d nm2_2.2.7-2_descriptor.py"
    elif [[ $vnumber -ge 2272 ]] && [[ $vnumber -lt $SWITCHVERSION ]];  then
        EchoAndLog I " Switch: $1 $ip No descriptor need while patching"
    else
        EchoAndLog I "Switch: $1 $ip upgrade not requried. Its already in $VNUMBER "
fi

EchoAndLog LINE;EchoAndLog C " getmaster detail from $ip";EchoAndLog EC $c_SWCHECK6;v_output=$(ExpectTool $ip $passwd $c_SWCHECK6);EchoAndLog "$v_output" | tee -a ${gc_tmptmp}/${i}:version-getmaster-priority
[[ ! $v_output =~ $LSM ]] && echo  E "getmaster of $1 - $ip not showing $LSM"
if [[ "$1" != "Spine-Switch" ]] && [[ $v_output =~ $LSM ]]; then echo "$v_output" | grep "$LSM" | egrep -i "MASTER|stand">/dev/null;[[ $? -ne 0 ]] && echo  E "$LSM  but state is not master/standy" ;fi
[[ ! $v_output =~ $LSM ]] && echo  E "getmaster of $1 - $ip not showing $LSM"
EchoAndLog LINE;EchoAndLog C " subnet manager priority  detail from $ip";EchoAndLog EC $c_SWCHECK7;v_output=$(ExpectTool $ip $passwd $c_SWCHECK7);EchoAndLog "$v_output" | tee -a ${gc_tmptmp}/${i}:version-getmaster-priority
ROUT=$(echo "$v_output" |egrep 'smpriority|controlled_handover'|tr -d "[:punct:]|[:space:]")
v_output=$(ExpectTool $ip $passwd "cat  /etc/opensm/opensm.conf")
COUT=$(echo "$v_output" |  egrep -i  'sm_priority|controlled_handover' |tr -d "[:punct:]|[:space:]")
[[ ! $ROUT =~ $COUT ]] && EchoAndLog E " $1  $ip smpriority/controlled_handover is mismatch with the confirmation file /etc/opensm/opensm.conf"
EchoAndLog LINE;EchoAndLog C " smnodes list  detail from $ip";EchoAndLog EC $c_SWCHECK8;v_output=$(ExpectTool $ip $passwd $c_SWCHECK8);EchoAndLog "$v_output"

if [[ "$1" != "Spine-Switch" ]] ; then
EchoAndLog LINE;EchoAndLog C " partconfigd  service status detail from $ip";EchoAndLog EC $c_SWCHECK9;v_output=$(ExpectTool $ip $passwd $c_SWCHECK9);EchoAndLog "$v_output"
[[ ! $v_output =~ [Pp][Ii][Dd] ]] && EchoAndLog  E " partconfigd service is not running on $1 $ip"
EchoAndLog LINE;EchoAndLog C " opensmd service status  detail from $ip";EchoAndLog EC $c_SWCHECK10;v_output=$(ExpectTool $ip $passwd $c_SWCHECK10);EchoAndLog "$v_output"
[[ ! $v_output =~ [Pp][Ii][Dd] ]] && EchoAndLog   E " opensmd  service is not running on $1 $ip"
EchoAndLog LINE;EchoAndLog C " bxm service status detail from $ip";EchoAndLog EC $c_SWCHECK11;v_output=$(ExpectTool $ip $passwd $c_SWCHECK11);EchoAndLog "$v_output"
[[ ! $v_output =~ [Pp][Ii][Dd] ]] && EchoAndLog  E " bxm service is not running on $1 $ip"
fi

EchoAndLog LINE;EchoAndLog C " Memory  detail  from $ip ";EchoAndLog EC $c_SWCHECK12;v_output=$(ExpectTool $ip $passwd $c_SWCHECK12);EchoAndLog "$v_output"
local ibmemory=$(echo "$v_output" | grep "buffers/cache" | awk '{print $4}');ValueChecker $1 $i Memory 200MB ${ibmemory}MB
EchoAndLog LINE;EchoAndLog C " vlan detail from $ip";EchoAndLog EC $c_SWCHECK13;v_output=$(ExpectTool $ip $passwd $c_SWCHECK13);EchoAndLog "$v_output"
EchoAndLog LINE;EchoAndLog C " /var filesystem size detail from $ip";EchoAndLog EC $c_SWCHECK14;v_output=$(ExpectTool $ip $passwd $c_SWCHECK14);EchoAndLog "$v_output"
local varsize=$(echo "$v_output" |grep dev  | awk '{print $4}'); ValueChecker $1 $i /var/log 10MB ${varsize}MB
EchoAndLog LINE;EchoAndLog C " lumain.log file size  detail from $ip";EchoAndLog EC $c_SWCHECK15;v_output=$(ExpectTool $ip $passwd $c_SWCHECK15);EchoAndLog "$v_output"
EchoAndLog LINE;EchoAndLog C " hwclock detail from $ip";EchoAndLog EC $c_SWCHECK16;v_output=$(ExpectTool $ip $passwd $c_SWCHECK16);EchoAndLog "$v_output"
[[ ! $v_output =~ seconds ]] && EchoAndLog E "unable to get the hwclock output from $1 $ip"
EchoAndLog LINE;EchoAndLog C " aggregation  detail from $ip";EchoAndLog EC $c_SWCHECK17;v_output=$(ExpectTool $ip $passwd $c_SWCHECK17);EchoAndLog "$v_output"
ERR=$(echo "$v_output" | egrep -v 'Members|--'| grep -i lag);[[ $ERR ]] && EchoAndLog E "CRITICAL  Link aggregation found take backup of /conf/lag.conf  file"
EchoAndLog LINE;EchoAndLog C " unhealthy sensor  detail from $ip";EchoAndLog EC $c_SWCHECK18;v_output=$(ExpectTool $ip $passwd $c_SWCHECK18);EchoAndLog "$v_output"
[[ !  $v_output =~ "No unhealthy sensors" ]] && EchoAndLog A "unhealthy sensors found on $1 $ip"
EchoAndLog LINE;EchoAndLog C " environment test    detail from $ip";EchoAndLog EC $c_SWCHECK19;v_output=$(ExpectTool $ip $passwd $c_SWCHECK19);EchoAndLog "$v_output"
[[ ! $v_output =~ "Environment test PASSED" ]] && EchoAndLog A "Environment test  failed on $1 $ip"
EchoAndLog LINE;EchoAndLog C " listing links up   detail from $ip";EchoAndLog EC $c_SWCHECK20;v_output=$(ExpectTool $ip $passwd $c_SWCHECK20);EchoAndLog "$v_output"
EchoAndLog LINE;EchoAndLog C " show gateway ports   detail from $ip";EchoAndLog EC $c_SWCHECK21;v_output=$(ExpectTool $ip $passwd $c_SWCHECK21);EchoAndLog "$v_output"
EchoAndLog LINE;EchoAndLog C " show vnics   detail from $ip";EchoAndLog EC $c_SWCHECK22;v_output=$(ExpectTool $ip $passwd $c_SWCHECK22);EchoAndLog "$v_output"
done

}
#-------------------------------------------------------------------
#PROCEDURE    : CollectAllSwitchDetail
#DESCRIPTION  :  this is to collect and compare the exalogic switch with exadata switch
#-------------------------------------------------------------------
CollectAllSwitchDetail(){   #--- this to collect all switch connected to the server and check priority
EchoAndLog LINE
if [[ ! -e ${gc_tmpdir}/ibswitches ]]; then  EchoAndLog LINE;EchoAndLog C "list of switch connected to node";EchoAndLog EC $c_SWCHECK1; ExpectTool $gv_argument2 $CNP $c_SWCHECK1 |tee -a ${gc_tmpdir}/ibswitches;fi
local rackconfigurationcswitch=$(egrep -c "NM2-36p-IB-Switch|NM2-GW-IB-Switch" $gv_componentlistfile)
local totalnumberofswitch=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' ${gc_tmpdir}/ibswitches | grep -c -v $gv_argument2)
[[ $rackconfigurationcswitch -eq  $totalnumberofswitch ]] && return 
    
EchoAndLog LINE;EchoAndLog I " Going to collect All Switch  information  including exadata switch"

local collectedswitch=$(ls ${gc_tmptmp}/*:version-getmaster-priority | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' |uniq)
local totalswitch=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' ${gc_tmpdir}/ibswitches | grep -v $gv_argument2  | uniq)
local exadataswitchip="$totalswitch"
for i in $collectedswitch;do exadataswitchip=$(echo "$exadataswitchip" | grep -v $i ); done
local ibswitchesip=$(grep NM2-GW-IB-Switch $gv_componentlistfile  |grep -v Enter | awk '{print $2}')


for i in $exadataswitchip;do
    forlooptocollectdetail(){ 
    local ip=$1; local passwd=$2
        v_output=$(ExapatchExpect $ip $passwd $c_SWCHECK5 )
        gv_ExitCode=$?;[[ $gv_ExitCode -ne 0  ]] && return $gv_ExitCode
        EchoAndLog "$v_output" | tee -a ${gc_tmptmp}/${i}:version-getmaster-priority
        EchoAndLog LINE;EchoAndLog C " getmaster detail from $ip";EchoAndLog EC $c_SWCHECK6;ExapatchExpect $ip $passwd $c_SWCHECK6| tee -a ${gc_tmptmp}/${i}:version-getmaster-priority
        EchoAndLog LINE;EchoAndLog C " subnet manager priority  detail from $ip";EchoAndLog EC $c_SWCHECK7;ExapatchExpect $ip $passwd $c_SWCHECK7 | tee -a ${gc_tmptmp}/${i}:version-getmaster-priority
        return 0
    }
    EchoAndLog LINE;EchoAndLog C " Version detail from $i ";EchoAndLog EC $c_SWCHECK5;
    forlooptocollectdetail $i $GWP ;gv_ExitCode=$?
    if [[ $gv_ExitCode -eq 8 ]] ;then forlooptocollectdetail $i $SSP ;gv_ExitCode=$?;fi
    if [[ $gv_ExitCode -eq 8 ]] ;then forlooptocollectdetail $i $DERP;gv_ExitCode=$?;fi
    [[ $gv_ExitCode -eq 8 ]] && EchoAndLog A "Not able to collect information from exadataswitch $i. due to wrong password "
    [[ $gv_ExitCode -eq 9 ]]&& EchoAndLog E "Not able to collect information from exadataswitch $i. due to not reachable from CN01  "
done

local totalcollectedswitch=$(ls ${gc_tmptmp}/*:version-getmaster-priority |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'|uniq |grep -c -v $gv_argument2  )
if [[ $totalcollectedswitch -ne $totalnumberofswitch ]] ; then EchoAndLog  A "Exadata switch  found, but failed to analysis log due Above reason .";return 6;fi


EchoAndLog LINE; EchoAndLog I " Verifying the exadataswitch priority with IB switch & controlled_handover status "
getpriority(){
     grep -v list ${gc_tmptmp}/${1}:version-getmaster-priority  | grep -i smpriority | awk '{print $2}'
}

for i in $ibswitchesip;do let value=$value+1 ;local ibswitch${value}priority=$(getpriority $i); done;unset value
[[ $ibswitch1priority -ne  $ibswitch2priority ]] && EchoAndLog E "Exalogic IB switch priority's  are not same" || local ibswitchpriority=$ibswitch2priority

for i in  $exadataswitchip;do let value=$value+1; local exadataswitch${value}priority=$(getpriority $i);done ;unset value
[[ $ibswitch1priority -le $exadataswitch2priority ]] && EchoAndLog E "Exalogic IB switch priority should be higher then Exadataswitch "

for i in  $exadataswitchip;do 
    c=$(grep -w "controlled_handover TRUE" ${gc_tmptmp}/${i}:version-getmaster-priority )
    [[ $? -eq 0 ]]&& EchoAndLog E  "Exadata Switch  has controlled_handover as  TRUE on $i. It suppose to be FALSE"
done


}
#-------------------------------------------------------------------
#PROCEDURE    : CollectCheckAuthOutput
#DESCRIPTION  : this is collect the checkAuthentication output
#-------------------------------------------------------------------
CollectCheckAuthOutput(){   #--- this is to collect check authentication output

local v_checkauthentication="/exalogic-lctools/bin/exapatch -a checkAuthentication"
EchoAndLog LINE; EchoAndLog C " Check Authentication output from Compompute node ";EchoAndLog EC $v_checkauthentication;v_output=$(ExpectTool $gv_argument2 $CNP $v_checkauthentication);EchoAndLog "$v_output" 
fc=$(echo "$v_output" | grep -v -i pdu | grep -c -e  Failed )
if [[ $fc -gt 1 ]];then
YesOrNo  "Check Authentication failed for some component. Continuing script will fail's for that component !! \n \n Still you want to continue ? "
[[ $? -eq  0 ]] &&  EchoAndLog I "Proceding futher" || Exit 8 
fi
}
#-------------------------------------------------------------------
#PROCEDURE    : OvmmServerDetail
#DESCRIPTION  : this to collect the ovmm server detail and analysis
#-------------------------------------------------------------------
OvmmServerDetail(){         #--- this if checking OVMM detail
[[ $gv_sysenv == "Linux" ]] && return 2
if [[ ! $(cat $gv_componentlistfile) =~  "$vServer-EC-OVMM" ]];then  EchoAndLog A "Not able to collect  OVMM detail . Due to OVMM password was wrong or OVMM  not running while starting  this script ";return 1; fi

local ovmip=$(grep vServer-EC-OVMM  $gv_componentlistfile |  awk '{print $2}')

CheckWebLogicPassword

EchoAndLog LINE; EchoAndLog C " root filesystem size of OVMM server $ovmip ";EchoAndLog EC $c_OVMMCHECK2; v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK2);EchoAndLog "$v_output" 
cused=$(echo "$v_output" | grep dev  | awk '{print $5}' | tr -d "[:punct:]")
let "cavail=100-$cused"
[[ $cused -ge 60 ]] && EchoAndLog A "root filesystem of OVMM server $ovmip need 40% free space. but there is only $cavail % free"

EchoAndLog LINE; EchoAndLog C " checking whether hostname alias is ther or not on OVMM server for PC1 and PC2 ";EchoAndLog EC $c_OVMMCHECK3;v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK3);EchoAndLog "$v_output"
[[ ! $v_output =~ ecu-pc-IPoIB-admin-primary ]] && EchoAndLog E "ecu-pc-IPoIB-admin-primary entry missing on /etc/hosts file of  OVMM server $ovmip. Skiping  other  OVMM check " 
[[ ! $v_output =~ ecu-pc-IPoIB-admin-secondary ]] && EchoAndLog E "ecu-pc-IPoIB-admin-secondary entry missing on /etc/hosts file of  OVMM server $ovmip.Skiping  other OVMM check"
[[ ! $v_output =~ ecu-pc-IPoIB-admin-primary ]] && return
[[ ! $v_output =~ ecu-pc-IPoIB-admin-secondary ]] && return

EchoAndLog LINE; EchoAndLog C " verfiy passwd less ssh between  OVMM & PC1";EchoAndLog EC $c_OVMMCHECK4; v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK4);EchoAndLog "$v_output"
[[ ! $v_output =~ average ]]  && EchoAndLog E "Password less ssh between  OVMM & PC1 is no there. correct it"

EchoAndLog LINE; EchoAndLog C " verfiy passwd less ssh between  OVMM & PC2";EchoAndLog EC $c_OVMMCHECK5; v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK5);EchoAndLog "$v_output"
[[ ! $v_output =~ average ]]  && EchoAndLog E "Password less ssh between  OVMM & PC2 is no there. correct it"


}
#-------------------------------------------------------------------
#PROCEDURE    : ValidateRackPhython
#DESCRIPTION  :  this to collect the getVersion , refreshHistory and pre-checkrack using the exaptch python script
#-------------------------------------------------------------------
ValidateRackPhython(){      #--- this is to run expatch precheckrack command

local v_getversion="/exalogic-lctools/bin/exapatch -a getVersion"
local v_refreshhistory="/exalogic-lctools/bin/exapatch -a refreshHistory"
local v_prepatchcheck="/exalogic-lctools/bin/exapatch -a prePatchCheck"

EchoAndLog LINE; EchoAndLog C "version from all component";EchoAndLog EC $v_getversion;v_output=$(ExpectToolNB $gv_argument2 $CNP $v_getversion)
[[  "$v_output" =~ 'Connection to ' ]] && EchoAndLog "$v_output" || ExpectToolNB $gv_argument2 $CNP $v_getversion
EchoAndLog LINE; EchoAndLog C "refreshing the rack histroy ";EchoAndLog EC $v_refreshhistory;ExpectToolNB $gv_argument2 $CNP $v_refreshhistory
EchoAndLog LINE; EchoAndLog C " python precheckrack  script ";EchoAndLog EC $v_prepatchcheck;EmptyNB;ExpectToolNB $gv_argument2 $CNP $v_prepatchcheck | tee -a $gc_tmpfileNB
strings $gc_tmpfileNB >${gc_tmptmp}/exapatchprepatchcheck
local v_output=$(grep "Logging to file" ${gc_tmptmp}/exapatchprepatchcheck | tail -1| awk '{print $4}')
CMD="scp root@${gv_argument2}:$v_output  ${gc_tmpdir}/ "
local exachklog=$(echo $v_output | awk -F / '{print $4}')
ExpectToolNB $gv_argument2 $CNP $CMD
\cp ${gc_tmpdir}/$exachklog ${gv_currentpwd}/${CN01}_$exachklog

}

#-------------------------------------------------------------------
#PROCEDURE    : ConvertLog
#DESCRIPTION  : convert log to standard format
#-------------------------------------------------------------------
ConvertLog(){               #-- this is to convert log into startand format
EchoAndLog 
EchoAndLog I "LogFile:  $gv_logfile \n "
if [[ -e $gv_logfile ]]
then
    SLOGFILE="${gv_currentpwd}/${cuname}_${srnumber}_${PSUNAME}_${gc_argument1}_${CN01}_${gv_datetime}.out"
    cat  $gv_logfile >  $gc_tmpfile
    awk '/LOGTOUPLOADSTARTHERE/,/LOGTOUPLOADSTOPHERE/' $gc_tmpfile | grep -v LOGTOUPLOAD >$SLOGFILE
    sed -i -e 's/\r//g' $SLOGFILE
    EchoAndLog I  "Formated Log File : $SLOGFILE  "
    EchoAndLog LINE
fi
}
#-------------------------------------------------------------------
#PROCEDURE    : SendLogToPortal
#DESCRIPTION  : send log to oracle portal
#-------------------------------------------------------------------
SendLogToPortal(){          #-- this it send log to portal 

if [[ -f /usr/bin/nc ]]; then       
        /usr/bin/nc -w 3 -z transport.oracle.com 443  >/dev/null 2>&1
        local connectioncheck=$?
        [[ $connectioncheck -ne 0 ]] && EchoAndLog E " Not able to connect to  oracle.com. So Log cannot be upload from Jumpgate"
        [[ $connectioncheck -ne 0 ]] && return      
fi

if [[ -z $1 ]]
then
    ReadPassword P " Enter the file name : ";local filepath=$v_enteredpassword
    if [[ -e $filepath ]] ;then 
        ReadPassword P " Enter  the SR-Number : ";local Srnumber=$v_enteredpassword
        local srnumber=$(echo $Srnumber | tr -d "[:blank:]")
        ReadPassword P " Enter your Email ID: ";local emailid=$v_enteredpassword
        curl -T $filepath  -u $emailid https://transport.oracle.com/upload/issue/${srnumber}/
    else
        EchoAndLog E "File name $filepath mention is not found . provide correct file name or obsolete  file path \n"
        SendLogToPortal 
    fi 
fi

if [[ $RUNENV == "jumpgate" ]]  && [[ $gc_argument1 == "pre-checkrack" ]]
    then
        YesOrNo " Shall i upload the Output to SR ? "
        if [[ $? -eq 0 ]]
        then 
            ReadPassword P  "Enter your Email ID: ";local emailid=$v_enteredpassword
            curl -T $1  -u $emailid  https://transport.oracle.com/upload/issue/${srnumber}/
        fi
fi
}
#-------------------------------------------------------------------
#PROCEDURE    : EndDisplaySummary
#DESCRIPTION  : display the precheck summary
#-------------------------------------------------------------------
EndDisplaySummary(){        #-- to display summary
productname=$(ExpectTool $gv_argument2 $CNP 'dmidecode' | grep -i 'Product Name' | awk -F \: '{print $2}'  | awk 'NR==1' )
v_output=$(grep Compute-Node ${gc_tmpdir}/componentlist | wc -l)
case $v_output in
    4)  rcsize="Eighth ($v_output Nodes)" ;;
    8)  rcsize="Quarter ($v_output Nodes)" ;;
    1?) rcsize="Half ($v_output Nodes)" ;;
    3?) rcsize="Full ($v_output Nodes)" ;;
    *)  rcsize="Not able to say" ;;
esac
EchoAndLog DLINE;EchoAndLog "\t Customer Name \t : $cuname \n\t SR Number \t : $srnumber \n\t Compute node1 \t : $CN01 \n\t Rack Size \t : $rcsize \n\t Sys Type \t : $gv_sysenv \n\t PSU-NAME \t : $PSUNAME \n\t PSU Number \t : $gv_patchnumber \n\t Patch path \t : $gv_patchlocation \n\t Product \t :  $productname"
[[ $RUNENV == jumpgate ]] && EchoAndLog "\t CTA Name \t : $(hostname) "
EchoAndLog  "\n\n\n **************************************************************************\n Following things found. ERROR need to fix while patching. ATTENTION need to fix by customer \n "

 cp ${gc_tmptmp}/exapatchprepatchcheck $gv_currentpwd/exapatchprepatchcheck_$gv_datetime
(
grep ERROR $gc_message ; EchoAndLog "\n";grep ATTENTION $gc_message
EchoAndLog "\n exapatch  -a precheckrack  errors: \n " 
cat ${gc_tmptmp}/exapatchprepatchcheck | grep ERROR | grep -i -v  -e backup -e 'more available software versions'
)|tee -a $gv_currentpwd/message_${gv_argument2}_$gv_datetime 
}

#-------------------------------------------------------------------
#PROCEDURE    : ExabrBackupCheck
#INPUT:  will be arguemnt -- <component> <component-IP>
#DESCRIPTION  :  used to check the exabr backup status of the given component
#-------------------------------------------------------------------
ExabrBackupCheck(){         #-- this to check exbrbackup of the component-- Argument components  components-IP

trap "TrapCtrlC" 2  
components=$1;ip=$2
CMD="/exalogic-lctools/bin/exabr list -v $ip "
ExpectToolNB $gv_argument2 $CNP $CMD >$gc_tmpfileNB 
strings $gc_tmpfileNB > $gc_tmpfile
bkpdate=$(awk  "/Status: OK/ {getline;print;exit 0 }" $gc_tmpfile  | awk '{print $2}' )
[[ -z $bkpdate ]] && bkpdate=20110825
Bdate=$(date -d $bkpdate +"%Y%m%d")
Tdate=$(date +%Y%m%d )
let "Cdate=Tdate-7"
if [[ -z $bkpdate ]] || [[ $Bdate -lt $Cdate ]]
then
    EchoAndLog  E " $components $ip  Exabr backup was  more than 7 days "
    EXABRBACKUPSTAUS="failed"
    EXABRBACKUPFAILEDIP="$ip"
else
    EchoAndLog  I " $components $ip Exabr backup was taken less than  7 days days "
fi

}

#-------------------------------------------------------------------
#PROCEDURE    : ECVserverStart
#DESCRIPTION  : this is to start exalogic control virtual server and check services status
#-------------------------------------------------------------------
ECVserverStart(){           #--- this to start exalogic control virtual server and check proxyadm status
[[ $gv_sysenv == "Linux" ]] && return 2
local ovmip=$(grep vServer-EC-OVMM  $gv_componentlistfile |  awk '{print $2}')
pc1ip=$(grep vServer-EC-EMOC-PC  $gv_componentlistfile  | awk '{print $2}'|head -1)
pc2ip=$(grep vServer-EC-EMOC-PC  $gv_componentlistfile  | awk '{print $2}'|tail -1)

SATADMSTARTER(){    #-- this to start satadm if it not start after server startup of  4 minutes
    while true;do
    CMD="ping $ovmip -c 1 -w 5 "
    v_output=$(ExpectTool $gv_argument2 $CNP $CMD)
    [[ $v_output =~ "100% packet loss" ]] &&    sleep 20  || break
    done
    sleep 30
    v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK8)
    [[ !$v_output =~ 'online' ]] && sleep 240 || return
    v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK8)
    if [[ ! $v_output =~ 'online' ]];then 
        EchoAndLog I "found satadm service is still down. server get booted before  4 minutes. tring to  start the services  ";EchoAndLog EC $c_OVMMCHECK8start
        ExpectTool $ovmip $OVMMECP $c_OVMMCHECK8start ;sleep 10
        v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK8);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'online' ]];then
            EchoAndLog A "Failed to start satadm service . start it manually" 
            return
        fi
    fi
        
}
    SATADMSTARTER & 
    EchoAndLog I "Going to start EC vServers";EchoAndLog EC "$c_OVMMCHECK14"
    ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK14  #---  ecvserversstartup
    EchoAndLog I " OVMM server started. will start next step in 2 minutes";SleepCount 120
    
    EchoAndLog LINE; EchoAndLog C " ovmm service status from OVMM server $ovmip ";EchoAndLog EC $c_OVMMCHECK6; v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK6);EchoAndLog "$v_output"
    if [[ ! $v_output =~ 'Oracle VM Manager is running' ]];then 
        EchoAndLog I "found OVMM service is down. tring to  start the services  ";EchoAndLog EC $c_OVMMCHECK6start
        ExpectTool $ovmip $OVMMECP  $c_OVMMCHECK6start ;sleep 10
        v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK6);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'Oracle VM Manager is running' ]];then
            EchoAndLog A "Failed to start OVMM service . start it manually"
            DoubleEnter
        fi
    fi
    
    EchoAndLog LINE; EchoAndLog C " ECADM  service status from OVMM server $ovmip ";EchoAndLog EC $c_OVMMCHECK7; v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK7);EchoAndLog "$v_output"
    if [[ ! $v_output =~ 'online' ]];then 
        EchoAndLog I "found ECADM service is down. tring to  start the services  ";EchoAndLog EC $c_OVMMCHECK7start
        ExpectTool $ovmip $OVMMECP  $c_OVMMCHECK7start ;sleep 10
        v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK7);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'online' ]];then
            EchoAndLog A "Failed to start ECADM service . start it manually" 
            DoubleEnter
        fi
    fi
    
    EchoAndLog LINE; EchoAndLog C " satadm  service status from OVMM server $ovmip ";EchoAndLog EC $c_OVMMCHECK8; v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK8);EchoAndLog "$v_output"
    if [[ ! $v_output =~ 'online' ]];then 
        EchoAndLog I "found satadm service is down. tring to  start the services  ";EchoAndLog EC $c_OVMMCHECK8start
        ExpectTool $ovmip $OVMMECP $c_OVMMCHECK8start ;sleep 10
        v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK8);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'online' ]];then
            EchoAndLog A "Failed to start satadm service . start it manually" 
            DoubleEnter
        fi
    fi
    EchoAndLog LINE; EchoAndLog C " proxyadm   service status from PC1 server $pc1ip ";EchoAndLog EC $c_OVMMCHECK9; v_output=$(ExpectTool  $pc1ip $OVMMPCP $c_OVMMCHECK9);EchoAndLog "$v_output"
    if [[ ! $v_output =~ 'online' ]];then 
        EchoAndLog I "found proxyadm service is down. tring to  start the services  on $pc1ip ";EchoAndLog EC $c_OVMMCHECK9start
        ExpectTool $pc1ip $OVMMPCP  $c_OVMMCHECK9start ;sleep 10
        v_output=$(ExpectTool  $pc1ip $OVMMPCP $c_OVMMCHECK9);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'online' ]];then
            EchoAndLog A "Failed to start proxyadm service on $pc1ip . start it manually"
            DoubleEnter
        fi
    fi
    
    EchoAndLog LINE; EchoAndLog C " proxyadm  service status from OVMM server $pc2ip ";EchoAndLog EC $c_OVMMCHECK9; v_output=$(ExpectTool  $pc2ip $OVMMPCP $c_OVMMCHECK9);EchoAndLog "$v_output"
    if [[ ! $v_output =~ 'online' ]];then 
        EchoAndLog I "found proxyadm service is down. tring to  start the services  on $pc2ip ";EchoAndLog EC $c_OVMMCHECK9start
        ExpectTool $pc2ip $OVMMPCP  $c_OVMMCHECK9start ;sleep 10
        v_output=$(ExpectTool  $pc2ip $OVMMPCP $c_OVMMCHECK9);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'online' ]];then
            EchoAndLog A "Failed to start proxyadm service $pc2ip . start it manually" 
            DoubleEnter
        fi
    fi

}
#-------------------------------------------------------------------
#PROCEDURE    : PatchECS
#DESCRIPTION  : patch the exalogic control stack
#-------------------------------------------------------------------
PatchECS(){                 #--- this for patching Exalogic control stack
[[ $gv_sysenv == "Linux" ]] && return 2
local ovmip=$(grep vServer-EC-OVMM  $gv_componentlistfile |  awk '{print $2}')
local  ECVMSRUNNING

if [[ -n $ovmip ]]
    then    

    v_output=$(ExpectTool $gv_argument2 $CNP $c_CNCHECK7)
    local ECVMS=$(echo "$v_output" | grep ExalogicControl | awk '{print $1}')
    v_output=$(ExpectTool $gv_argument2 $CNP $c_CNCHECK8 )
    unset ECVMSRUNNING
    for i in $ECVMS
    do
        [[ "$v_output" =~ i ]]&&  ECVMSRUNNING="yes" || ECVMSRUNNING="no"
    done
    
    if [[ $ECVMSRUNNING == "yes" ]];then
        EchoAndLog I "Going to shutdown the OVMM vServers. if it running - for taking backup";EchoAndLog EC $c_OVMMCHECK11
        EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK11 | tee -a $gc_tmpfileNB   #--- this is for ecvserversshutdown
    else
        EchoAndLog I "OVMM is already down. So proceeding next step"
    fi

    EchoAndLog I "Going to backup  the Control stack ";EchoAndLog EC $c_OVMMCHECK12
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK12 | tee -a $gc_tmpfileNB   #--- this if for backup control-stack
    EchoAndLog I "Will start next command in 61 Second"; SleepCount 61
    EchoAndLog I "Going to Veirfy  the control-stack backup status ";EchoAndLog EC $c_OVMMCHECK13
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK13  |tee -a $gc_tmpfileNB   #-- this if for list  control-stack backup
    grep -i minutes  $gc_tmpfileNB >/dev/null
    if [[ $? -ne 0 ]]
    then    
        EchoAndLog A " Control-Stack:  Looks exabr backup is not happen/Failed, please take it manually !!! "
        DoubleEnter
    fi
    
    ECVserverStart
    
    EmptyNB;CheckWebLogicPassword > $gc_tmpfileNB
    if [[ ! $(cat $gc_tmpfileNB) =~ RUNNING ]] 
    then
        EchoAndLog A "Weblogic password check failed.  do patching manually.  So far exabr backup taken and EC vServer started \n "
        Exit 9
    else
        EchoAndLog I "Weblogic password check Success"
    fi
    
    
    if [[ $WLP != $DERP ]]; then 
    local v_ovmmcustompass="su -c \\\" source /u01/app/oracle/Middleware/wlserver_10.3/server/bin/setWLSEnv.sh && sh /u01/app/oracle/ovm-manager-3/weblogic/wlconfig.sh weblogic '$WLP' \\\" oracle"

        EchoAndLog I "Weblogic password is not default one. So executing wlconfig.sh with custom password";EchoAndLog EC $v_ovmmcustompass
        EmptyNB;ExpectTool  $ovmip $OVMMECP $v_ovmmcustompass |tee -a $gc_tmpfileNB
        if [[ $(cat $gc_tmpfileNB) =~ "wlconfig.properties " ]] ; then 
            EchoAndLog I "Custom password updated on wlconfig.properties and wlkey.properties. " 
        else 
            EchoAndLog A "Failed to store custom password. Execute following command on EC Vserver - $OVMIP  and then   press yes twice.\n \n   $v_ovmmcustompass \n  "
            DoubleEnter     
        fi
    fi
    
    EchoAndLog I "All looks fine . Starting actual patch command";sleep 2;EchoAndLog line
    EchoAndLog I "Going to Start patching  the OVMM vServers";EchoAndLog EC $c_OVMMCHECK15
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK15 |tee -a $gc_tmpfileNB    #----  run the emoc  patch command.
    grep -i -e error -e failed $gc_tmpfileNB
    if [[ $? -eq 0 ]]
    then
        EchoAndLog  A " EMOC  patching  Failed. Please validate  it manually"
        DoubleEnter         
    fi

    if [[ $ECVMSRUNNING == "no" ]];then
        EchoAndLog I "OVMM server was not running before starting this EMOC patching. So shuting down";EchoAndLog EC $c_OVMMCHECK11
        EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK11 | tee -a $gc_tmpfileNB   #--- this is for ecvserversshutdown
        unset ECVMSRUNNING
    fi
    
else
    echo -e  "\n OVMM is not on rackconfiguration.py or server might be Physical \n"
fi
}
#-------------------------------------------------------------------
#PROCEDURE    : PostCheckECS
#DESCRIPTION  :  post check after patching the ECS/EMOC
#-------------------------------------------------------------------
PostCheckECS(){             #---  after patching the ECS CHECK 
PostCheckVtemplate
EchoAndLog "[ ATTENTION] Please login to OVMM & EMOC to check the version upgrade"
}

#-------------------------------------------------------------------
#PROCEDURE    : PatchSwitch
#DESCRIPTION  : Patch IB switch / Spine switch 
#-------------------------------------------------------------------
PatchSwitch(){              #--- this to patch the ib switch
    local EXABRBACKUPSTAUS;unset EXABRBACKUPSTAUS
    if [[ "$1" == "Spine-Switch" ]] ;then   
        v_switch=NM2-36p-IB-Switch;local passwd=$SSP;local LSM="Local SM not enabled";local PCOMPONENT="nm2-36p"
    else  
        v_switch=NM2-GW-IB-Switch;local passwd=$GWP;local LSM="Local SM enabled and running";local PCOMPONENT="nm2-gw" 
    fi
    
    #sed -i 's/.*ClientAliveInterval.*/ClientAliveInterval 60/g;s/.*ClientAliveCountMax.*/ClientAliveCountMax 3/g' 3 to modify the value
    #spshexec set /SP/cli timeout=1
    EchoAndLog I "Going to check exbrbackup of for $v_switch"
    for i in $(grep $v_switch $gv_componentlistfile |grep -v Enter | awk '{print $2}')
    do
        local ip=$i
        ExabrBackupCheck $v_switch  $ip 
    done
    
    local gv_datetime=(date +%F.%H.%M.%S)
    EchoAndLog I "Taking backup of /conf/lag.conf to /conf/lag.conf_$gv_datetime . if the file present $v_switch"
    for i in $(grep $v_switch $gv_componentlistfile |grep -v Enter | awk '{print $2}')
    do
        local ip=$i
        CMD='spshexec set /SP/cli timeout=1';ExpectTool $ip $passwd $CMD  >$gc_tmpfile  #-- this to set cli timeout to 1
        CMD="cp  -f /conf/lag.conf /conf/lag.conf_$gv_datetime " ; ExpectTool $ip $passwd  $CMD  >$gc_tmpfile #-- this is to take backup if /conf/lag.conf is there
    done

    
    if [[ $EXABRBACKUPSTAUS == failed ]] 
    then
        EchoAndLog  A " exbr backup is old. so taking exbr backup for $PCOMPONENT "
        CMD="/exalogic-lctools/bin/exabr backup all-ib";EchoAndLog EC "$CMD"
        EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB
        grep -i -e error -e failed $gc_tmpfileNB
        if [[ $? -eq 0 ]]
        then
            EchoAndLog  A " Switch: gc_EXABR Backup for the $PCOMPONENT Failed. Please take it manually"
            DoubleEnter 
            PatchSwitch $1 
            return
            
        else
            PatchSwitch $1 
            return
        fi  
    fi
    unset EXABRBACKUPSTAUS
    EchoAndLog LINE;EchoAndLog I "Running exapatch -a prePatchCheck $PCOMPONENT - it will take 10 minutes"
    CMD="/exalogic-lctools/bin/exapatch -a prePatchCheck $PCOMPONENT"
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB 
    grep -i -e error -e failed $gc_tmpfileNB
    if [[ $? -eq 0 ]]
    then
        EchoAndLog  A " Switch: prePatchCheck for the $PCOMPONENT Failed. Please validate  it manually"
        DoubleEnter 
    fi

    #---- patching of ibswitch start here
    local ibversion=$SWITCHVERSION
    for i in $(grep $v_switch $gv_componentlistfile |grep -v Enter | awk '{print $2}')
    do
        v_output=$(ExpectTool $i $passwd $c_SWCHECK5)
        ibversionf=$(echo "$v_output" | grep -i 'SUN.*version' | awk -F ":" '{print $2}' | sed "s/\.//g" | sed "s/\-//g")
        IBCURRENTVERSIONF=$(echo "$v_output" | grep -i 'SUN.*version'  | awk -F ":" '{print $2}' )
        [[ $ibversionf -lt $ibversion ]]&& ibversion=$ibversionf 
    done
    
    if [[ $ibversion -lt 2243 ]]
    then
        EchoAndLog  A "Swtich: We are working on to make automation of installing the  2.2.4-3 (p25747868). \n Install it  manully and continue the script "
        DoubleEnter
        PatchSwitch $1 
        return
    elif [[ $ibversion -lt 2272 ]] && [[ $ibversion -ge 2243 ]]
    then
        EchoAndLog I "Going to install $v_switch $PCOMPONENT to the version  2.2.7-2"
        CMD="/exalogic-lctools/bin/exapatch -a patch $PCOMPONENT -d nm2_2.2.7-2_descriptor.py";EchoAndLog EC "$CMD"
        EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB
        grep -i -e error -e failed $gc_tmpfileNB
        if [[ $? -eq 0 ]]
        then
            EchoAndLog A " Switch: $v_switch  $PCOMPONENT Patching failed while doing switch upgrade to 2.2.7-2."
            DoubleEnter
        else
            EchoAndLog I " Switch: $v_switch $PCOMPONENT is Patched to   2.2.7-2.  Proceeding to next version";EmptyNB;EchoAndLog DLINE;
            PatchSwitch $1
            return
        fi
    elif [[ $ibversion -ge 2272 ]] && [[ $ibversion -lt $SWITCHVERSION ]]
    then
        EchoAndLog I "Going to install $v_switch $PCOMPONENT to the -  latest verison "
        CMD="/exalogic-lctools/bin/exapatch -a patch $PCOMPONENT";EchoAndLog EC "$CMD"
        EmptyNB;EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD |tee -a $gc_tmpfileNB
        grep -i -e error  -e failed $gc_tmpfileNB
        if [[ $? -eq 0 ]]
        then
            EchoAndLog A " Switch: $v_switch  $PCOMPONENT Patching failed while doing switch upgrade to Latest. "
            DoubleEnter
        else
            EchoAndLog  I " Switch: $v_switch $PCOMPONENT is Patching  Completed"
            if [[ "$PCOMPONENT" == "nm2-gw" ]]
            then
                EchoAndLog I " Going to set leaf number for the $v_switch "
                SettingLeafNumber  
                 ExpectTool $gv_argument2 $CNP $c_SWCHECK1 
            fi
            
        fi

    else
        EchoAndLog I  "Switch: $PCOMPONENT Already have in version  $IBCURRENTVERSIONF"
        ExpectTool $gv_argument2 $CNP $c_SWCHECK1 
    fi
}
#-------------------------------------------------------------------
#PROCEDURE    : SettingLeafNumber
#DESCRIPTION  : set the leaf number o for the ib switch
#-------------------------------------------------------------------
SettingLeafNumber(){        #---this is to set leaf number for the ib switch  : argument "argument" "node1"
unset SW_ADDR1 SW_ADDR2 SW_ADDR3 SW_ADDR4 allip scfile
for i in $(grep NM2-GW-IB-Switch $gv_componentlistfile |grep -v Enter | awk '{print $2}')
do
    if [[ -z $SW_ADDR1 ]];then  SW_ADDR1=$i;allip=$i
    elif [[ -z $SW_ADDR2 ]];then  SW_ADDR2=$i;allip=${allip},$i 
    elif [[ -z $SW_ADDR3 ]];then  SW_ADDR3=$i;allip=${allip},$i 
    elif [[ -z $SW_ADDR4 ]];then  SW_ADDR4=$i;allip=${allip},$i ;fi
done

CMD="/opt/exalogic.tools/tools/dcli -c $allip -f /opt/exalogic.tools/tools/network_tools/switch_node_desc_config.tgz -d /tmp"
ExpectTool $gv_argument2 $CNP $CMD 
scfile="/opt/exalogic.tools/tools/network_tools/remote_config_switch_node_desc.sh"

if [[ $SW_ADDR1 ]];then
CMD="/opt/exalogic.tools/tools/dcli -c $SW_ADDR1 -f $scfile -d /tmp '/tmp/remote_config_switch_node_desc.sh 1'"
ExpectTool $gv_argument2 $CNP $CMD ; fi

if [[ $SW_ADDR2 ]];then
CMD="/opt/exalogic.tools/tools/dcli -c $SW_ADDR2 -f $scfile -d /tmp '/tmp/remote_config_switch_node_desc.sh 2'"
ExpectTool $gv_argument2 $CNP $CMD ; fi

if [[ $SW_ADDR3 ]];then
CMD="/opt/exalogic.tools/tools/dcli -c $SW_ADDR3 -f $scfile -d /tmp '/tmp/remote_config_switch_node_desc.sh 3'"
ExpectTool $gv_argument2 $CNP $CMD ;fi

if [[ $SW_ADDR4 ]];then
CMD="/opt/exalogic.tools/tools/dcli -c $SW_ADDR4 -f $scfile -d /tmp '/tmp/remote_config_switch_node_desc.sh 4'"
ExpectTool $gv_argument2 $CNP $CMD ;fi

unset SW_ADDR1 SW_ADDR2 SW_ADDR3 SW_ADDR4 allip scfile 
}
#-------------------------------------------------------------------
#PROCEDURE    : PostCheckSwitch
#DESCRIPTION  : post check  after patching the switch
#-------------------------------------------------------------------
PostCheckSwitch(){          #---after pathcing ibswitch check 
EchoAndLog LINE
}

#-------------------------------------------------------------------
#PROCEDURE    : ClearOldZFSHeadUpdates
#DESCRIPTION  : this is to clear clear the ZFS head old updates
#-------------------------------------------------------------------
ClearOldZFSHeadUpdates() {  #--- clear the zfs head old updates
local i
    if [[ $gv_patchnumber -lt 27454750 ]];then EchoAndLog A  " ZFS-Storage-Head: You are trying to install prior to AUG-2018 PSU..you need to upgrade it manually";Exit 10;fi
    
    EchoAndLog I "ZFS-Storage-Head : Going  to check previous version there or not. if more than one. it will remove that."
    for i in $(grep ZFS-Storage-Head $gv_componentlistfile |grep -v Enter| awk '{print $2}')
    do
        local ip=$i
        ExpectTool $ip $ZFSHEADP $c_ZFSCHECK3 > ${gc_tmptmp}/${ip}:updatesshow  #--- to get update show from zfs head
    
        for i in $(grep previous ${gc_tmptmp}/${ip}:updatesshow|awk '{print $1}')
        do
            EchoAndLog I " ZFS-Storage-Head: $ip found and removing the previous version  $i of ZFS from head $ip"
            CMD="confirm maintenance system updates destroy  $i"
            ExpectTool $ip $ZFSHEADP $CMD
             EchoAndLog I "$i on $ip Deleting  going on it will take 2 minutes";SleepCount 120
        done
    done

unset i
}
#-------------------------------------------------------------------
#PROCEDURE    : PatchZFSHead
#DESCRIPTION  :  patch the ZFS head
#-------------------------------------------------------------------
PatchZFSHead(){             #--- to patch ZFS storage head
    local EXABRBACKUPSTAUS;unset EXABRBACKUPSTAUS
    EchoAndLog I "Going to check exbrbackup of for ZFS-Storage-Head"
    for i in $(grep ZFS-Storage-Head $gv_componentlistfile |grep -v Enter | awk '{print $2}')
    do
        local ip=$i
        ExabrBackupCheck ZFS-Storage-Head  $ip 
    done

    if [[ $EXABRBACKUPSTAUS == failed ]] 
    then
        EchoAndLog  A " exbr backup is old. so taking exbr backup for  ZFS-Storage-Head  "
        CMD="/exalogic-lctools/bin/exabr backup all-sn";EchoAndLog EC "$CMD"
        EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB
        grep -i -e error -e failed $gc_tmpfileNB
        if [[ $? -eq 0 ]]
        then
            EchoAndLog  A " ZFS-Storage-Head: gc_EXABR Backup for the COMPONENT Failed. Please take it manually"
            DoubleEnter 
            PatchZFSHead 
            return
            
        else
            PatchZFSHead  
            return
        fi  
    fi
    unset EXABRBACKUPSTAUS
    #--zfs precheck script
    EchoAndLog LINE;EchoAndLog I "Running exapatch -a prePatchCheck ZFS-Storage-Head"
    CMD="/exalogic-lctools/bin/exapatch -a prePatchCheck zfs_software";EchoAndLog EC "$CMD"
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB
    grep -i -e error -e failed $gc_tmpfileNB
    if [[ $? -eq 0 ]]
    then
        EchoAndLog  A " zfs_storage-Head: prePatchCheck for the zfs_software Failed. Please validate  it manually"
        DoubleEnter 
    fi
    
    #--- zfs patching starts here
    
    #/////////// updating the ZFS_ilom
    EchoAndLog I "Going to do ZFS ILOM patching";
    CMD="/exalogic-lctools/bin/exapatch -a patch zfs_ilom";EmptyNB;EchoAndLog EC "$CMD"
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD |tee -a $gc_tmpfileNB
    grep -i -e  error  -e failed $gc_tmpfileNB
    if [[ $? -eq 0 ]]
    then
        EchoAndLog A " zfs_storagehead: Patching failed while doing zfs_ilom. ";DoubleEnter
    else
        EchoAndLog I " zfs_storagehead: zfs_ilom is Patching  Completed"
    fi
    
    if [[ $gv_ExitCode -eq 9 ]];  then  EchoAndLog A " TIMEOUT while patching  zfs_ilom ";Exit 9 ;fi
    
    #///////// updating the zfs_software
    EchoAndLog I "Going to do ZFS Head  patching";
    CMD="/exalogic-lctools/bin/exapatch -a patch zfs_software ";EmptyNB;EchoAndLog EC "$CMD"    
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD |tee -a $gc_tmpfileNB
    grep -i  -e error -e failed $gc_tmpfileNB
    if [[ $? -eq 0 ]]
    then
        EchoAndLog A " zfs_storagehead: Patching failed while doing zfs_software. ";DoubleEnter
    else
        EchoAndLog I " zfs_storagehead: zfs_software is Patching  Completed"
    fi
    
    if [[ $gv_ExitCode -eq 9 ]];  then  EchoAndLog A " TIMEOUT while patching  zfs_head ";Exit 9 ;fi
}
#-------------------------------------------------------------------
#PROCEDURE    : PostCheckZFS
#DESCRIPTION  :  post check after the  ZFS Head patching
#-------------------------------------------------------------------
PostCheckZFS(){             #--- after pathching ZFS head  check 
for i in $(grep ZFS-Storage-Head $gv_componentlistfile |grep -v Enter| awk '{print $2}')
do
    local ip=$i
    local passwd=$ZFSHEADP
    EchoAndLog LINE; EchoAndLog C " problems show from the storage head $i ";EchoAndLog EC $c_ZFSCHECK2;v_output=$(ExpectTool $ip $passwd $c_ZFSCHECK2);EchoAndLog "$v_output"
    [[ $v_output =~ "problem-" ]] && EchoAndLog A "found problem on maintenance problem show on $i" 
done
}

#-------------------------------------------------------------------
#PROCEDURE    : CollectNodeVSIlomIP
#DESCRIPTION  : collect computenode and its corresponding ILOM IP
#-------------------------------------------------------------------
CollectNodeVSIlomIP(){      #--- this to collect Node IP vs Ilom IP
[[ -f ${gc_tmpdir}/NODEVSILOM_$gv_patchnumber ]] && return
>${gc_tmpdir}/NODEVSILOM
    EchoAndLog I "Please wait. collecting and arranging the HOST IP vs ILOM  IP"
    for i in $(grep Compute-Node $gv_componentlistfile| awk '{print $2}')
    do  
        CMD="ipmitool sunoem cli 'show /System/ ilom_address'\;ipmitool sunoem cli 'show /SP/ hostname'"
        ExpectTool $i $CNP $CMD   >$gc_tmpfile
        local sysip=$i
        local sysname=$(grep -w $i $gv_componentlistfile| awk '{print $4}')
        local ilomip=$(grep = $gc_tmpfile | grep ilom_address | awk '{print $3}')
        local ilomname=$(grep = $gc_tmpfile | grep hostname | awk '{print $3}')
        echo "${sysip}=${sysname}=${ilomip}=${ilomname}" >>${gc_tmpdir}/NODEVSILOM  
        EchoAndLog "${sysip}=${sysname}=${ilomip}=${ilomname}"
    done
cat ${gc_tmpdir}/NODEVSILOM >${gc_tmpdir}/NODEVSILOM_$gv_patchnumber
}
#-------------------------------------------------------------------
#PROCEDURE    : ListComputeNodes
#DESCRIPTION  : lis the compute nodes and it ilom ip for the selection
#-------------------------------------------------------------------
ListComputeNodes(){         #--- this is to list compute node with the ilom detail
        [[ ! -f ${gc_tmpdir}/NODEVSILOM_$gv_patchnumber ]] && CollectNodeVSIlomIP
        
        EchoAndLog  "Select the compute node for patching "
        EchoAndLog "Number \t CNode-IP \t CNode-name \t CN-ilom-ip \t CN-Ilom-name "
        local cnode=$(grep $gc_hostname ${gc_tmpdir}/NODEVSILOM)
        if [[ $RUNENV == "node" ]] && [[ $cnode =~ $gc_hostname ]];then
            sed "s/$cnode/${cnode}-Current node, so dont select for patching/g" ${gc_tmpdir}/NODEVSILOM > ${gc_tmptmp}/nodesforselection
        else
            cat ${gc_tmpdir}/NODEVSILOM > ${gc_tmptmp}/nodesforselection
        fi
        cat -n ${gc_tmptmp}/nodesforselection | sed "s/=/ /g"
        read -p "Enter the node number by space : " nodelistuserentered
        EchoAndLog $nodelistuserentered >>$gv_logfile
        EchoAndLog  "Entered Number are -- $nodelistuserentered"

        if [[ -z $nodelistuserentered ]];then EchoAndLog E "Enter the number"; ListComputeNodes;return;fi
        
        local totalnodes=$(cat ${gc_tmptmp}/nodesforselection | wc -l)  #-- to check wrong number entered
        for i in $nodelistuserentered;do
        if [[ $i -gt $totalnodes ]] || [[ $i -le 0 ]] ; then 
            EchoAndLog ;EchoAndLog E "looks you enter wrong number ' $i '.  Please enter the correct number";EchoAndLog 
            ListComputeNodes
            return
        fi
        done
        
        one=one;two=two
        if [[ $RUNENV == "jumpgate" ]]; then
            for i in $nodelistuserentered
            do
                [[ $i -eq 1 ]] && local one=yes 
                [[ $i -eq 2 ]] && local two=yes 
            done
            if [[ $one == $two ]];then
                EchoAndLog ; EchoAndLog E "You can't select both  CN01 and CN02 for patching at same time ";EchoAndLog
                unset one ; unset two ; ListComputeNodes
                return
            fi
        fi
        
        
        EmptyNB
        for i in $nodelistuserentered       #--- to remove current running node
        do
            awk "NR==$i" ${gc_tmptmp}/nodesforselection | grep -v Current >>$gc_tmpfileNB
            [[ $? -ne 0 ]] && EchoAndLog I  "skipping  $i : because it is current node/non eligible node"
        done
        
        if [[ $(grep -c =  $gc_tmpfileNB) -eq 0 ]]; then ListComputeNodes  $1 $2 ; return;fi 
        
        unset ILOMIP NODEIP
        for i  in $(cat $gc_tmpfileNB)
        do
            ILOMIP="$ILOMIP  $(echo $i |awk -F "=" '{print $3}')"
        done

        for i  in $(cat $gc_tmpfileNB)
        do
            NODEIP="$NODEIP $(echo $i |awk -F "=" '{print $1}' )"
        done
        
        if [[ $gc_argument1 ==  "patch-components" ]] || [[ $gc_argument1 == "testing" ]]; then cat $gc_tmpfileNB >${gc_tmptmp}/computenodeselection;return;fi
            
        EchoAndLog  "Node for patching are : "
        cat $gc_tmpfileNB | sed "s/=/ /g"
        
        
        YesOrNo "Press 'yes' to Start patching for the above Compute node or press 'no' to show the list again ? yes/no :"
        if [[ $? -ne 0 ]]
        then
            ListComputeNodes  $1 $2
            return
        fi

}
#-------------------------------------------------------------------
#PROCEDURE    : SelectedNodeCheck
#DESCRIPTION  : do basic precheck of selected nodes.
#-------------------------------------------------------------------
SelectedNodeCheck(){        #--- selected node precheck
>$gc_message
EchoAndLog I "Checking basic prechecks from Selected nodes. it will take Few minutes"


local nodelist=$(echo $NODEIP |  tr ' ' ',')
local gc_DCLIWCNODEFILE="$gc_DCLI -c  $nodelist ";UsingCommand DCLIWITHIP
local NODECOUNT=$(echo "$NODEIP" | wc -w)


ComputeNodeDetail selectednode
DoubleEnter message

if [[ $gv_sysenv == "Virtual" ]];then
    EchoAndLog I "Going to check whether selected server has ExalogicControl vServer or not "
    local ECVMSRUNNING;unset ECVMSRUNNING
    local nodelist=$(echo $NODEIP |  tr ' ' ',')
    local CMDXMLIST="$gc_DCLI -c  $nodelist xm list"
    v_output=$(ExpectTool $gv_argument2 $CNP $CMDXMLIST )
    local ECVMS=$(grep ExalogicControl ${gc_tmptmp}/listvms | awk '{print $1}')
    for i in $ECVMS
    do
        if [[ "$v_output" =~ $i ]]; then 
            ECVMSRUNNING="yes"
        fi
    done
    
    if [[ $ECVMSRUNNING == "yes" ]];then
        EchoAndLog E "Found ExalogicControl vServer is running"
        grep ExalogicControl ${gc_tmptmp}/listvms
        YesOrNo " Shall I it shutdown  ? "
        if [[ $? -eq 0 ]];then
            EchoAndLog I "Going to stop the ExalogicControl vServer";
            EmptyNB;EchoAndLog EC "$c_OVMMCHECK11" ;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK11 | tee -a $gc_tmpfileNB   #--- this is for ecvserversshutdown
            ECVMSTOPPEDBYSCRIPT="yes"
            ECVMSRUNNING="no"
            sed -i 's/.*Found ExalogicControl vServer is running//g' $gc_message
        else
            ECVMSTOPPEDBYSCRIPT="no"
            EchoAndLog E " Cannot patch Compute node while VM is running. stop it manually  and hit enter or press cntl+C to stop the script"
            DoubleEnter
        fi
    fi
    
    EchoAndLog I "Going to check whether vm running or not on the server "
    v_output=$(ExpectTool $gv_argument2 $CNP $CMDXMLIST |grep 00000 | grep -i  -v -e state -e Domain-0 )
    if [[ $v_output ]];then
        EchoAndLog DLINE;EchoAndLog E " VM are running on the  following nodes. Please stop it ";EchoAndLog
        EchoAndLog "$v_output"
        DoubleEnter
        if [[ $? -eq 0 ]];then
            SelectedNodeCheck
            return
        else
            EchoAndLog E " Cannot patch Compute node while VM is running. stop it manually  and hit enter or press cntl+C to stop the script"
            DoubleEnter
        fi
    fi
fi
}
#-------------------------------------------------------------------
#PROCEDURE    : PatchComputeNode
#DESCRIPTION  : patch the selected computenode
#-------------------------------------------------------------------
PatchComputeNode(){         #--- runs actual node patchin command
unset NODEIPWITHH; unset ILOMWITHH
    for i in $NODEIP
    do
        NODEIPWITHH="$NODEIPWITHH -h $i "
    done
    
    for i in $ILOMIP
    do
        ILOMWITHH="$ILOMWITHH -h $i "
    done    
    
    EchoAndLog I "Going to check exabr backup status of  Node and Its Ilom: $NODEIP . it will take few minutes"
    unset EXABRBACKUPFAILEDIP;local EXABRBACKUPFAILEDIP
    local EXABRBACKUPSTAUS;local FAILEDIP
    unset EXABRBACKUPSTAUS;unset FAILEDIP
    for i in $NODEIP
    do
        ExabrBackupCheck Computenode $i
        FAILEDIP="$FAILEDIP $EXABRBACKUPFAILEDIP";unset EXABRBACKUPFAILEDIP
    done
    
    for i in $ILOMIP
    do
        ExabrBackupCheck Computenode-ilom $i
        FAILEDIP="$FAILEDIP $EXABRBACKUPFAILEDIP";unset EXABRBACKUPFAILEDIP
    done
    
    if [[ $EXABRBACKUPSTAUS == failed ]] 
    then
        unset backupip;local backupip;backupip=$(echo $FAILEDIP|tr ' ' ',')
    
        EchoAndLog ;EchoAndLog  A " exbr backup is old. so taking exbr backup for Compute-Node & Ilom  $backupip \n "
        CMD="/exalogic-lctools/bin/exabr backup $backupip --exclude-paths /tmp,/var/tmp,/var/run,/var/lib/nfs,/sys,/proc,/dev,/OVS,/dlm,/exalogic-lctools,/exalogic-lcdata,/nfsmnt,/poolfsmnt,/ssd  --timeout=5000"
        EmptyNB;EchoAndLog EC "$CMD";ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB
        grep -i -e error -e failed $gc_tmpfileNB
        if [[ $? -eq 0 ]]
        then
            grep 'Logging to file' $gc_tmpfileNB
            EchoAndLog  A " Compute-Node gc_EXABR Backup for the $FAILEDIP Failed. Please take it manually"
            DoubleEnter 
            PatchComputeNode 
            return
            
        else
            PatchComputeNode  
            return
        fi  
    fi
    unset EXABRBACKUPSTAUS
    
    local CN01IP=gv_argument2
    if [[ $RUNENV == "jumpgate" ]]; then
        local CN02IP=$(grep Compute-Node $gv_componentlistfile | awk "NR==2" | awk '{print $2}')
            for i in $nodelistuserentered
            do
                [[ $i -eq 1 ]] && local gv_argument2=$CN02IP
                if [[ $i -eq 1 ]] ; then 
                    EchoAndLog I "Checking whether /exalogic-lcdata mounted or not on node 2 "
                    CMD="ls -ld /exalogic-lcdata/patches/${gv_sysenv}/${gv_patchnumber}/Infrastructure"
                    v_output=$(ExpectTool $gv_argument2 $CNP $CMD)
                    err=$(echo "$v_output" | grep directory)
                    if [[ -n $err ]]
                    then
                        EchoAndLog I " Staged directory not found. so going to mount /exalogic-lcdata  the  on Node 2"
                        CMD="scp  root@${CN01IP}:/etc/fstab  ${gc_tmpdir}/node1-fstab"
                        ExpectToolNB $gv_argument2 $CNP $CMD
                        CMD="scp  root@${CN02IP}:/etc/fstab  ${gc_tmpdir}/node2-fstab"
                        ExpectToolNB $gv_argument2 $CNP $CMD
                        CMD="cp /etc/fstab /etc/fstab_$gv_datetime"
                        ExpectToolNB $gv_argument2 $CNP $CMD
                        CMD="scp ${gc_tmpdir}/node1-fstab  root@${CN02IP}:/etc/fstab  "
                        ExpectToolNB $gv_argument2 $CNP $CMD
                        CMD="mount -a"
                        ExpectToolNB $gv_argument2 $CNP $CMD
                        CMD="/bin/cp /etc/fstab_$gv_datetime /etc/fstab"
                        ExpectToolNB $gv_argument2 $CNP $CMD
                                                
                    else    
                        EchoAndLog   ".. mounted  \n"
                    fi
                
                fi 
                
            done
    fi
    
    
    prePatchCheckcomputenodeilom(){
        EchoAndLog I " Going prePatchCheck Compute node  "
        CMD="/exalogic-lctools/bin/exapatch -a prePatchCheck cn_ilom $ILOMWITHH";EmptyNB;EchoAndLog EC $CMD;EmptyNB
        EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB
        grep -i -e error -e failed  -e WARNING $gc_tmpfileNB 
        if [[ $? -eq 0 ]]
        then
            EchoAndLog A " Compute Node ILom prePatchCheck  failed . fix the and continue  "
            DoubleEnter
            prePatchCheckcomputenodeilom
            return
        else
            EchoAndLog I " Compute Node ILOM  prePatchCheck completed  for $ILOMIP"
            
        fi
    }
    prePatchCheckcomputenodeilom
    
    EchoAndLog I " Going patch Compute node ILOM "
    CMD="/exalogic-lctools/bin/exapatch -a patch cn_ilom $ILOMWITHH";EmptyNB;EchoAndLog EC $CMD;EmptyNB
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB
    grep -i -e error -e failed $gc_tmpfileNB
    if [[ $? -eq 0 ]]
    then
        EchoAndLog A " Compute Node ILOM patching failed  "
        DoubleEnter
    else
        EchoAndLog I " Compute Node ILOM patching completed  for $ILOMIP"
        
    fi
    
    EchoAndLog  I "Will start compute node patching  in  60 seconds" ; SleepCount 60

    prePatchCheckcomputenode(){
        EchoAndLog I " Going prePatchCheck Compute node  "
        CMD="/exalogic-lctools/bin/exapatch -a prePatchCheck cn $NODEIPWITHH";EmptyNB;EchoAndLog EC $CMD
        EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB
        grep -i -e error -e failed  -e WARNING $gc_tmpfileNB 
        if [[ $? -eq 0 ]]
        then
            EchoAndLog A " Compute Node prePatchCheck  failed . fix the and continue  "
            DoubleEnter
            prePatchCheckcomputenode
            return
        else
            EchoAndLog I " Compute Node prePatchCheck completed  for $NODEIP"
            
        fi
    }
    prePatchCheckcomputenode
    
    
    EchoAndLog I " Going patch Compute node  "
    CMD="/exalogic-lctools/bin/exapatch -a patch cn  $NODEIPWITHH";EmptyNB;EchoAndLog EC $CMD;EmptyNB
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD | tee -a $gc_tmpfileNB
    grep -i -e error -e failed $gc_tmpfileNB
    if [[ $? -eq 0 ]]
    then
        EchoAndLog A " Compute Node patching  failed  "
        DoubleEnter
    else
        EchoAndLog I " Compute Node Patching completed for $NODEIP"
        
    fi
    
}
#-------------------------------------------------------------------
#PROCEDURE    : PostCheckComputeNode
#DESCRIPTION  : post check after the compute node patching 
#-------------------------------------------------------------------
PostCheckComputeNode(){     #--- post check after compute node pathing
    EchoAndLog ;EchoAndLog I " Going to do post patch check of compute node  on $NODEIP "
    local nodelist=$(echo $NODEIP |  tr ' ' ',')
    local DCLINIP="$gc_DCLI -c  $nodelist "
    local CMD;local NODECOUNT=$(echo "$NODEIP" | wc -w)
    
    
    CMD="$DCLINIP  '/opt/exalogic.tools/tools/CheckSWProfile'"
    EchoAndLog LINE; EchoAndLog C " SW profile from   compute node" ; EchoAndLog EC "$CMD";v_output=$(ExpectTool $gv_argument2 $CNP $CMD);EchoAndLog "$v_output"
    err=$(echo "$v_output" | grep \: | grep -v -i SUCCESS);[[ $err ]] && EchoAndLog E " SW profile verification found issue" || EchoAndLog I " SW profile verification-  No issue."

    CMD="$DCLINIP '/opt/exalogic.tools/tools/CheckHWnFWProfile | tail -1'"
    EchoAndLog LINE; EchoAndLog C " HW profile from  all compute node" ; EchoAndLog EC "$CMD";v_output=$(ExpectTool $gv_argument2 $CNP $CMD );EchoAndLog "$v_output"
    tc=$(echo "$v_output" | grep  -c 'Firmware verification succeeded' ); [[ $tc -ne $NODECOUNT ]] && EchoAndLog E "Check HW profile of some node failed" || EchoAndLog I " HW profile verification No issue."
    
    
    if [[ $gv_sysenv == "Virtual" ]]; then 
            CMD="df -Ph"; EchoAndLog C "Going to  verfiy /poolfsmnt mounted or not. if not mounted . it will restart the ovs-agent "
            for i in $NODEIP ;do
                v_output=$(ExpectTool $i $CNP  $CMD| grep poolfsmnt)
                if [[ $v_output =~ mapper ]]; then 
                    EchoAndLog I " $i /poolfsmnt mounted " 
                else 
                    EchoAndLog I " $i /poolfsmnt is not mounted. so going to restart OVS-agent on $i"
                    ExpectToolNB $i $CNP 'service ovs-agent restart'
                fi
            done
        [[ $ECVMSTOPPEDBYSCRIPT == "yes" ]] && EchoAndLog I "will start ovmm server . becuease it   stoped by this script: $ECVMSTOPPEDBYSCRIPT"
        [[ $ECVMSTOPPEDBYSCRIPT == "yes" ]] && ECVserverStart
        unset ECVMSTOPPEDBYSCRIPT
    fi
    if [[ $gv_sysenv == "Virtual" ]];then
            EchoAndLog LINE ; EchoAndLog I " Collecting O2CB status from all compute node";EchoAndLog EC "$c_ZFSCHECK13"
            v_output=$(ExpectTool $gv_argument2 $CNP $c_ZFSCHECK13) ; v_output=$(echo "$v_output" | grep : );EchoAndLog "$v_output"
            v_output=$(echo "$v_output" | egrep 'O2CB|threshold' | grep -v Online | grep -v 43201 | grep -v Active | grep -v  Nodes)
            if [[ -n $v_output  ]]
            then
                    EchoAndLog E "O2CB Status  has wrong value  on : "
                    EchoAndLog E "$v_output"
            fi
            
    fi
}

#-------------------------------------------------------------------
#PROCEDURE    : PatchVTemplate
#DESCRIPTION  : patch Vtemplate ( upgrading the base image for OVMM , pc1 and p2)
#-------------------------------------------------------------------
PatchVTemplate(){           #-- to upgrade EC vServer template
[[ $gv_sysenv == "Linux" ]] && return 2
local ovmip=$(grep vServer-EC-OVMM  $gv_componentlistfile |  awk '{print $2}')
local pc1ip=$(grep vServer-EC-EMOC-PC  $gv_componentlistfile  | awk '{print $2}'|head -1)
local pc2ip=$(grep vServer-EC-EMOC-PC  $gv_componentlistfile  | awk '{print $2}'|tail -1)

if [[ -n $ovmip ]]
    then
    v_output=$(ExpectTool $gv_argument2 $CNP $c_CNCHECK7)
    local ECVMS=$(echo "$v_output" | grep ExalogicControl | awk '{print $1}')
    v_output=$(ExpectTool $gv_argument2 $CNP $c_CNCHECK8 )
    for i in $ECVMS
    do
        [[ "$v_output" =~ i ]]&&  ECVMSRUNNING="yes" || ECVMSRUNNING="no"
    done
    
    if [[ $ECVMSRUNNING == "yes" ]];then
        EchoAndLog I "Going to shutdown the OVMM vServers. if it running -- for taking backup";EchoAndLog EC $c_OVMMCHECK11
        EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK11 | tee -a $gc_tmpfileNB   #--- this is for ecvserversshutdown
    fi
    EchoAndLog I "Going to backup  the Control stack ";EchoAndLog EC $c_OVMMCHECK12
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK12 | tee -a $gc_tmpfileNB   #--- this if for backup control-stack
    EchoAndLog I "Will start next command in 61 Second"; SleepCount 61
    EchoAndLog I "Going to Veirfy  the control-stack backup status ";EchoAndLog EC $c_OVMMCHECK13
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK13  |tee -a $gc_tmpfileNB   #-- this if for list  control-stack backup
    grep -i minutes  $gc_tmpfileNB >/dev/null
    if [[ $? -ne 0 ]]
    then    
        EchoAndLog A " Control-Stack:  Looks exabr backup is not happen/Failed, please take it manually !!! "
        DoubleEnter
    fi
    
    ECVserverStart
    
{       #-------------- Verfying Ekit installed on OVMM & PC or not
    EchoAndLog I "Verfying Ekit installed on OVMM & PC or not"
    CMD="rpm -qa ekit"; v_output=$(ExpectTool  $ovmip $OVMMECP $CMD)
    if [[ $v_output =~ 'ekit-' ]];then  
        EchoAndLog E "Found ekit on the OVMM $OVMIP"
        YesOrNo "Shall i remove it"
        if [[ $? -eq 0 ]]; then
            ExpectTool  $ovmip $OVMMECP  'rpm -ev ekit'
        else 
            EchoAndLog E "With ekit on the OVMM. script can't proceed for pathing. so stoping the script";Exit 10
        fi
    fi
    v_output=$(ExpectTool  $pc1ip $OVMMECP $CMD)
    if [[ $v_output =~ 'ekit-' ]];then  
        EchoAndLog E "Found ekit on the PC1  $pc1ip"
        YesOrNo "Shall i remove it"
        if [[ $? -eq 0 ]]; then
            ExpectTool  $pc1ip $OVMMPCP  'rpm -ev ekit'
        else 
            EchoAndLog E "With ekit on the PC1. script can't proceed for pathing. so stoping the script";Exit 10
        fi
    fi
    v_output=$(ExpectTool  $pc2ip $OVMMECP $CMD)
    if [[ $v_output =~ 'ekit-' ]];then  
        EchoAndLog E "Found ekit on the PC2 $pc2ip"
        YesOrNo "Shall i remove it"
        if [[ $? -eq 0 ]]; then
            ExpectTool  $pc2ip $OVMMPCP  'rpm -ev ekit'
        else 
            EchoAndLog E "With ekit on the PC2. script can't proceed for pathing. so stoping the script";Exit 10
        fi
    fi
}   
    CMD="/exalogic-lctools/bin/exapatch -a prePatchCheck ectemplates"
    EchoAndLog I " Going to do precheck for ec templates";EmptyNB;EchoAndLog EC $CMD
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD |tee -a $gc_tmpfileNB
    grep -i -e error -e failed $gc_tmpfileNB
    if [[ $? -eq 0 ]]
    then
        EchoAndLog  A " EC TEMPLATES prePatchCheck for the Failed. Please validate  it manually"
        DoubleEnter 
    fi
    
    #--- actual patch command start here
    CMD="/exalogic-lctools/bin/exapatch -a patch ectemplates"
    EchoAndLog I " Going to do patch for ec templates";EmptyNB;EchoAndLog EC $CMD
    EmptyNB;ExpectToolNB $gv_argument2 $CNP $CMD |tee -a $gc_tmpfileNB
    grep -i -e error -e failed $gc_tmpfileNB
    if [[ $? -eq 0 ]]
    then
        EchoAndLog  A " EC TEMPLATES patching   Failed. Please validate  it manually"
        Exit 10 
    fi
    
    if [[ $ECVMSRUNNING == "no" ]];then
        EchoAndLog I "OVMM server was not running before starting this vServer patching. So shuting down";EchoAndLog EC $c_OVMMCHECK11
        EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK11 | tee -a $gc_tmpfileNB   #--- this is for ecvserversshutdown
        unset ECVMSRUNNING
    fi
    
else
    echo -e  "\n OVMM might be not running while starting this script  or server might be Physical \n"
fi
}
#-------------------------------------------------------------------
#PROCEDURE    : PostCheckVtemplate
#DESCRIPTION  : post check the after the patching of vtemplate
#-------------------------------------------------------------------
PostCheckVtemplate(){       #--- after patching V-template
[[ $gv_sysenv == "Linux" ]] && return 2
local ovmip=$(grep vServer-EC-OVMM  $gv_componentlistfile |  awk '{print $2}')
local pc1ip=$(grep vServer-EC-EMOC-PC  $gv_componentlistfile  | awk '{print $2}'|head -1)
local pc2ip=$(grep vServer-EC-EMOC-PC  $gv_componentlistfile  | awk '{print $2}'|tail -1)
    EchoAndLog LINE; EchoAndLog C " ovmm service status from OVMM server $ovmip ";EchoAndLog EC $c_OVMMCHECK6; v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK6);EchoAndLog "$v_output"
    if [[ ! $v_output =~ 'Oracle VM Manager is running' ]];then 
        EchoAndLog I "found OVMM service is down. tring to  start the services  ";EchoAndLog EC $c_OVMMCHECK6start
        ExpectTool $ovmip $OVMMECP  $c_OVMMCHECK6start ;sleep 10
        v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK6);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'Oracle VM Manager is running' ]];then
            EchoAndLog A "Failed to start OVMM service . start it manually"
            DoubleEnter
        fi
    fi
    
    EchoAndLog LINE; EchoAndLog C " ECADM  service status from OVMM server $ovmip ";EchoAndLog EC $c_OVMMCHECK7; v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK7);EchoAndLog "$v_output"
    if [[ ! $v_output =~ 'online' ]];then 
        EchoAndLog I "found ECADM service is down. tring to  start the services  ";EchoAndLog EC $c_OVMMCHECK7start
        ExpectTool $ovmip $OVMMECP  $c_OVMMCHECK7start ;sleep 10
        v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK7);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'online' ]];then
            EchoAndLog A "Failed to start ECADM service . start it manually" 
            DoubleEnter
        fi
    fi
    
    EchoAndLog LINE; EchoAndLog C " satadm  service status from OVMM server $ovmip ";EchoAndLog EC $c_OVMMCHECK8; v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK8);EchoAndLog "$v_output"
    if [[ ! $v_output =~ 'online' ]];then 
        EchoAndLog I "found satadm service is down. tring to  start the services  ";EchoAndLog EC $c_OVMMCHECK8start
        ExpectTool $ovmip $OVMMECP $c_OVMMCHECK8start ;sleep 10
        v_output=$(ExpectTool  $ovmip $OVMMECP $c_OVMMCHECK8);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'online' ]];then
            EchoAndLog A "Failed to start satadm service . start it manually" 
            DoubleEnter
        fi
    fi

    local restartcontrolstack; unset restartcontrolstack
    EchoAndLog "" >$gc_message
    EchoAndLog I "Going to check whether OVMM port  7002 open or not "
    CMD="/usr/bin/nc -w 3 -z $ovmip 7002"
    v_output=$(ExpectTool $gv_argument2 $CNP $CMD )
    if [[ $v_output =~ succeeded ]] ; then
        EchoAndLog I "7002 port is open "
    else
        EchoAndLog A "7002 is not open.  OVMM will not be accessable. need restart of Control stack"
        restartcontrolstack="yes"
    fi 
    
    EchoAndLog I "Going to check whether EMOC  port  9443  open or not "
    CMD="/usr/bin/nc -w 3 -z $ovmip 9443"
    v_output=$(ExpectTool $gv_argument2 $CNP $CMD )
    if [[ $v_output =~ succeeded ]] ; then
        EchoAndLog I "9443 EMOC  port is open "
    else
        EchoAndLog A "9443 EMOC port  is not open.  EMOC  will not be accessable. need restart of Control stack"
        restartcontrolstack="yes"
    fi 
    
    if [[ $restartcontrolstack == yes ]]; then
        YesOrNo " OVMM or EMOC port is not open. Shall i  restart control-stack "
        if [[ $? -eq 0 ]];then
            EmptyNB;ExpectToolNB $gv_argument2 $CNP $c_OVMMCHECK11 | tee -a $gc_tmpfileNB        #--- to shutdown the control stack
            EchoAndLog I "Sleeping 30 second";SleepCount 30
            ECVserverStart                #-- to start the control-stack
            PostCheckVtemplate
            return
        else
            EchoAndLog I " Please check it those two port on Control-Stack server. otherwise EMOC/OVMM  wont work"
        fi
    fi
    
    
        EchoAndLog LINE; EchoAndLog C " proxyadm   service status from PC1 server $pc1ip ";EchoAndLog EC $c_OVMMCHECK9; v_output=$(ExpectTool  $pc1ip $OVMMPCP $c_OVMMCHECK9);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'online' ]];then 
            EchoAndLog I "found proxyadm service is down. tring to  start the services  on $pc1ip ";EchoAndLog EC $c_OVMMCHECK9start
            ExpectTool $pc1ip $OVMMPCP  $c_OVMMCHECK9start ;sleep 10
            v_output=$(ExpectTool  $pc1ip $OVMMPCP $c_OVMMCHECK9);EchoAndLog "$v_output"
            if [[ ! $v_output =~ 'online' ]];then
                EchoAndLog A "Failed to start proxyadm service on $pc1ip . start it manually"
                DoubleEnter
            fi
        fi
        
        EchoAndLog LINE; EchoAndLog C " proxyadm  service status from OVMM server $pc2ip ";EchoAndLog EC $c_OVMMCHECK9; v_output=$(ExpectTool  $pc2ip $OVMMPCP $c_OVMMCHECK9);EchoAndLog "$v_output"
        if [[ ! $v_output =~ 'online' ]];then 
            EchoAndLog I "found proxyadm service is down. tring to  start the services  on $pc2ip ";EchoAndLog EC $c_OVMMCHECK9start
            ExpectTool $pc2ip $OVMMPCP  $c_OVMMCHECK9start ;sleep 10
            v_output=$(ExpectTool  $pc2ip $OVMMPCP $c_OVMMCHECK9);EchoAndLog "$v_output"
            if [[ ! $v_output =~ 'online' ]];then
                EchoAndLog A "Failed to start proxyadm service $pc2ip . start it manually" 
                DoubleEnter
            fi
        fi
    
    
}

#-------------------------------------------------------------------
#PROCEDURE    : DisplayComponents
#DESCRIPTION  : display the component for the selection 
#-------------------------------------------------------------------
DisplayComponents(){        #-- this is to list components for patching
EchoAndLog DLINE;EchoAndLog

EchoAndLog "list" >$gc_message

local COMPLIST="Select component for pathing 
        1. Exalogic Control Services - Virtual Environment
        2. GW/Infiniband Switches
        3. Spine Switch 
        4. ZFS Storage Head and ILOM
        5. Compute Node
        6. EC vServers Template - Virtual Environment" 

    
[[ ! $(cat $gv_componentlistfile) =~ NM2-36p-IB-Switch ]] && COMPLIST=$(EchoAndLog "$COMPLIST" | sed "s/Spine Switch/Spine Switch - don't select no spine switch found/g")
[[ $gv_sysenv != Virtual ]] && COMPLIST=$(EchoAndLog "$COMPLIST" | sed "s/Virtual Environment/Physical Environment - don't select/g")
EchoAndLog "$COMPLIST"
EchoAndLog
read -p "Enter the Components Number by space : " componentlistforpatching
    EchoAndLog $componentlistforpatching >>$gv_logfile
if [[ -z $componentlistforpatching ]];then EchoAndLog E "Enter the number"; DisplayComponents;return;fi

    for i in $componentlistforpatching;do
        if [[ $i -gt 6 ]]  || [[ $i -le 0 ]] ; then 
            EchoAndLog ;EchoAndLog E "looks you enter wrong number ' $i '.  Please enter the correct number";EchoAndLog 
            DisplayComponents
            return
        fi
    done
[[ $componentlistforpatching =~ 5 ]] && ListComputeNodes
#YesOrNo "Would you like to press 'yes' before starting each components ( interactive) ?  "
#if [[ $? -eq 0 ]]; then patchmode="interactive" ;EchoAndLog I " Script will wait for your input before starting the each component"; fi    

patchmode="interactive"

EchoAndLog;EchoAndLog " Then number entred by you : $componentlistforpatching";EchoAndLog

[[ ! $(cat $gv_componentlistfile) =~ NM2-36p-IB-Switch ]]&& componentlistforpatching=$(echo $componentlistforpatching |tr -d 3 )
[[ $gv_sysenv != Virtual ]] && componentlistforpatching=$(echo $componentlistforpatching |tr -d 1 |tr -d 6 )

if [[ -z $componentlistforpatching ]];then EchoAndLog E "Select Component according  to environment"; DisplayComponents;return;fi
 
EchoAndLog " The components for pathching are: \n "
unset patchitem
for i in  $componentlistforpatching;do
    if [[ $i -eq 1 ]]; then EchoAndLog "\t 1. Exalogic Control Services";patchitem="$patchitem patchecs ";fi
    if [[ $i -eq 2 ]]; then EchoAndLog "\t 2. GW/Infiniband Switches";patchitem="$patchitem patchib "; fi
    if [[ $i -eq 3 ]]; then EchoAndLog "\t 3. Spine-Switch ";patchitem="$patchitem patchspine "; fi
    if [[ $i -eq 4 ]]; then EchoAndLog "\t 4. ZFS Storage Appliance";patchitem="$patchitem patchzfs ";fi
    if [[ $i -eq 5 ]]; then EchoAndLog "\t 5. Compute nodes";patchitem="$patchitem patchnode ";cat ${gc_tmptmp}/computenodeselection | sed "s/=/ /g";EchoAndLog;fi
    if [[ $i -eq 6 ]]; then EchoAndLog "\t 6. EC vServers Template";patchitem="$patchitem patchect ";fi
done
    
    YesOrNo "Was the above information correct ? "
    if [[ $? -ne 0 ]] ; then DisplayComponents;return;fi
        
}
#-------------------------------------------------------------------
#PROCEDURE    : PreCheckComponents
#DESCRIPTION  : do the basic precheck for the selected components
#-------------------------------------------------------------------
PreCheckComponents(){        #--- this to do precheck of selected component
EchoAndLog 
EchoAndLog I " Going to do basic precheck of selected  component "
local PRECMESSAGE=${gc_tmptmp}/PRECMESSAGE
    for i in $patchitem;do
        [[ $i == patchecs ]] && OvmmServerDetail
        [[ $i == patchib ]] && IBSwitchDetail IB-Switch
        [[ $i == patchspine ]] && IBSwitchDetail Spine-Switch
        [[ $i == patchzfs ]] && ClearOldZFSHeadUpdates
        [[ $i == patchzfs ]] && ZFSHeadDetail
        [[ $i == patchnode ]] && SelectedNodeCheck
        [[ $i == patchect ]] && OvmmServerDetail
                
        cat $gc_message >>$PRECMESSAGE
        >$gc_message
        EchoAndLog DLINE;EchoAndLog DLINE
    done

cat $PRECMESSAGE >$gc_message
DoubleEnter message
>$PRECMESSAGE

}
#-------------------------------------------------------------------
#PROCEDURE    : PatchComponents
#DESCRIPTION  :  patch the selected components 
#-------------------------------------------------------------------
PatchComponents(){            #---- for pathing each components

local exitcode;local CMESSAGE=${gc_tmptmp}/CMESSAGE
for i in $patchitem;do
    [[ $exitcode -eq 10 ]] && Exit 10 
    if [[ $patchmode == interactive ]]; then 
            [[ $i == patchecs ]] && COMPTODISPLAY="Exalogic Control Services"
            [[ $i == patchib ]] && COMPTODISPLAY="IB Gateway Switches"
            [[ $i == patchspine ]] && COMPTODISPLAY="IB Spine Switch "
            [[ $i == patchzfs ]] && COMPTODISPLAY="ZFS Storage Appliance"
            [[ $i == patchnode ]] && COMPTODISPLAY="Compute Nodes and Compute Node ILOM"
            [[ $i == patchect ]] && COMPTODISPLAY="EC vServers Template"
            
        YesOrNo  " *************  Shall i start -  $COMPTODISPLAY ? "
        if [[ $? -eq 0 ]]; then 
            [[ $i == '' ]] && EchoAndLog DLINE
            [[ $i == patchecs ]] && PatchECS
            [[ $i == patchib ]] && PatchSwitch IB-Switch
            [[ $i == patchspine ]] && PatchSwitch Spine-Switch
            [[ $i == patchzfs ]] && PatchZFSHead
            [[ $i == patchnode ]] && PatchComputeNode
            [[ $i == patchect ]] && PatchVTemplate
            cat $gc_message >$CMESSAGE
            >$gc_message
            DoubleEnter message
        else
            EchoAndLog I " You have typed  'no' . So going to stop the script "
            exitcode=10
            Exit 10 
            break
        fi
        unset COMPTODISPLAY
    else
        [[ $i == '' ]] && EchoAndLog DLINE
        [[ $i == patchecs ]] && PatchECS
        [[ $i == patchib ]] && PatchSwitch IB-Switch
        [[ $i == patchspine ]] && PatchSwitch Spine-Switch
        [[ $i == patchzfs ]] && PatchZFSHead
        [[ $i == patchnode ]] && PatchComputeNode
        [[ $i == patchect ]] && PatchVTemplate
        cat $gc_message >$CMESSAGE
        >$gc_message
        DoubleEnter message
    fi
    [[ $exitcode -eq 10 ]] && Exit  10 
done
    [[ $exitcode -eq 10 ]] && Exit  10 
}
#-------------------------------------------------------------------
#PROCEDURE    : PostCheckComponents
#DESCRIPTION  :  post check the selected components after patching 
#-------------------------------------------------------------------
PostCheckComponents(){         #--- this to do post check of selected component
EchoAndLog 
EchoAndLog I " Going to do post check of selected  component "
local POCMESSAGE=${gc_tmptmp}/POCMESSAGE
    for i in $patchitem;do
        [[ $i == patchecs ]] && PostCheckECS
        [[ $i == patchib ]] && PostCheckSwitch IB-Switch
        [[ $i == patchspine ]] && PostCheckSwitch Spine-Switch
        [[ $i == patchzfs ]] && PostCheckZFS
        [[ $i == patchnode ]] && PostCheckComputeNode
        [[ $i == patchect ]] && PostCheckVtemplate
                
        cat $gc_message >>$POCMESSAGE; echo >$gc_message;EchoAndLog DLINE
    done

cat $POCMESSAGE >$gc_message
DoubleEnter message
>$POCMESSAGE
}

#-------------------------------------------------------------------
#PROCEDURE    : PreCheckAllComponents
#DESCRIPTION  : do precheck for all components. this if non-rolling
#-------------------------------------------------------------------
PreCheckAllComponents(){    #-- this to do all post patch check  for non-rolling
EchoAndLog > $gc_message
EchoAndLog 
EchoAndLog I " Going to do basic precheck of all component  "
local PREACMESSAGE=${gc_tmptmp}/POACMESSAGE
local allcomponent=$(cat $gv_componentlistfile)
MESSAGE_TO_PREACMESSAGE(){
cat $gc_message >>$PREACMESSAGE; echo >$gc_message;EchoAndLog DLINE
}
        
        [[ $allcomponent =~ vServer-EC-OVMM ]] && OvmmServerDetail ; MESSAGE_TO_PREACMESSAGE    
        [[ $allcomponent =~ NM2-GW-IB-Switch ]] && IBSwitchDetail IB-Switch ; MESSAGE_TO_PREACMESSAGE
        [[ $allcomponent =~ NM2-36p-IB-Switch ]] && IBSwitchDetail Spine-Switch ; MESSAGE_TO_PREACMESSAGE
        [[ $allcomponent =~ ZFS-Storage-Head ]] && ClearOldZFSHeadUpdates ; MESSAGE_TO_PREACMESSAGE
        [[ $allcomponent =~ ZFS-Storage-Head ]] && ZFSHeadDetail ; MESSAGE_TO_PREACMESSAGE
        if [[ $allcomponent =~ Compute-Node ]] ;then 
            CollectNodeVSIlomIP ; MESSAGE_TO_PREACMESSAGE
            unset ILOMIP;for i  in $(cat $NODEVSILOM) ; do ILOMIP="$ILOMIP $(echo $i |awk -F "=" '{print $3}'  )" ;done
            unset NODEIP;for i  in $(cat $NODEVSILOM) ; do NODEIP="$NODEIP $(echo $i |awk -F "=" '{print $1}'  )" ;done
            SelectedNodeCheck ; MESSAGE_TO_PREACMESSAGE
            unset ILOMIP NODEIP
        fi
        
cat $PREACMESSAGE >$gc_message
DoubleEnter message
echo >$PREACMESSAGE
}
#-------------------------------------------------------------------
#PROCEDURE    : PatchAllComponents
#DESCRIPTION  : patch all components . this is for non-rolling
#-------------------------------------------------------------------
PatchAllComponents(){        #-- this to do patching of all component
EchoAndLog I " Going to do patching on all component "
local allcomponent=$(cat $gv_componentlistfile)
        [[ $allcomponent =~ vServer-EC-OVMM ]] && PatchECS
        [[ $allcomponent =~ NM2-GW-IB-Switch ]] && PatchSwitch IB-Switch
        [[ $allcomponent =~ NM2-36p-IB-Switch ]] && PatchSwitch Spine-Switch
        [[ $allcomponent =~ ZFS-Storage-Head ]] && PatchZFSHead
        if [[ $allcomponent =~ Compute-Node ]] ; then 
            EchoAndLog I "Going to patch first compute node"
            nodelistuserentered="1" 
            cat $NODEVSILOM | awk "NR==1" >${gc_tmptmp}/NODEVSILOMWITHNODE1
            unset ILOMIP;for i  in $(cat ${gc_tmptmp}/NODEVSILOMWITHNODE1) ; do ILOMIP="$ILOMIP $(echo $i |awk -F "=" '{print $3}' )" ;done
            unset NODEIP;for i  in $(cat ${gc_tmptmp}/NODEVSILOMWITHNODE1) ; do NODEIP="$NODEIP $(echo $i |awk -F "=" '{print $1}' )" ;done
            [[ NODEIP ]] && PatchComputeNode || Exit 66
            unset nodelistuserentered
            
            EchoAndLog I " Going to patch balance compute node"
            cat $NODEVSILOM | awk "NR!=1" >${gc_tmptmp}/NODEVSILOMWITHOUTNODE1
            unset ILOMIP;for i  in $(cat ${gc_tmptmp}/NODEVSILOMWITHOUTNODE1) ; do ILOMIP="$ILOMIP $(echo $i |awk -F "=" '{print $3}' )" ;done
            unset NODEIP;for i  in $(cat ${gc_tmptmp}/NODEVSILOMWITHOUTNODE1) ; do NODEIP="$NODEIP $(echo $i |awk -F "=" '{print $1}' )" ;done
            [[ NODEIP ]] && PatchComputeNode || Exit 66
        fi
        [[ $allcomponent =~ vServer-EC-OVMM ]] && PatchVTemplate
}
#-------------------------------------------------------------------
#PROCEDURE    : PostCheckAllComponents
#DESCRIPTION  : post check of all components . this is for non-rolling
#-------------------------------------------------------------------
PostCheckAllComponents(){     #--- this to do post check of all  component
EchoAndLog 
EchoAndLog I " Going to do postcheck of all component  "
local POACMESSAGE=${gc_tmptmp}/POACMESSAGE
local allcomponent=$(cat $gv_componentlistfile)
        [[ $allcomponent =~ vServer-EC-OVMM ]] && PostCheckECS
        [[ $allcomponent =~ NM2-GW-IB-Switch ]] && PostCheckSwitch IB-Switch
        [[ $allcomponent =~ NM2-36p-IB-Switch ]] && PostCheckSwitch Spine-Switch
        [[ $allcomponent =~ ZFS-Storage-Head ]] && PostCheckZFS
        unset ILOMIP;for i  in $(cat $NODEVSILOM) ; do ILOMIP="$ILOMIP $(echo $i |awk -F "=" '{print $3}'  )" ;done
        unset NODEIP;for i  in $(cat $NODEVSILOM) ; do NODEIP="$NODEIP $(echo $i |awk -F "=" '{print $1}'  )" ;done
        [[ $allcomponent =~ Compute-Node ]] && PostCheckComputeNode
        [[ $allcomponent =~ vServer-EC-OVMM ]] && PostCheckVtemplate
                
        cat $gc_message >$POACMESSAGE
        >$gc_message
        EchoAndLog DLINE;EchoAndLog DLINE

cat $POACMESSAGE >$gc_message
DoubleEnter message
}

#-------------------------------------------------------------------
#PROCEDURE    : MainCaseStatement
#DESCRIPTION  : main case statement  of this  script
#-------------------------------------------------------------------
MainCaseStatement(){        #----- main script  case statement of this script

case $gc_argument1 in
    passwd-check)
        PatchBasicDetail 
        PasswordCheckFunction   
        ;;

    stage-psu)
        PatchBasicDetail  "onlycomputenode"
        StagePatch $gc_argument1 $gv_argument2  
        ;;

    send-logtoportal)
        SendLogToPortal
        ;;

    pre-checkrack)
        PatchBasicDetail 
        PasswordCheckFunction    
        EchoAndLog "LOGTOUPLOADSTARTHERE" >>$gv_logfile
        CollectCheckAuthOutput             
        ComputeNodeDetail              
        ZFSHeadDetail                   
        IBSwitchDetail  IB-Switch      
        IBSwitchDetail    Spine-Switch 
        CollectAllSwitchDetail          
        OvmmServerDetail                      
        ValidateRackPhython 
        EchoAndLog "LOGTOUPLOADSTOPHERE" >>$gv_logfile        
        EndDisplaySummary
        ConvertLog
        SendLogToPortal $SLOGFILE
        ;;
    
    patch-ecs)
        PatchBasicDetail             
        PasswordCheckFunction
        OvmmServerDetail                      
        DoubleEnter message              
        PatchECS                     
        PostCheckECS    
        DoubleEnter message
        ;;
        
    patch-ib)
        PatchBasicDetail
        PasswordCheckFunction
        IBSwitchDetail IB-Switch     
        DoubleEnter message             
        PatchSwitch IB-Switch            
        PostCheckSwitch IB-Switch  
        DoubleEnter message
        ;;
        
    patch-Spine)
        PatchBasicDetail
        if [[ $(cat $gv_componentlistfile) =~ NM2-36p-IB-Switch ]]; then 
            PasswordCheckFunction
            IBSwitchDetail Spine-Switch     
            DoubleEnter message                
            PatchSwitch Spine-Switch        
            PostCheckSwitch Spine-Switch 
            DoubleEnter message
        else
            EchoAndLog DLINE; EchoAndLog I " No spine switch as per rackconfiguration";EchoAndLog DLINE
        fi
        ;;
        
    patch-zfs)
        PatchBasicDetail          
        PasswordCheckFunction
        ClearOldZFSHeadUpdates             
        ZFSHeadDetail                 
        DoubleEnter    message             
        PatchZFSHead                 
        PostCheckZFS
        DoubleEnter message
        ;;
        
    patch-node)
        [[ ! -f ${gc_tmptmp}/noask_$gv_datetime ]]&&  PatchBasicDetail    
        [[ ! -f ${gc_tmptmp}/noask_$gv_datetime ]]&& PasswordCheckFunction || gv_componentlistfile="${gc_tmpdir}/passwdcheck.Successful"
        ListComputeNodes     
        SelectedNodeCheck 
        PatchComputeNode     
        PostCheckComputeNode
        DoubleEnter message
        ;;
        
    patch-ectemplate)
        PatchBasicDetail    
        PasswordCheckFunction        
        PatchVTemplate        
        PostCheckVtemplate
        DoubleEnter message
        ;;
        
    patch-components)
        [[ ! -f ${gc_tmptmp}/noask_$gv_datetime ]]&& PatchBasicDetail    
        [[ ! -f ${gc_tmptmp}/noask_$gv_datetime ]]&& PasswordCheckFunction || gv_componentlistfile="${gc_tmpdir}/passwdcheck.Successful"
        DisplayComponents        
        PreCheckComponents    
        PatchComponents        
        PostCheckComponents    
        ;;
    post-patchcheck)
        PatchBasicDetail    
        PasswordCheckFunction    
        ALLCOMPOENENTPOSTCHECK     
        ;;
            
    patch-nonrolling)
        EchoAndLog A " Currently disabled. will enable once the other option goes smooth"
        Exit 10
        PatchBasicDetail
        PasswordCheckFunction
        PreCheckAllComponents
        PatchAllComponents
        PostCheckAllComponents
        ;;
        
    create-passkey)
        PatchBasicDetail 
        PasswordCheckFunction
        CreateEncryptedPassKeyFile        
        ;;

        
    *) ScriptSyntax ;Exit 10  ;;
    
esac 

}
#-------------------------------------------------------------------
#PROCEDURE    : MainScript
#DESCRIPTION  : Main script fuction
#-------------------------------------------------------------------
MainScript(){                #--- script start here
#-------------- Script starts---------------------------------------##################
EchoAndLog " \t \n You are running Script Version :  $gc_version \n "
[[ $(hostname|awk -F "-" '{print $1}') =~ [CcK][TtA] ]] && RUNENV=jumpgate || RUNENV=node    #--- setting for run env
EchoAndLog  " [INFORMATION] You are running the script on -- $RUNENV \n"
if [[ $RUNENV == jumpgate ]] && [[ ! $1 =~ send-logtoportal ]]
then
    [[ $# -ne 2 ]] && ScriptSyntax     #---- argume checker
    #ping $2 -c 1  >/dev/null 2>&1
    if [[ -f /usr/bin/nc ]]; then        #----------- to check valid node entered or not
        /usr/bin/nc -w 3 -z $2 22 >/dev/null 2>&1
        ar2check=$?
    else
        v_output=$(ssh -o BatchMode=yes -o ConnectTimeout=2  -o StrictHostKeyChecking=no $2  "echo Permission" 2>&1)
        [[ $v_output =~ Permission ]] && ar2check=0 || ar2check=1
    fi
    if [[ $ar2check -ne 0 ]];then EchoAndLog ; EchoAndLog E "$2  is not valid host. mention correct IP or Hostname as per /etc/hosts file \n ";Exit 10 ;fi 
    unset ar2check
    HN=$2
elif [[ $RUNENV == node ]] && [[ ! $1 =~ send-logtoportal ]] 
then 
    [[ $# -ne 2 ]] && ScriptSyntax    #---- argume checker
#    HN=`hostname | awk -F \. '{print $1}'`
    HN=$2
fi
SetEnv $1 $HN
EchoAndLog "\n LogFile:  $gv_logfile \n "


if [[ $RUNENV == node ]] && [[ $1 == "patch-nonrolling" ]]; then EchoAndLog E "Non-rolling patching will work only from Jumpgate. you can use 'patch-components'" ; Exit 10  ; fi

unset rerunfunction
until [[ $rerunfunction == "no" ]];do
    echo "0" >$gc_tmpdir/ECODEFILE
    MainCaseStatement          #------------------------------------- starting the main case  function
    [[ $(cat $gc_tmpdir/ECODEFILE) -ne 0 ]] && Exit 
    sed -i -e 's/\r//g' $gv_logfile
    if [[ $gc_argument1 == patch-components ]] ||[[ $gc_argument1 == patch-node ]] ;then 
        [[ $(cat ${gc_tmptmp}/closecode) -eq 1 ]] && Exit 10
        YesOrNo "Shall i list  the components/node  again for patching "
        [[ $? -eq 0 ]] && rerunfunction=yes || rerunfunction=no
    else 
        rerunfunction=no
    fi 
done

}

MainScript $1 $2  2>&1 | tee -a $gv_logfile
{
[[  $(cat $gv_logfile) =~ 'node1 Name' ]] && \rm $gv_logfile
[[ -f $gv_logfile ]] && EchoAndLog "\n LogFile : $gv_logfile"
RemoveTmpFiles
EchoAndLog DLINE;echo  "Script Completed and Reached End";exit 10;EchoAndLog DLINE
}