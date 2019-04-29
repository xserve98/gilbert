#!/bin/sh
PKG_URL="github.com/go-gilbert/gilbert"
URL_DOWNLOAD_PREFIX="https://${PKG_URL}/releases/latest/download"
ISSUE_URL="https://${PKG_URL}/issues"
NIL="nil"
GOROOT=${GOROOT:-$(go env GOROOT)}
GOPATH=${GOPATH:-$(go env GOPATH)}
PATH="${PATH}"

RED="\033[0;31m"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

warn() {
    printf "${YELLOW}${1}${NC}\n"
}

panic() {
    printf "${RED}ERROR: ${1}${NC}\n" >&2
    printf "${RED}Installation Failed${NC}\n"
    exit 1
}

contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0
    else
        return 1
    fi
}

check_env() {
    if [ -z "${GOROOT}" ]; then
        panic "GOROOT environment variable is undefined"
    fi

    if ! command -v "git" > /dev/null; then
        panic "Git is not installed"
    fi

    if ! contains "${PATH}" "${GOPATH}/bin"; then
        warn "Go binaries directory '${GOPATH}/bin' is not included in PATH variable!\nPlease run 'export PATH=\$PATH:\$GOPATH/bin' after installation"
        PATH="${PATH}:${GOPATH}/bin"
    fi
}

get_gilbert_name() {
    os=$(uname -s | awk '{print tolower($0)}')
    arc=$(get_arch)
    if [ "${arc}" = "${NIL}" ]; then
        echo "${NIL}"
    else
        echo "gilbert_${os}-${arc}"
    fi
}

get_arch() {
    a=$(uname -m)
    case ${a} in
    "x86_64" | "amd64" )
        echo "amd64"
        ;;
    "i386" | "i486" | "i586")
        echo "386"
        ;;
    *)
        echo ${NIL}
        ;;
    esac
}

compile_install() {
    if ! command -v "go" > /dev/null; then
        panic "go compiler is not installed"
    fi

    if [ -z "${GOPATH}" ]; then
        panic "GOPATH environment variable is undefined"
    fi

    if ! command -v "dep" > /dev/null; then
        warn "dep is not installed, downloading..."
        curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
        local curl_result=$?
        if [ ${curl_result} -ne 0 ]; then
            panic "failed to install 'dep' (${curl_result})"
        fi
    fi

    go get -d ${PKG_URL}
    cd ${GOPATH}/src/${PKG_URL}
    echo "-> Installing dependencies..."
    dep ensure
    echo "-> Building..."
    go build -o ${GOPATH}/bin/gilbert .
    local build_result=$?
    if [ ${build_result} -ne 0 ]; then
        panic "build failed for $(uname -s) $(uname -m) with error $build_result.\nPlease report the issue on ${ISSUE_URL}"
    fi
    echo "-> Installed to '${GOPATH}/bin/gilbert'"
    printf "${GREEN}Done!${NC}\n"
    exit 0
}

main() {
    check_env
    local gb_name=$(get_gilbert_name)
    if [ "$gb_name" = "$NIL" ]; then
        warn "No prebuilt binaries available, trying to compile manually..."
        compile_install
    fi

    local dest_file="${GOPATH}/bin/gilbert"
    local lnk=${URL_DOWNLOAD_PREFIX}/${gb_name}
    echo "-> Downloading '${lnk}'..."
    if ! curl -sS -L -o "${dest_file}" ${lnk}; then
        warn "Download failed, trying to compile manually..."
        compile_install
    fi

    chmod +x ${dest_file}
    echo "-> Successfully installed to '${dest_file}'"
    printf "${GREEN}Done!${NC}\n"
    exit 0
}

main