#!/usr/bin/env bash

set -x

SRC="$(dirname "$0")"

aws eks update-kubeconfig --name sandbox

helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  -f "${SRC}/external-secrets/helm/values.yaml" \
  --create-namespace \
  --wait

kubectl apply \
  -f "${SRC}/external-secrets/secretstore.yaml" \
  -n external-secrets

kubectl create namespace argocd

kubectl apply \
  -f "${SRC}/argocd/secrets/creds.yaml" \
  -n argocd

helm repo add argo https://argoproj.github.io/argo-helm

helm install \
  argocd \
  argo/argo-cd \
  --version 7.8.20 \
  -f "${SRC}/argocd/helm/values.yaml" \
  -n argocd \
  --wait

kubectl apply \
  -f "${SRC}/argocd/repos/argocd.yaml" \
  -n argocd

# Sleep to give argo time to settle
sleep 10

argocd login \
  --insecure \
  --skip-test-tls \
  --grpc-web \
  --port-forward \
  --port-forward-namespace argocd \
  --username admin

argocd app create apps \
  --dest-namespace argocd \
  --dest-server https://kubernetes.default.svc \
  --repo https://github.com/ianmurphy1/argocd-eks \
  --path argocd-apps \
  --port-forward \
  --port-forward-namespace argocd

ARGO_APPS=(
  apps
  external-dns
  aws-loadbalancer
  argocd
)

for app in "${ARGO_APPS[@]}"; do
  argocd app \
    sync "${app}" \
    --port-forward-namespace argocd \
    --port-forward \
    --async

  sleep 20
done
