{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "cifs-share.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cifs-share.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s-%s" .Values.fullnameOverride .Os | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Os | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "cifs-share.pv-fullname" -}}
{{ printf "%s-%s" .Release.Namespace (include "cifs-share.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cifs-share.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cifs-share.labels" -}}
helm.sh/chart: {{ include "cifs-share.chart" . }}
{{ include "cifs-share.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cifs-share.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cifs-share.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cifs-share.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cifs-share.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
