#!/usr/bin/env bash

SERVICE_TMPL=${SERVICE_TMPL:-"/opt/tools/confd/etc/templates/zoo.cfg.tmpl"}

ZK_DATA_DIR=${ZK_DATA_DIR:-"/opt/zk/data"}
ZK_INIT_LIMIT=${ZK_INIT_LIMIT:-"10"}
ZK_MAX_CLIENT_CXNS=${ZK_MAX_CLIENT_CXNS:-"500"}
ZK_SYNC_LIMIT=${ZK_SYNC_LIMIT:-"5"}
ZK_TICK_TIME=${ZK_TICK_TIME:-"2000"}
ZK_RC_NAME=$(echo $HOSTNAME | cut -d"-" -f1)

cat << EOF > ${SERVICE_TMPL}
tickTime=${ZK_TICK_TIME}
initLimit=${ZK_INIT_LIMIT}
syncLimit=${ZK_SYNC_LIMIT}
dataDir=${ZK_DATA_DIR}
maxClientCnxns=${ZK_MAX_CLIENT_CXNS}
clientPort=2181
autopurge.snapRetainCount=3
autopurge.purgeInterval=1
{{- \$data := json (getv "/services/endpoints/default/${ZK_RC_NAME}") -}}
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
