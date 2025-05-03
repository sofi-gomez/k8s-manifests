#!/bin/bash
set -e

# ============================================
# Script de despliegue Kubernetes en Minikube
# Compatible con Linux y Windows (Git Bash)
# ============================================

BASE_DIR="$HOME/tpcloud"
WEB_DIR="$BASE_DIR/static-website"
MANIFESTS_DIR="$BASE_DIR/k8s-manifests"
REPO_WEB="https://github.com/sofi-gomez/static-website.git"
REPO_MANIFESTS="https://github.com/sofi-gomez/k8s-manifests.git"
MAX_ATTEMPTS=15
SLEEP_TIME=2

log() {
    echo "[OK] $1"
}

err() {
    echo "[ERROR] $1" >&2
    exit 1
}

verificar_dependencias() {
    for cmd in git kubectl minikube curl; do
        if ! command -v $cmd >/dev/null; then
            err "$cmd no está instalado. Abortando."
        fi
    done
}

esperar_pod_running() {
    local intentos=0
    while true; do
        if kubectl get pods | grep web | grep -q Running; then
            break
        fi
        sleep "$SLEEP_TIME"
        ((intentos++))
        if [ "$intentos" -gt "$MAX_ATTEMPTS" ]; then
            err "El pod no llegó a estado Running luego de $MAX_ATTEMPTS intentos."
        fi
    done
}

verificar_pvc_montado() {
    kubectl exec deploy/web-deployment -- ls /usr/share/nginx/html/index.html >/dev/null 2>&1 || \
        err "El contenido no se montó correctamente dentro del pod."
}

verificar_pagina_web() {
    local url
    url=$(minikube service static-website-service --url)
    local respuesta
    respuesta=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    if [ "$respuesta" != "200" ]; then
        err "La web no respondió correctamente. Código HTTP: $respuesta"
    fi
    log "Sitio desplegado correctamente. Accedé a: $url"
}

# ============ EJECUCIÓN ============

verificar_dependencias

log "Creando carpetas..."
mkdir -p "$BASE_DIR"
[ ! -d "$WEB_DIR" ] && git clone "$REPO_WEB" "$WEB_DIR" || log "Repositorio web ya clonado."
[ ! -d "$MANIFESTS_DIR" ] && git clone "$REPO_MANIFESTS" "$MANIFESTS_DIR" || log "Repositorio de manifiestos ya clonado."

log "Iniciando Minikube..."
minikube start --driver=docker

# Montaje de carpeta según sistema operativo
log "Montando carpeta con contenido web (en segundo plano)..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows (Git Bash)
    if ! command -v cygpath >/dev/null; then
        err "cygpath no está disponible. Usá Git Bash o instalá cygwin."
    fi
    MOUNT_SRC=$(cygpath -u "$WEB_DIR")
else
    # Linux/macOS
    MOUNT_SRC="$WEB_DIR"
fi

MOUNT_PATH="$MOUNT_SRC:/mnt/static-website"

(minikube mount "$MOUNT_PATH" &) || err "Falló el montaje del volumen en Minikube."

log "Aplicando manifiestos de Kubernetes..."
kubectl apply -f "$MANIFESTS_DIR/volumes/web-pv.yaml"
kubectl apply -f "$MANIFESTS_DIR/volumes/web-pvc.yaml"
kubectl apply -f "$MANIFESTS_DIR/deployments/web-deployment.yaml"
kubectl apply -f "$MANIFESTS_DIR/services/web-service.yaml"

log "Esperando que el pod esté en estado Running..."
esperar_pod_running

log "Verificando montaje del volumen persistente..."
verificar_pvc_montado

log "Verificando accesibilidad de la aplicación web..."
verificar_pagina_web
