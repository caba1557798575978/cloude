# Cloud Project 部署指南

## 一、项目概述

本项目包含一个前后端分离的云原生应用：
- **后端**: Flask 应用，提供 REST API
- **前端**: Nginx 托管的静态页面

## 二、本地测试运行

### 2.1 构建镜像

```bash
cd c:\Users\Administrator\Desktop\作业\cloude-project

# 构建后端镜像
docker build -t backend:v1 ./backend

# 构建前端镜像
docker build -t frontend:v1 ./frontend

# 验证镜像
docker images
```

### 2.2 启动服务

```bash
docker compose up
```

### 2.3 验证服务

```bash
# 测试后端 API
curl http://localhost:5000/api/ping
# 预期返回: {"status":"ok"}

# 测试前端页面
curl http://localhost:80
```

### 2.4 停止服务

```bash
# 按 Ctrl + C 停止，或在另一个终端执行
docker compose down
```

## 三、Kubernetes 部署

### 3.1 前提条件

- 已安装 kubectl 并配置好集群访问
- 已创建 SWR 镜像仓库

### 3.2 推送镜像到 SWR

```bash
# 登录 SWR
docker login swr.cn-north-4.myhuaweicloud.com

# 打标签
docker tag backend:v1 swr.cn-north-4.myhuaweicloud.com/cloud-project/backend:v1
docker tag frontend:v1 swr.cn-north-4.myhuaweicloud.com/cloud-project/frontend:v1

# 推送镜像
docker push swr.cn-north-4.myhuaweicloud.com/cloud-project/backend:v1
docker push swr.cn-north-4.myhuaweicloud.com/cloud-project/frontend:v1
```

### 3.3 部署应用

```bash
# 使用脚本部署
bash scripts/deploy-app.sh

# 或手动部署
kubectl create namespace cloud-project
kubectl apply -f k8s/backend-deployment.yaml -n cloud-project
kubectl apply -f k8s/frontend-deployment.yaml -n cloud-project
```

### 3.4 验证部署

```bash
# 查看 Pod 状态
kubectl get pods -n cloud-project

# 查看服务
kubectl get svc -n cloud-project

# 测试后端服务
kubectl port-forward service/backend-service 5000:80 -n cloud-project
curl http://localhost:5000/api/ping
```

## 四、Prometheus + Grafana 监控部署

### 4.1 使用 Helm 部署

```bash
cd monitoring

# 添加 Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 创建命名空间
kubectl create namespace monitoring

# 安装 kube-prometheus-stack
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --version 58.0.0
```

### 4.2 访问 Grafana

```bash
# 获取 Grafana 服务地址
kubectl get svc -n monitoring | grep grafana

# 访问地址
# http://<node-ip>:<node-port>
# 用户名: admin
# 密码: admin
```

### 4.3 导入 Dashboard

推荐导入的 Dashboard:
- **Node Exporter Full**: 1860 (节点监控)
- **Kubernetes Pods**: 10566 (Pod 资源监控)
- **Kubernetes Cluster**: 3119 (集群概览)

## 五、CI/CD 流水线配置

### 5.1 GitHub Actions 配置

在 GitHub 仓库设置 Secrets:
- `SWR_USERNAME`: SWR 用户名
- `SWR_PASSWORD`: SWR 密码
- `KUBECONFIG`: Kubernetes 配置文件内容

### 5.2 流水线流程

```
代码提交 → GitHub Actions → 构建镜像 → 推送 SWR → 更新 K8s Deployment
```

### 5.3 手动触发

```bash
# 查看流水线状态
gh run list

# 手动触发
gh workflow run ci-cd.yaml
```

## 六、常用命令

```bash
# 查看 Pod 日志
kubectl logs <pod-name> -n cloud-project -f

# 进入 Pod
kubectl exec -it <pod-name> -n cloud-project -- /bin/sh

# 查看部署状态
kubectl rollout status deployment/backend -n cloud-project

# 回滚部署
kubectl rollout undo deployment/backend -n cloud-project

# 删除部署
kubectl delete -f k8s/ -n cloud-project
```

## 七、故障排查

### 7.1 Pod 无法启动

```bash
# 查看 Pod 状态
kubectl describe pod <pod-name> -n cloud-project

# 检查镜像是否存在
docker pull swr.cn-north-4.myhuaweicloud.com/cloud-project/backend:v1
```

### 7.2 服务无法访问

```bash
# 检查 Service
kubectl describe svc backend-service -n cloud-project

# 检查网络策略
kubectl get networkpolicy -n cloud-project

# 检查防火墙规则
# 在 CCE 控制台查看安全组配置
```

### 7.3 Prometheus 无法采集指标

```bash
# 检查 ServiceMonitor
kubectl get servicemonitor -n monitoring

# 检查 Prometheus 配置
kubectl get secret prometheus-kube-prometheus-stack-prometheus -n monitoring -o yaml
```