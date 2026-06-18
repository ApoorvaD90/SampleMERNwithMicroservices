{{- define "streaming-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}
{{- define "streaming-app.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/name: streaming-app
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
{{- define "streaming-app.selectorLabels" -}}
app.kubernetes.io/name: streaming-app
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- define "streaming-app.mongoUrl" -}}
{{- if .Values.profileService.mongodb.url }}
{{- .Values.profileService.mongodb.url }}
{{- else }}
{{- printf "mongodb://%s-mongodb:%d/streaming_app"
    (include "streaming-app.fullname" .) (.Values.mongodb.port | int) }}
{{- end }}
{{- end }}