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
