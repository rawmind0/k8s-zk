#!/usr/bin/env bash

ZK_DATA_DIR=${ZK_DATA_DIR:-"/opt/zk/data"}
ZK_INIT_LIMIT=${ZK_INIT_LIMIT:-"10"}
ZK_MAX_CLIENT_CXNS=${ZK_MAX_CLIENT_CXNS:-"500"}
ZK_SYNC_LIMIT=${ZK_SYNC_LIMIT:-"5"}
ZK_TICK_TIME=${ZK_TICK_TIME:-"2000"}

RC_NAME=$(echo $HOSTNAME | cut -d"-" -f1)
POD_NAME=$(echo $HOSTNAME)
POD_NAMESPACE=${POD_NAMESPACE:-"default"}

cat << EOF > ${CONF_HOME}/etc/conf.d/myid.toml
[template]
src = "myid.tmpl"
dest = "${ZK_DATA_DIR}/myid"
owner = "${SERVICE_USER}"
mode = "0644"
keys = [
  "/",
]
EOF

cat << EOF > ${CONF_HOME}/etc/templates/myid.tmpl
{{- \$data := json (getv "/pods/${POD_NAMESPACE}/${POD_NAME}") -}}
{{ index (split \$data.status.podIP ".") 3 }}
EOF

cat << EOF > ${CONF_HOME}/etc/conf.d/zoo.cfg.toml
[template]
src = "zoo.cfg.tmpl"
dest = "${SERVICE_HOME}/conf/zoo.cfg"
owner = "${SERVICE_USER}"
mode = "0644"
keys = [
  "/",
]

reload_cmd = "${SERVICE_HOME}/bin/zk-service.sh restart"
EOF

cat << EOF > ${CONF_HOME}/etc/templates/zoo.cfg.tmpl
tickTime=${ZK_TICK_TIME}
initLimit=${ZK_INIT_LIMIT}
syncLimit=${ZK_SYNC_LIMIT}
dataDir=${ZK_DATA_DIR}
maxClientCnxns=${ZK_MAX_CLIENT_CXNS}
clientPort=2181
autopurge.snapRetainCount=3
autopurge.purgeInterval=1
{{- \$data := json (getv "/services/endpoints/${POD_NAMESPACE}/${RC_NAME}") -}}
{{- range \$i, \$subset := \$data.subsets -}}
    {{ range \$subset.addresses }}
server.{{ index (split .ip ".") 3 }}={{.ip}}
        {{- range \$subset.ports -}}
            {{- if eq .name "zk-server" -}}
                :{{.port}}
            {{- end -}}
        {{- end -}}
        {{- range \$subset.ports -}}
            {{- if eq .name "zk-leader" -}}
                :{{.port}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{end}}
EOF