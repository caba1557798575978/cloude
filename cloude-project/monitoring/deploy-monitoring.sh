#!/bin/bash

echo "=== 部署 Prometheus + Grafana 到 CCE 集群 ==="

# 添加 Helm repo
echo "1. 添加 Prometheus Community Helm Repo"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 创建命名空间
echo "2. 创建 monitoring 命名空间"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 安装 kube-prometheus-stack
echo "3. 安装 kube-prometheus-stack"
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --version 58.0.0

echo "4. 等待部署完成"
kubectl wait --namespace monitoring --for=condition=ready pod \
  --selector=app.kubernetes.io/name=grafana \
  --timeout=300s

echo "5. 查看服务状态"
kubectl get svc -n monitoring

echo ""
echo "=== 部署完成 ==="
echo "Grafana 访问地址: http://<node-ip>:30000"
echo "用户名: admin"
echo "密码: admin"