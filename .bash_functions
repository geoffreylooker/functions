#!/bin/bash

function install_google_cloud_sdk {
  scratch=$(mktemp -d -t tmp.XXXXXXXXXX) || exit 
  script_file=$scratch/install_google_cloud_sdk.bash 
  echo "Downloading Google Cloud SDK install script: $URL" 
  curl -# https://dl.google.com/dl/cloudsdk/channels/rapid/install_google_cloud_sdk.bash > $script_file || exit 
  chmod 775 $script_file 
  if [ -n "$ANDROID_ROOT" ]; then
      termux-fix-shebang $script_file
    fi
  echo "Running install script from: $script_file" 
  $script_file 
}

### start credits: https://github.com/dylanaraps/neofetch/blob/master/neofetch

gettitle() {
    title="${USER:-$(whoami || printf "%s" "${HOME/*\/}")}@${HOSTNAME:-$(hostname)}"
}

getsudo() {
  sudo=""
  if [ ! -w /usr/local/bin ]; then
    sudo=sudo
    echo "Warning: you may be asked for administrator password to save the file in /usr/local/bin directory"
  fi
}

getos() {
    case "$(uname)" in
        "Linux")   os="Linux" ;;
        "Darwin")  os="$(sw_vers -productName)" ;;
        *"BSD" | "DragonFly" | "Bitrig") os="BSD" ;;
        "CYGWIN"*) os="Windows" ;;
        "SunOS") os="Solaris" ;;
        "Haiku") os="Haiku" ;;
        "GNU"*) os="GNU" ;;
        *) printf "%s\n" "Unknown OS detected: $(uname)"; exit 1 ;;
    esac
}

getdistro() {
    [[ "$distro" ]] && return
    distro_shorthand="off"
    getos
    case "$os" in
        "Linux" | "GNU")
            if grep -q -F 'Microsoft' /proc/version >/dev/null || \
               grep -q -F 'Microsoft' /proc/sys/kernel/osrelease >/dev/null; then
                case "$distro_shorthand" in
                    "on")   distro="$(lsb_release -sir) [Windows 10]" ;;
                    "tiny") distro="Windows 10" ;;
                    *)      distro="$(lsb_release -sd) on Windows 10" ;;
                esac
                ascii_distro="Windows 10"

            elif [[ -f "/etc/redstar-release" ]]; then
                case "$distro_shorthand" in
                    "on" | "tiny") distro="Red Star OS" ;;
                    *) distro="Red Star OS $(awk -F'[^0-9*]' '$0=$2' /etc/redstar-release)"
                esac

            elif type -p lsb_release >/dev/null; then
                case "$distro_shorthand" in
                    "on")   lsb_flags="-sir" ;;
                    "tiny") lsb_flags="-si" ;;
                    *)      lsb_flags="-sd" ;;
                esac
                distro="$(lsb_release $lsb_flags)"

            elif type -p guix >/dev/null; then
                distro="GuixSD"

            elif type -p crux >/dev/null; then
                distro="$(crux)"
                case "$distro_shorthand" in
                    "on")   distro="${distro//version}" ;;
                    "tiny") distro="${distro//version*}" ;;
                esac

            elif [[ -d "/system/app/" && -d "/system/priv-app" ]]; then
                distro="Android $(getprop ro.build.version.release)"

            else
                # Source the os-release file
                for file in /etc/*ease /usr/lib/*ease; do
                    source "$file"
                done

                # The 3rd line down matches the fold marker syntax. {{{
                case "$distro_shorthand" in
                    "on") distro="${NAME:-${DISTRIB_ID}} ${VERSION_ID:-${DISTRIB_RELEASE}}" ;;
                    "tiny") distro="${NAME:-${DISTRIB_ID:-${TAILS_PRODUCT_NAME}}}" ;;
                    "off") distro="${PRETTY_NAME:-${DISTRIB_DESCRIPTION}} ${UBUNTU_CODENAME}" ;;
                esac

                # Workarounds for distros that go against the os-release standard.
                [[ -z "${distro// }" ]] && distro="$(awk '/BLAG/ {print $1; exit}' /etc/*ease /usr/lib/*ease)"
                [[ -z "${distro// }" ]] && distro="$(awk -F'=' '{print $2; exit}' /etc/*ease /usr/lib/*ease)"
            fi
            distro="${distro//\"}"
            distro="${distro//\'}"
        ;;

        # "Mac OS X")
            # osx_version="$(sw_vers -productVersion)"
            # osx_build="$(sw_vers -buildVersion)"

            # case "$osx_version" in
                # "10.4"*) codename="Mac OS X Tiger" ;;
                # "10.5"*) codename="Mac OS X Leopard" ;;
                # "10.6"*) codename="Mac OS X Snow Leopard" ;;
                # "10.7"*) codename="Mac OS X Lion" ;;
                # "10.8"*) codename="OS X Mountain Lion" ;;
                # "10.9"*) codename="OS X Mavericks" ;;
                # "10.10"*) codename="OS X Yosemite" ;;
                # "10.11"*) codename="OS X El Capitan" ;;
                # "10.12"*) codename="macOS Sierra" ;;
                # *) codename="macOS" ;;
            # esac
            # distro="$codename $osx_version $osx_build"

            # case "$distro_shorthand" in
                # "on") distro="${distro/ ${osx_build}}" ;;
                # "tiny")
                    # case "$osx_version" in
                        # "10."[4-7]*) distro="${distro/${codename}/Mac OS X}" ;;
                        # "10."[8-9]* | "10.1"[0-1]*) distro="${distro/${codename}/OS X}" ;;
                        # "10.12"*) distro="${distro/${codename}/macOS}" ;;
                    # esac
                    # distro="${distro/ ${osx_build}}"
                # ;;
            # esac
        # ;;

        # "iPhone OS")
            # distro="iOS $(sw_vers -productVersion)"

            # # "uname -m" doesn't print architecture on iOS so we force it off.
            # os_arch="off"
        # ;;

        "BSD")
            case "$distro_shorthand" in
                "tiny" | "on") distro="$(uname -s)" ;;
                *) distro="$(uname -sr)" ;;
            esac

            distro="${distro/DragonFly/DragonFlyBSD}"

            # Workarounds for FreeBSD based distros.
            [[ -f "/etc/pcbsd-lang" ]] && distro="PCBSD"
            [[ -f "/etc/pacbsd-release" ]] && distro="PacBSD"
        ;;

        # "Windows")
            # distro="$(wmic os get Caption /value)"

            # # Strip crap from the output of wmic
            # distro="${distro/Caption'='}"
            # distro="${distro/Microsoft }"
        # ;;

        "Solaris")
            case "$distro_shorthand" in
                "on" | "tiny") distro="$(awk 'NR==1{print $1 " " $2;}' /etc/release)" ;;
                *) distro="$(awk 'NR==1{print $1 " " $2 " " $3;}' /etc/release)" ;;
            esac
            distro="${distro/\(*}"
        ;;

        # "Haiku")
            # distro="$(uname -sv | awk '{print $1 " " $2}')"
        # ;;
    esac

    # Get architecture
    [[ "$os_arch" == "on" ]] && \
        distro+=" $(uname -m)"

    #[[ "${ascii_distro:-auto}" == "auto" ]] && \
    #    ascii_distro="$(trim "$distro")"
}

getscriptdir() {
    [[ "$script_dir" ]] && return

    # Use $0 to get the script's physical path.
    cd "${0%/*}" || exit
    script_dir="${0##*/}"

    # Iterate down a (possible) chain of symlinks.
    while [[ -L "$script_dir" ]]; do
        script_dir="$(readlink "$script_dir")"
        cd "${script_dir%/*}" || exit
        script_dir="${script_dir##*/}"
    done

    # Final directory
    script_dir="$(pwd -P)"
}

getlocalip() {
    case "$os" in
        "Linux")
            localip="$(ip route get 1 | awk '{print $NF;exit}')"
        ;;

        # "Mac OS X" | "iPhone OS")
            # localip="$(ipconfig getifaddr en0)"
            # [[ -z "$localip" ]] && localip="$(ipconfig getifaddr en1)"
        # ;;

        "BSD" | "Solaris")
            localip="$(ifconfig | awk '/broadcast/ {print $2}')"
        ;;

        # "Windows")
            # localip="$(ipconfig | awk -F ': ' '/IPv4 Address/ {printf $2}')"
        # ;;

        # "Haiku")
            # localip="$(ifconfig | awk -F ': ' '/Bcast/ {print $2}')"
            # localip="${localip/', Bcast'}"
        # ;;
    esac
}

getpublicip() {
    if type -p dig >/dev/null; then
        publicip="$(dig +time=1 +tries=1 +short myip.opendns.com @resolver1.opendns.com)"
    fi

    if [[ -z "$publicip" ]] && type -p curl >/dev/null; then
        publicip="$(curl --max-time 10 -w '\n' "$public_ip_host")"
    fi

    if [[ -z "$publicip" ]] && type -p wget >/dev/null; then
        publicip="$(wget -T 10 -qO- "$public_ip_host"; printf "%s")"
    fi
}

### end credits: https://github.com/dylanaraps/neofetch/blob/master/neofetch

### start credits: https://dl.google.com/dl/cloudsdk/release/install_google_cloud_sdk.bash
# cmd: curl -k https://dl.google.com/dl/cloudsdk/release/install_google_cloud_sdk.bash | bash
# forked: https://github.com/geoffreylooker/gceprd/blob/master/install_google_cloud_sdk.bash

trace() {
  echo "$@" >&2
  "$@"
}

download() {
  # $1: The source URL.
  # $2: The local file to write to.
  __download_src=$1
  __download_dst=$2
  if trace which curl >/dev/null; then
    trace curl -k -# -f "$__download_src" > "$__download_dst"
  elif trace which wget >/dev/null; then
    trace wget -O - "$__download_src" > "$__download_dst"
  else
    echo "Either curl or wget must be installed to download files." >&2
    return 1
  fi
}

### end credits: https://dl.google.com/dl/cloudsdk/release/install_google_cloud_sdk.bash


### start credit: https://github.com/termux/termux-packages/blob/47182adc56469c1856a0cb70c76d56f80d2cbae1/scripts/setup-ubuntu.sh

require_pkgs() {
  # common to all os/distro
  PACKAGES=""
  PACKAGES="$PACKAGES wget"			# Used for fetching sources.
  PACKAGES="$PACKAGES curl"			# Used for fetching sources.
  PACKAGES="$PACKAGES git"			# Used by the neovim build.
  PACKAGES="$PACKAGES tar"
  PACKAGES="$PACKAGES unzip"
  # rpm 
  RPM_PACKAGES=""
  RPM_PACKAGES="$RPM_PACKAGES $PACKAGES"		# Include common packages
  RPM_PACKAGES="$RPM_PACKAGES openssh"		# 
  # deb
  APT_PACKAGES=""
  APT_PACKAGES="$APT_PACKAGES $PACKAGES"		# Include common packages
  APT_PACKAGES="$APT_PACKAGES ssh"		    # 
}

  # common to all os/distro
  PACKAGES=""
  PACKAGES="$PACKAGES wget"			# Used for fetching sources.
  PACKAGES="$PACKAGES curl"			# Used for fetching sources.
  PACKAGES="$PACKAGES git"			# Used by the neovim build.
  PACKAGES="$PACKAGES tar"
  PACKAGES="$PACKAGES unzip"
  # rpm 
  RPM_PACKAGES=""
  RPM_PACKAGES="$RPM_PACKAGES $PACKAGES"		# Include common packages
  RPM_PACKAGES="$RPM_PACKAGES openssh"		# 
  # deb
  APT_PACKAGES=""
  APT_PACKAGES="$APT_PACKAGES $PACKAGES"		# Include common packages
  APT_PACKAGES="$APT_PACKAGES ssh"		    # 
  
### end credits: https://github.com/termux/termux-packages/blob/47182adc56469c1856a0cb70c76d56f80d2cbae1/scripts/setup-ubuntu.sh


### start credits: https://github.com/GoogleCloudPlatform/puppetlabs-gce_compute/blob/master/files/puppet-community.sh

rpm_upgrade() {
  getsudo
  echo "== Refreshing rpm packages =="
  if ! $sudo yum update && yum $sudo upgrade; then
    echo "== rpm yum update failed, NOT retrying =="
  fi
}

rpm_install() {
  getsudo
  require_pkgs
  local -r packages=( $@ )
  installed=true
  for package in "${packages[@]}"; do
    if ! $sudo yum list installed "${package}" &>/dev/null; then
      installed=false
      break
    fi
  done
  if [[ "${installed}" == "true" ]]; then
    echo "== ${packages[@]} already installed, skipped rpm install ${packages[@]} =="
    return
  fi

  rpm_upgrade

  if ! $sudo yum -y install $@; then
    echo "== install of packages $@ failed, NOT retrying =="
  fi
}

apt_upgrade() {
  getsudo
  echo "== Refreshing apt packages =="
  if ! $sudo apt-get update && $sudo apt upgrade; then
    echo "== apt update failed, NOT retrying =="
  fi
}

apt_install() {
  getsudo
  require_pkgs
  local -r packages=( $@ )
  installed=true
  for package in "${packages[@]}"; do
    if ! dpkg-query --show "${package}" &>/dev/null; then
      installed=false
      break
    fi
  done
  if [[ "${installed}" == "true" ]]; then
    echo "== ${packages[@]} already installed, skipped apt install ${packages[@]} =="
    return
  fi

  apt_upgrade

  if ! $sudo apt-get -y install $@; then
    echo "== install of packages $@ failed, NOT retrying =="
  fi
}

install_packages() {
  getdistro
  breed=$(echo -n ${distro} | cut -d' ' -f1)
  echo "dist: ${breed}"
  case ${breed} in
    "Redhat")
      rpm_install "${RPM_PACKAGES}" ;;
    "Debian")
      apt_install "${APT_PACKAGES}" ;;
    "Ubuntu")
      apt_install "${APT_PACKAGES}" ;;
  esac
}

### end credits: https://github.com/GoogleCloudPlatform/puppetlabs-gce_compute/blob/master/files/puppet-community.sh

