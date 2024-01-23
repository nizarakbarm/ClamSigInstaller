#!/bin/bash

#Get latest LTS
if [ ! -f "/usr/bin/html-xml-utils" ]; then
    case $(grep -E '^(NAME)=' /etc/os-release | cut -d"=" -f2 | tr -d '"') in
        Ubuntu|Debian)
            sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
            sed -i "/#\$nrconf{kernelhints} = -1;/s/.*/\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf
            apt install -y html-xml-utils
            sed -i "/\$nrconf{restart} = 'a';/s/.*/#\$nrconf{restart} = 'i';/" /etc/needrestart/needrestart.conf
            sed -i "/\$nrconf{kernelhints} = -1;/s/.*/#\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf
            ;;
        Centos)
            yum install -y html-xml-utils
            ;;
        *)
            echo -n "Unknown error!"
            exit 1
            ;;
    esac
fi
latestlts_release=$(curl -s -A @ua https://www.clamav.net/downloads -L | grep '<span class="badge">LTS</span>' | hxselect -c -s "\n" "h4" | grep -oE "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+" | head -n 1)

configure_clamavdaemon_service() {
    cat <<EOF>"/etc/systemd/system/clamav-daemon.service" <<EOF
[Unit]
Description=Clam AntiVirus userspace daemon
Documentation=man:clamd(8) man:clamd.conf(5) https://docs.clamav.net/
# Check for database existence
ConditionPathExistsGlob=/var/lib/clamav/main.{c[vl]d,inc}
ConditionPathExistsGlob=/var/lib/clamav/daily.{c[vl]d,inc}

[Service]
ExecStart=/usr/local/sbin/clamd --foreground=true
# Reload the database
ExecReload=/bin/kill -USR2 $MAINPID
StandardOutput=syslog
TimeoutStartSec=420

[Install]
WantedBy=multi-user.target
EOF
}

postinstall_clamav() {

    CLAMAV_DIR="/etc/clamav"
    if [ ! -d "$CLAMAV_DIR" ]; then
        mkdir -p -m 0755 "$CLAMAV_DIR"
    fi
    
    CLAMAVD_CONF="$CLAMAV_DIR/clamd.conf"
    CLAMAVROTATEFILE="/etc/logrotate.d/clamav-daemon"
    
    # all variable for clamd.conf
    #AUTOMATICALLY=Generated=by=clamav-daemon=postinst
    #TO=reconfigure=clamd=run=#dpkg-reconfigure=clamav-daemon
    #PLEASE=read=/usr/share/doc/clamav-daemon/README.Debian.gz=for=details
    LOCALSOCKET=/var/run/clamav/clamd.ctl
    FIXSTALESOCKET=true
    LOCALSOCKETGROUP=clamav
    LOCALSOCKETMODE=666
    #=TemporaryDirectory=is=not=set=to=its=default=/tmp=here=to=make=overriding
    #=the=default=with=environment=variables=TMPDIR/TMP/TEMP=possible
    USER=clamav
    SCANMAIL=true
    SCANARCHIVE=true
    ARCHIVEBLOCKENCRYPTED=false
    MAXDIRECTORYRECURSION=15
    FOLLOWDIRECTORYSYMLINKS=false
    FOLLOWFILESYMLINKS=false
    READTIMEOUT=180
    MAXTHREADS=12
    MAXCONNECTIONQUEUELENGTH=15
    LOGSYSLOG=false
    LOGROTATE=true
    LOGFACILITY=LOG_LOCAL6
    LOGCLEAN=false
    LOGVERBOSE=false
    PRELUDEENABLE=no
    PRELUDEANALYZERNAME=ClamAV
    DATABASEDIRECTORY=/var/lib/clamav
    OFFICIALDATABASEONLY=false
    SELFCHECK=3600
    FOREGROUND=false
    DEBUG=false
    SCANPE=true
    MAXEMBEDDEDPE=10M
    SCANOLE2=true
    SCANPDF=true
    SCANHTML=true
    MAXHTMLNORMALIZE=10M
    MAXHTMLNOTAGS=2M
    MAXSCRIPTNORMALIZE=5M
    MAXZIPTYPERCG=1M
    SCANSWF=true
    EXITONOOM=false
    LEAVETEMPORARYFILES=false
    ALGORITHMICDETECTION=true
    SCANELF=true
    IDLETIMEOUT=30
    CROSSFILESYSTEMS=true
    PHISHINGSIGNATURES=true
    PHISHINGSCANURLS=true
    PHISHINGALWAYSBLOCKSSLMISMATCH=false
    PHISHINGALWAYSBLOCKCLOAK=false
    PARTITIONINTERSECTION=false
    DETECTPUA=false
    SCANPARTIALMESSAGES=false
    HEURISTICSCANPRECEDENCE=false
    STRUCTUREDDATADETECTION=false
    COMMANDREADTIMEOUT=30
    SENDBUFTIMEOUT=200
    MAXQUEUE=100
    EXTENDEDDETECTIONINFO=true
    OLE2BLOCKMACROS=false
    ALLOWALLMATCHSCAN=true
    FORCETODISK=false
    DISABLECERTCHECK=false
    DISABLECACHE=false
    MAXSCANTIME=120000
    MAXSCANSIZE=100M
    MAXFILESIZE=25M
    MAXRECURSION=16
    MAXFILES=10000
    MAXPARTITIONS=50
    MAXICONSPE=100
    PCREMATCHLIMIT=10000
    PCRERECMATCHLIMIT=5000
    PCREMAXFILESIZE=25M
    SCANXMLDOCS=true
    SCANHWP3=true
    MAXRECHWP3=16
    STREAMMAXLENGTH=25M
    LOGFILE=/var/log/clamav/clamav.log
    LOGTIME=true
    LOGFILEUNLOCK=false
    LOGFILEMAXSIZE=0
    BYTECODE=true
    BYTECODESECURITY=TrustSigned
    BYTECODETIMEOUT=60000
    ONACCESSMAXFILESIZE=5M

    #create user and group clamav
    groupadd -r $USER
    useradd -g $USER -s /bin/false -c "Clam AntiVirus" $USER

    #create clamd configuration file
    cat >> "$CLAMAVD_CONF" << EOF
LocalSocket $LOCALSOCKET
FixStaleSocket $FIXSTALESOCKET
LocalSocketGroup $LOCALSOCKETGROUP
LocalSocketMode $LOCALSOCKETMODE
User $USER
ScanMail $SCANMAIL
ScanArchive $SCANARCHIVE
ArchiveBlockEncrypted $ARCHIVEBLOCKENCRYPTED
MaxDirectoryRecursion $MAXDIRECTORYRECURSION
FollowDirectorySymlinks $FOLLOWDIRECTORYSYMLINKS
FollowFileSymlinks $FOLLOWFILESYMLINKS
ReadTimeout $READTIMEOUT
MaxThreads $MAXTHREADS
MaxConnectionQueueLength $MAXCONNECTIONQUEUELENGTH
LogSyslog $LOGSYSLOG
LogRotate $LOGROTATE
LogFacility $LOGFACILITY
LogClean $LOGCLEAN
LogVerbose $LOGVERBOSE
PreludeEnable $PRELUDEENABLE
PreludeAnalyzerName $PRELUDEANALYZERNAME
DatabaseDirectory $DATABASEDIRECTORY
OfficialDatabaseOnly $OFFICIALDATABASEONLY
SelfCheck $SELFCHECK
Foreground $FOREGROUND
Debug $DEBUG
ScanPE $SCANPE
MaxEmbeddedPE $MAXEMBEDDEDPE
ScanOLE2 $SCANOLE2
ScanPDF $SCANPDF
ScanHTML $SCANHTML
MaxHTMLNormalize $MAXHTMLNORMALIZE
MaxHTMLNoTags $MAXHTMLNOTAGS
MaxScriptNormalize $MAXSCRIPTNORMALIZE
MaxZipTypeRcg $MAXZIPTYPERCG
ScanSWF $SCANSWF
ExitOnOOM $EXITONOOM
LeaveTemporaryFiles $LEAVETEMPORARYFILES
AlgorithmicDetection $ALGORITHMICDETECTION
ScanELF $SCANELF
IdleTimeout $IDLETIMEOUT
CrossFilesystems $CROSSFILESYSTEMS
PhishingSignatures $PHISHINGSIGNATURES
PhishingScanURLs $PHISHINGSCANURLS
PhishingAlwaysBlockSSLMismatch $PHISHINGALWAYSBLOCKSSLMISMATCH
PhishingAlwaysBlockCloak $PHISHINGALWAYSBLOCKCLOAK
PartitionIntersection $PARTITIONINTERSECTION
DetectPUA $DETECTPUA
ScanPartialMessages $SCANPARTIALMESSAGES
HeuristicScanPrecedence $HEURISTICSCANPRECEDENCE
StructuredDataDetection $STRUCTUREDDATADETECTION
CommandReadTimeout $COMMANDREADTIMEOUT
SendBufTimeout $SENDBUFTIMEOUT
MaxQueue $MAXQUEUE
ExtendedDetectionInfo $EXTENDEDDETECTIONINFO
OLE2BlockMacros $OLE2BLOCKMACROS
AllowAllMatchScan $ALLOWALLMATCHSCAN
ForceToDisk $FORCETODISK
DisableCertCheck $DISABLECERTCHECK
DisableCache $DISABLECACHE
MaxScanTime $MAXSCANTIME
MaxScanSize $MAXSCANSIZE
MaxFileSize $MAXFILESIZE
MaxRecursion $MAXRECURSION
MaxFiles $MAXFILES
MaxPartitions $MAXPARTITIONS
MaxIconsPE $MAXICONSPE
PCREMatchLimit $PCREMATCHLIMIT
PCRERecMatchLimit $PCRERECMATCHLIMIT
PCREMaxFileSize $PCREMAXFILESIZE
ScanXMLDOCS $SCANXMLDOCS
ScanHWP3 $SCANHWP3
MaxRecHWP3 $MAXRECHWP3
StreamMaxLength $STREAMMAXLENGTH
LogFile $LOGFILE
LogTime $LOGTIME
LogFileUnlock $LOGFILEUNLOCK
LogFileMaxSize $LOGFILEMAXSIZE
Bytecode $BYTECODE
BytecodeSecurity $BYTECODESECURITY
BytecodeTimeout $BYTECODETIMEOUT
OnAccessMaxFileSize $ONACCESSMAXFILESIZE
EOF

    #set permission for CLAMAVD_CONF file
    chmod 644 $CLAMAVD_CONF
    chown root:root $CLAMAVD_CONF

    #config logrotate
    if [ -n "$LOGFILE" ]; then
        if echo "$LOGFILE" | grep -q '^/dev/'; then
            make_logrotate=false
        else
            if [ "$LOGROTATE" == "true" ]; then
                make_logrotate=true
            else
                make_logrotate=false
            fi
        fi

        [ -z "$USER" ] && USER=clamav

        if [ "$make_logrotate" == 'true' ]; then
            cat >> "$CLAMAVROTATEFILE" << EOF
$LOGFILE {
     rotate 12
     weekly
     compress
     delaycompress
     create 640  $USER adm
     postrotate
     if [ -d /run/systemd/system ]; then
         systemctl -q is-active clamav-daemon && systemctl kill --signal=SIGHUP clamav-daemon || true
     else
         invoke-rc.d clamav-daemon reload-log > /dev/null || true
     fi
     endscript
     }
EOF

        fi
    fi

}

configure_apparmor() {
    APP_PROFILE="/etc/apparmor.d/usr.local.sbin.clamd"
    if [ -f "$APP_PROFILE" ]; then
        LOCAL_APP_PROFILE="/etc/apparmor.d/local/usr.local.sbin.clamd"

        test -e "$LOCAL_APP_PROFILE" || {
            mkdir -p $(dirname "$LOCAL_APP_PROFILE")
            install --mode 644/dev/null "$LOCAL_APP_PROFILE"
        }

        # Reload the profile, including any abstraction updates
        if aa-enabled --quiet 2>/dev/null; then
            apparmor_parser -r -T -W "$APP_PROFILE"
        fi
    fi
}

#Install ClamAV for Ubuntu and Debian
install_clamav_ubuntu() {
    #$1 is version
    version="$1"

    sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    sed -i "/#\$nrconf{kernelhints} = -1;/s/.*/\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf
    curl -A @ua -o "clamav-$version.linux.x86_64.deb" -L "https://www.clamav.net/downloads/production/clamav-$version.linux.x86_64.deb"
    if [[ $? -ne 0 ]]; then
        echo "Warning: unable to download clamav-$version.linux.x86_64.deb!"
        exit 1
    fi
    dpkg -i "clamav-$version.linux.x86_64.deb"
    if [[ $? -ne 0 ]]; then
        echo "Warning: unable to install clamav-$version.linux.x86_64.deb!"
        exit 1
    fi
    sed -i "/\$nrconf{restart} = 'a';/s/.*/#\$nrconf{restart} = 'i';/" /etc/needrestart/needrestart.conf
    sed -i "/\$nrconf{kernelhints} = -1;/s/.*/#\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf

    postinstall_clamav
    configure_apparmor
}

#Install ClamAV for Centos
install_clamav_centos() {
    #$! is version
    version="$1"

    curl -A @ua -o "clamav-$version.linux.x86_64.rpm" "https://www.clamav.net/downloads/production/clamav-$version.linux.x86_64.rpm"
    if [[ $? -ne 0 ]]; then
        echo "Warning: unable to download clamav-$version.linux.x86_64.rpm!"
        exit 1
    fi
    rpm -i clamav-$version.linux.x86_64.rpm
    if [[ $? -ne 0 ]]; then
        echo "Warning: unable to install clamav-$version.linux.x86_64.rpm!"
        exit 1
    fi

    postinstall_clamav
}

#Download the package based on the OS release
case $(grep -E '^(NAME)=' /etc/os-release | cut -d"=" -f2 | tr -d '"') in
    Ubuntu|Debian)
        install_clamav_ubuntu $latestlts_release
        ;;
    Centos)
        install_clamav_centos $latestlts_release
        ;;
    *)
        echo -n "Unknown error!"
        exit 1
        ;;
esac
    