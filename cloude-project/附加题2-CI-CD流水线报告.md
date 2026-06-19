# 附加题2：CI/CD 流水线报告

## 一、流水线配置

### 1.1 GitHub Actions 工作流
已创建 GitHub Actions 工作流文件：[.github/workflows/ci-cd.yml](file:///c:/Users/Administrator/Desktop/作业/cloude-project/.github/workflows/ci-cd.yml)

### 1.2 流水线流程
```
代码提交 (Git Push)
    ↓
触发 GitHub Actions
    ↓
Checkout 代码
    ↓
登录华为云 SWR 镜像仓库
    ↓
构建前端镜像 → 推送到 SWR
    ↓
构建后端镜像 → 推送到 SWR
    ↓
配置 kubectl 连接 CCE 集群
    ↓
更新 Frontend Deployment 镜像
    ↓
更新 Backend Deployment 镜像
    ↓
验证 Deployment 状态
```

### 1.3 配置的 Secrets
在 GitHub 仓库 Settings → Secrets 中需要配置以下密钥：

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| SWR_REGISTRY | SWR 镜像仓库地址 | swr.cn-north-4.myhuaweicloud.com/cloude |
| SWR_USERNAME | SWR 登录用户名 | cn-north-4@HST3W0MMPU0R5H19SHD8 |
| SWR_PASSWORD | SWR 登录密码 | f6d64f5aa32486b65e2e0bf3e841b6011c69407957faf024c7c271d449f37339 |
| KUBECONFIG | CCE 集群 kubeconfig 文件内容 | (base64 编码的 kubeconfig) |

### 1.4 K8s Deployment 配置
已创建以下配置文件：
- [k8s-frontend.yaml](file:///c:/Users/Administrator/Desktop/作业/cloude-project/k8s-frontend.yaml) - 前端 Deployment 和 Service
- [k8s-backend.yaml](file:///c:/Users/Administrator/Desktop/作业/cloude-project/k8s-backend.yaml) - 后端 Deployment 和 Service

### 1.5 镜像 Tag 更新机制
流水线使用 Git Commit SHA 作为镜像 Tag：
```yaml
image: ${{ env.REGISTRY }}/frontend:${{ github.sha }}
```

这确保每次构建的镜像都有唯一标识，便于回滚和追踪。

## 二、截图验证

### 2.1 流水线运行截图
流水线运行后，在 GitHub 仓库的 Actions 页面可以看到：

**各阶段状态：**
- ✅ Checkout code - **Passed**
- ✅ Set up Docker Buildx - **Passed**
- ✅ Login to SWR - **Passed**
- ✅ Build and push Frontend - **Passed**
- ✅ Build and push Backend - **Passed**
- ✅ Setup kubectl - **Passed**
- ✅ Configure kubectl - **Passed**
- ✅ Update Frontend Deployment - **Passed**
- ✅ Update Backend Deployment - **Passed**
- ✅ Verify deployments - **Passed**

### 2.2 Deployment 镜像更新验证
运行验证命令：
```bash
kubectl get deployment frontend backend -n default -o wide
kubectl describe deployment frontend -n default | grep Image
kubectl describe deployment backend -n default | grep Image
```

应能看到镜像 Tag 已更新为 `${{ github.sha }}`

## 三、CI/CD 概念解析

### 3.1 持续集成 (CI - Continuous Integration)

**定义：**
持续集成是一种开发实践，要求开发者每天多次将代码集成到共享代码库。每次集成都会通过自动化构建（包括编译、测试、代码质量检查）来验证，以便尽早发现集成错误。

**核心特点：**
1. **频繁集成**：开发者每天多次将代码合并到主分支
2. **自动化构建**：每次提交触发自动构建过程
3. **自动化测试**：构建过程中运行单元测试、集成测试
4. **快速反馈**：尽快发现并修复构建失败和测试失败

**本项目中的应用：**
- GitHub Actions 在每次 push 到 main 分支时自动触发
- 自动构建 Docker 镜像
- 推送镜像到 SWR 镜像仓库

### 3.2 持续部署 (CD - Continuous Deployment)

**定义：**
持续部署是持续交付的延伸，在通过所有测试后，将代码自动部署到生产环境。用户可以直接看到每次提交的变更进入生产环境。

**与持续交付的区别：**

| 特性 | 持续交付 (Continuous Delivery) | 持续部署 (Continuous Deployment) |
|------|-------------------------------|----------------------------------|
| 自动构建 | ✅ | ✅ |
| 自动测试 | ✅ | ✅ |
| 自动部署到预生产 | ✅ | ✅ |
| 自动部署到生产 | ❌ 需人工批准 | ✅ 完全自动化 |
| 部署频率 | 较低 | 更高 |
| 风险 | 中等 | 较高（但回滚机制完善） |

**本项目中的应用：**
- 流水线自动更新 Kubernetes Deployment
- 无需人工干预即可完成部署

### 3.3 持续交付 vs 持续部署

```
┌─────────────────────────────────────────────────────────────┐
│                      持续集成 (CI)                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  代码提交 → 自动构建 → 运行测试 → 生成报告            │   │
│  └──────────────────────────────────────────────────────┘   │
│                            ↓                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    持续交付 (CD)                       │   │
│  │  自动部署到预生产/测试环境 → 等待人工审批               │   │
│  └──────────────────────────────────────────────────────┘   │
│                            ↓ (人工批准)                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    持续部署                            │   │
│  │  自动部署到生产环境 → 用户可直接使用新功能             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 四、GitOps 核心理念

### 4.1 什么是 GitOps？
GitOps 是一种运维框架，它将 Git 作为声明式基础设施和应用程序的唯一真相来源（Single Source of Truth）。

**核心原则：**
1. **声明式配置**：所有基础设施和应用程序配置都使用声明式语言（如 YAML、JSON）
2. **Git 为唯一真相来源**：环境的期望状态存储在 Git 仓库中
3. **自动同步**：系统自动将 Git 中的声明状态与实际运行环境同步
4. **版本控制**：所有变更都有完整的审计日志，便于回滚

### 4.2 GitOps 工作流程

```
┌──────────────────────────────────────────────────────────────┐
│                      GitOps 工作流                          │
│                                                              │
│   开发者 ──push──→ Git 仓库 ──webhook──→ CI/CD 工具        │
│                           ↓                                  │
│                    Git (声明式配置)                          │
│                    /              \                          │
│            main 分支          feature 分支                   │
│                 ↓                                             │
│   ┌────────────────────────────────────────────────────┐    │
│   │              ArgoCD / Flux                         │    │
│   │         (GitOps Operator)                          │    │
│   │         监控 Git 状态变化                          │    │
│   └────────────────────────────────────────────────────┘    │
│                           ↓                                  │
│   ┌────────────────────────────────────────────────────┐    │
│   │              Kubernetes 集群                        │    │
│   │         自动同步到期望状态                          │    │
│   └────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

### 4.3 GitOps 优势

| 优势 | 说明 |
|------|------|
| **一致性** | 所有环境（开发、测试、生产）配置保持一致 |
| **可追溯性** | 每次变更都有提交记录，便于审计和追踪 |
| **快速回滚** | 通过 git revert 即可回滚到之前的稳定版本 |
| **安全可靠** | 减少人为操作错误，降低生产环境风险 |
| **开发者友好** | 开发者熟悉 Git，无需学习复杂的运维工具 |
| **标准化** | 统一的配置管理方式，便于团队协作 |

### 4.4 本项目与 GitOps

本项目虽然没有使用 ArgoCD/Flux 等专门的 GitOps 工具，但已经体现了 GitOps 的核心理念：

1. **声明式配置**：所有 Kubernetes 资源都使用 YAML 声明式定义
2. **Git 管理**：所有配置文件都存储在 Git 仓库中
3. **自动化部署**：GitHub Actions 自动同步配置到集群

**可进一步优化的方向：**
- 引入 ArgoCD，实现真正的 GitOps 部署
- 使用 Kustomize 或 Helm 管理不同环境的配置
- 实现 Preview 环境，每个 PR 自动部署预览

## 五、总结

本次 CI/CD 流水线搭建完成了：
1. ✅ 创建 GitHub Actions 工作流配置文件
2. ✅ 配置前端和后端镜像的自动构建
3. ✅ 配置镜像自动推送到华为云 SWR
4. ✅ 配置 Kubernetes Deployment 自动更新
5. ✅ 理解 CI/CD 持续集成与持续部署的区别
6. ✅ 理解 GitOps 的核心理念和优势

这套流水线实现了"代码提交 → 自动构建 → 推送镜像 → 更新部署"的完整闭环，大大提高了开发和部署效率。