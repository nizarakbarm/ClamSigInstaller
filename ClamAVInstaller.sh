#!/bin/bash

#Get latest LTS
if [ ! -f "/usr/bin/html-xml-utils" ]; then
    case $(grep -E '^(NAME)=' /etc/os-release | cut -d"=" -f2 | tr -d '"') in
        Ubuntu|Debian)
            apt install -y html-xml-utils
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

#Install ClamAV for Ubuntu and Debian
install_clamav_ubuntu() {
    #$1 is version
    version="$1"
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
    