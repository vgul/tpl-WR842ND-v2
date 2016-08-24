#!/bin/bash

set -u

EFFSCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
MY_DIR="$(dirname "${EFFSCRIPT}")"

#LOGIN=adminuser
#PASS=pass
#ROUTER_URL=http://some

CREDENTIALS_FILE="${MY_DIR}/router-data.credentials"

if [ -f "${MY_DIR}/router-data.credentials" ]; then
    source "${CREDENTIALS_FILE}"
    echo $LOGIN > /dev/null
    echo $PASS > /dev/null
    echo $ROUTER_URL > /dev/null
else
    echo "Credentials file '$(basename ${CREDENTIALS_FILE})' not found"
    exit 1
fi

DATA_DIR="${MY_DIR}/Data"
[ ! -d "${DATA_DIR}" ] && { mkdir ${DATA_DIR} ;}



SUFFIX='userRpm'
PASS="$(echo -n "${PASS}" | md5sum )"
PASS="${PASS%% *}"

AUTH_COOKIE0="$(echo -n "${LOGIN}:${PASS}" | base64 )"
AUTH_COOKIE="Authorization=$(echo -n "Basic $AUTH_COOKIE0" | perl -pe's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg');path=/"

function rotate () {
    local FILE="$1"
    local MAX=${2:-90}

    local BODY="$(basename $FILE)"
    local DATA_DIR="$(dirname $FILE)"

    local ROTATE_FLAG=
    [ -e "${FILE}" ] && ROTATE_FLAG=1

    [ -n "${ROTATE_FLAG}" ] && {
      find "${DATA_DIR}" -maxdepth 1 -name ${BODY}\.\* \( -type d -or -type f \) -printf '%f\n' | sort -t '.' -k1 -nr | while read CF; do
        NUM=${CF##*\.}
        #NUM=$(echo ${NUM}|sed -e 's/^0*//g')
        #echo "Found: $CF NUM: $NUM" >&2
        printf -v NEWCF "${BODY}.%d" $((++NUM))
        if ((NUM<=MAX)); then
            [ -d "${DATA_DIR}/${NEWCF}" ] && {
                rm -rf "${DATA_DIR}/${NEWCF}"
            }
          mv "${DATA_DIR}/$CF" "${DATA_DIR}/${NEWCF}"
        else
          [ -e "${DATA_DIR}/$NEWCF" ] && rm -rf "${DATA_DIR}/${NEWCF}"
        fi
      done
      mv "${DATA_DIR}/$BODY"  "${DATA_DIR}/${BODY}.0"
    }
}

INVOKE_DIR="${DATA_DIR}/invoke"
rotate "${INVOKE_DIR}" 12
mkdir "${INVOKE_DIR}"


function get_data {
    local TAG=$1 
    local PARAM=${2:-}

        #--header 'Accept-Language: ru,en-US;q=0.8,en;q=0.6' \
        #--header 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
                    #--header 'Connection: keep-alive' \
    #local \
    #TAG="${URL} ###${ROUTER_URL}/*/}"
    #TAG="${TAG%%\.*}"

    local INVOKE_DATA_DIR="${INVOKE_DIR}/${TAG}"
    mkdir "${INVOKE_DATA_DIR}"

    local DUMP_HEADER="${INVOKE_DATA_DIR}/headers"
    local DUMP_STDERR="${INVOKE_DATA_DIR}/stderr"
    local OUTPUT="${INVOKE_DATA_DIR}/output.html"

    local URL="${ROUTER_URL}/${TOKEN:+${TOKEN}/}${SUFFIX}/${TAG}.htm${PARAM:+?${PARAM}}"

    #echo URL: $URL     >&2
    #echo TAG: $TAG     >&2

    CURL_CMD="curl \
                    --silent \
                    --verbose \
                    --cookie \"${AUTH_COOKIE}\" \
                    --dump-header ${DUMP_HEADER} \
                    --stderr ${DUMP_STDERR} \
                    --output ${OUTPUT} \
                    ${REFERER:+--referer ${REFERER}} \
                \"${URL}\""

    eval "${CURL_CMD}"

    cat "${OUTPUT}" | grep ^var.*new | grep -v Array.*Array | sed -e 's/^var\s\(.\+\) =.*/\1/' | while read VAR; do
        #echo VAR = $VAR >&2
        VAR_DIR="${INVOKE_DATA_DIR}/vars"
        mkdir -p "${VAR_DIR}"
        VAR_FILE="${VAR_DIR}/${VAR}"
        VALUE="$(cat "${OUTPUT}" | perl -ane "\$a .= \$_; END { print \$1 if \$a =~ m/var $VAR = new Array\((.*?)\);.<\/SCRIPT>/s }" | grep -v ^$)" 
        echo "$VALUE" >  $VAR_FILE
    done

    #echo      >&2
    echo "${OUTPUT}"

}

OUTPUT=$(get_data "LoginRpm" "Save=Save")
INDEX_URL="$(cat $OUTPUT | sed -ne 's/.\+\(http:\/\/.\+\)".*/\1/p')"
REFERER=$INDEX_URL

SUBURL=${INDEX_URL#*/}
SUBURL=${SUBURL#*/}
SUBURL=${SUBURL#*/}
TOKEN=${SUBURL%%/*}


TAG='StatusRpm'
#echo $TAG
get_data $TAG  > /dev/null
#find ${INVOKE_DIR}/$TAG/vars/ -type f -ls

[ -f "${MY_DIR}/time-text.sh.inc" ] && {
    source ${MY_DIR}/time-text.sh.inc
}

UPTIME=$(cat ${INVOKE_DIR}/${TAG}/vars/statusPara | sed '5q;d' | sed -e 's/,//')

echo "Uptime: $(time_text $UPTIME "" )"
unset -f time_text

TAG='WlanStationRpm'
get_data $TAG  >/dev/null
cat ${INVOKE_DIR}/${TAG}/vars/hostList | grep -v '^0,0'

exit 0
__END__
