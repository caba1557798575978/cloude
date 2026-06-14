#!/bin/bash

echo "=== 部署 Cloud Project 应用到 Kubernetes ==="

# 创建命名空间
echo "1. 创建应用命名空间"
kubectl create namespace cloud-project --dry-run=client -o yaml | kubectl apply -f -

# 部署后端服务
echo "2. 部署后端服务"
kubectl apply -f k8s/backend-deployment.yaml -n cloud-project

# 部署前端服务
echo "3. 部署前端服务"
kubectl apply -f k8s/frontend-deployment.yaml -n cloud-project

echo "4. 等待部署完成"
kubectl wait --namespace cloud-project --for=condition=ready pod \
  --selector=app=backend \
  --timeout=120s

kubectl wait --namespace cloud-project --for=condition=ready pod \
  --selector=app=frontend \
  --timeout=120s

echo "5. 查看部署状态"
kubectl get deployments -n cloud-project
kubectl get pods -n cloud-project
kubectl get svc -n cloud-project

echo ""
echo "=== 应用部署完成 ==="
echo "后端服务: ClusterIP"
echo "前端服务: NodePort"