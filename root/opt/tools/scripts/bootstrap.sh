#!/usr/bin/env bash

CONF_NODE_IP=${CONF_NODE_IP:-$(fping -A etcd.kubernetes. | grep alive | cut -d" " -f1)}
export CONF_URL="http://${CONF_NODE_IP}:2379/v2/keys/registry"
export JQ_BIN=${JQ_BIN:-${SERVICE_VOLUME}"/scripts/jq -r"}
export KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)
export KUBE_LABEL_ID="/metadata/labels/zkid"
export LABEL_ID=".metadata.labels.zkid"
export POD_NAME=${POD_NAME:-$HOSTNAME}
export POD_NAMESPACE=${POD_NAMESPACE:-"default"}
export RC_NAME=${RC_NAME:-$(echo $HOSTNAME | cut -d"-" -f1)}
export RC_LOCK_NAME=${RC_LOCK_NAME:-${RC_NAME}"_ZKLOCK"}

function log {
        echo `date` $ME - $@
}

function myZkid {
    curl -Ss ${CONF_URL}/pods/${POD_NAMESPACE}/${HOSTNAME} | ${JQ_BIN} .node.value | ${JQ_BIN} ${LABEL_ID}
}

function putZkid {
    id=$(newZkid)
    new_id=$(cat <<EOF
[
 {
 "op": "add", "path": "${KUBE_LABEL_ID}", "value": "${id}"
 }
]
EOF
)
    resp=$(curl -Ss --insecure --header "Authorization: Bearer $KUBE_TOKEN" --request PATCH --data "$new_id" -H "Content-Type:application/json-patch+json" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/${POD_NAMESPACE}/pods/${HOSTNAME})
    rc=$(echo $resp | ${JQ_BIN} .kind)

    if [ "X$rc" == "XStatus" ]; then
        id=$resp
    fi

    echo $id
}

function getLock {
    log "[ Getting ZKLOCK ... ]"
    resp=$(curl -Ss ${CONF_URL}/controllers/${POD_NAMESPACE}/${RC_LOCK_NAME}?prevExist=false -XPUT -d value=${HOSTNAME} -d ttl=30)
    error=$(echo $resp | ${JQ_BIN} .errorCode)
    counter=0
    max=12
    step=5

    while [ "X$error" != "Xnull" ] && [ $counter -lt $max ]; do
        log "[ Waiting to get ZKLOCK ... ] "
        sleep $step
        resp=$(curl -Ss ${CONF_URL}/controllers/${POD_NAMESPACE}/${RC_LOCK_NAME}?prevExist=false -XPUT -d value=${HOSTNAME} -d ttl=30)
        error=$(echo $resp | ${JQ_BIN} .errorCode)
        log "errorCode: $error - message: $(echo $resp | ${JQ_BIN} .message) - cause: $(echo $resp | ${JQ_BIN} .cause) "
        counter=$(expr $counter + 1)
    done

    if [ "X$error" != "Xnull" ]; then
        log "[ Error getting ZKLOCK ] - Timeout"
        exit 1
    fi
}

function releaseLock {
    log "[ Releasing ZKLOCK ... ]"
    resp=$(curl -Ss ${CONF_URL}/controllers/${POD_NAMESPACE}/${RC_LOCK_NAME}?prevValue=${HOSTNAME} -XDELETE)
    error=$(echo $resp | ${JQ_BIN} .errorCode)

    if [ "X$error" != "Xnull" ]; then
        log "[ Error releasing ZKLOCK ... ]"
        log "errorCode: $error - message: $(echo $resp | ${JQ_BIN} .message) - cause: $(echo $resp | ${JQ_BIN} .cause) "
    fi
}

function newZkid {
    getLock

    for id in {1..255}; do
        for i in $(curl -Ss ${CONF_URL}/services/endpoints/${POD_NAMESPACE}/${RC_NAME} | ${JQ_BIN} .node.value | ${JQ_BIN} .subsets[0].addresses[].targetRef.name) ; do
            g=$(curl -Ss ${CONF_URL}/pods/${POD_NAMESPACE}/${i} | ${JQ_BIN} .node.value | ${JQ_BIN} ${LABEL_ID})
            if [ "X$id" == "X$g" ]; then
                rc="exists"
                break
            fi
        done
        if [ "X$rc" !=  "Xexists" ]; then
            break
        else
            rc="new"
        fi
    done

    releaseLock

    echo $id
}

function waitDeploy {
    log "[ Waiting replicas to be started ... ]"

    current_rep=$(curl -Ss ${CONF_URL}/controllers/${POD_NAMESPACE}/${RC_NAME} | ${JQ_BIN} .node.value | ${JQ_BIN} .status.replicas)
    wanted_rep=$(curl -Ss ${CONF_URL}/controllers/${POD_NAMESPACE}/${RC_NAME} | ${JQ_BIN} .node.value | ${JQ_BIN} .spec.replicas)

    while [ ${current_rep} -ne ${wanted_rep} ]; do
        log "${current_rep} of ${wanted_rep} started replicas....waiting..."
        sleep 3
    done
}

function bootstrapZk {
    waitDeploy

    myid=$(myZkid)
    counter=0
    while [ "X$myid" == "Xnull" ] && [ $counter -lt 5 ]; do
        log "[ Getting new zookeeper id ... ] "
        myid=$(putZkid)
        counter=$(expr $counter + 1)
    done

    if [ "X$myid" == "Xnull" ]; then
        log "[ Error getting zookeeper id ] - Exiting "
        exit 1
    else
        echo $myid
    fi
}

waitDeploy
newZkid

