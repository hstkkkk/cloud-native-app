#!/bin/bash

# Cloud Native Application - 项目验证脚本
# 用于验证项目各个组件是否正常工作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if command -v $1 &> /dev/null; then
        log_success "$1 已安装"
        $1 --version 2>/dev/null || $1 version 2>/dev/null || echo "版本信息不可用"
        return 0
    else
        log_error "$1 未安装"
        return 1
    fi
}

# 检查端口是否可用
check_port() {
    local port=$1
    if netstat -tlnp 2>/dev/null | grep ":$port " &> /dev/null; then
        log_warning "端口 $port 已被占用"
        return 1
    else
        log_success "端口 $port 可用"
        return 0
    fi
}

# 检查 HTTP 服务
check_http_service() {
    local url=$1
    local expected_status=${2:-200}
    local timeout=${3:-10}
    
    if curl -s -o /dev/null -w "%{http_code}" --max-time $timeout "$url" | grep -q "$expected_status"; then
        log_success "HTTP 服务 $url 正常响应"
        return 0
    else
        log_error "HTTP 服务 $url 无法访问或响应异常"
        return 1
    fi
}

# 主验证流程
main() {
    log_info "开始验证云原生应用项目..."
    echo "======================================="
    
    # 1. 环境依赖检查
    log_info "1. 检查环境依赖..."
    
    local missing_deps=0
    
    # Java 检查
    if check_command java; then
        java_version=$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}')
        if [[ $java_version == 1.8* ]] || [[ $java_version == 17* ]] || [[ $java_version == 21* ]]; then
            log_success "Java 版本兼容: $java_version"
        else
            log_warning "Java 版本可能不兼容: $java_version (推荐 17+)"
        fi
    else
        ((missing_deps++))
    fi
    
    # Maven 检查
    if [ -f "./mvnw" ]; then
        log_success "Maven Wrapper 存在"
        ./mvnw --version | head -n3
    elif check_command mvn; then
        log_success "系统 Maven 可用"
    else
        log_error "Maven 和 Maven Wrapper 都不可用"
        ((missing_deps++))
    fi
    
    # Docker 检查
    check_command docker || ((missing_deps++))
    
    # kubectl 检查
    check_command kubectl || log_warning "kubectl 未安装，跳过 Kubernetes 相关检查"
    
    if [ $missing_deps -gt 0 ]; then
        log_error "存在 $missing_deps 个必需依赖未安装，请先安装后重试"
        exit 1
    fi
    
    echo ""
    
    # 2. 项目结构检查
    log_info "2. 检查项目结构..."
    
    local required_files=(
        "pom.xml"
        "src/main/java/com/example/demo/CloudNativeApplication.java"
        "src/main/java/com/example/demo/controller/HelloController.java"
        "src/main/resources/application.yml"
        "Dockerfile"
        "k8s/deployment.yaml"
        "Jenkinsfile"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_success "文件存在: $file"
        else
            log_error "文件缺失: $file"
        fi
    done
    
    echo ""
    
    # 3. 编译构建检查
    log_info "3. 检查项目编译..."
    
    if [ -f "./mvnw" ]; then
        maven_cmd="./mvnw"
    else
        maven_cmd="mvn"
    fi
    
    log_info "执行: $maven_cmd clean compile"
    if $maven_cmd clean compile -q; then
        log_success "项目编译成功"
    else
        log_error "项目编译失败"
        exit 1
    fi
    
    echo ""
    
    # 4. 单元测试检查
    log_info "4. 执行单元测试..."
    
    log_info "执行: $maven_cmd test"
    if $maven_cmd test -q; then
        log_success "单元测试通过"
    else
        log_error "单元测试失败"
        exit 1
    fi
    
    echo ""
    
    # 5. 打包检查
    log_info "5. 检查项目打包..."
    
    log_info "执行: $maven_cmd package -DskipTests"
    if $maven_cmd package -DskipTests -q; then
        if [ -f "target/cloud-native-app-1.0.0.jar" ]; then
            log_success "JAR 包构建成功"
            jar_size=$(du -h target/cloud-native-app-1.0.0.jar | cut -f1)
            log_info "JAR 包大小: $jar_size"
        else
            log_error "JAR 包未找到"
            exit 1
        fi
    else
        log_error "项目打包失败"
        exit 1
    fi
    
    echo ""
    
    # 6. Docker 镜像构建检查
    if command -v docker &> /dev/null; then
        log_info "6. 检查 Docker 镜像构建..."
        
        if docker build -t cloud-native-app:test . &> /dev/null; then
            log_success "Docker 镜像构建成功"
            
            # 检查镜像大小
            image_size=$(docker images cloud-native-app:test --format "{{.Size}}")
            log_info "镜像大小: $image_size"
            
            # 清理测试镜像
            docker rmi cloud-native-app:test &> /dev/null || true
        else
            log_error "Docker 镜像构建失败"
        fi
        
        echo ""
    fi
    
    # 7. 应用启动检查
    log_info "7. 检查应用启动..."
    
    # 检查端口是否可用
    if ! check_port 8080; then
        log_warning "端口 8080 被占用，跳过应用启动检查"
    else
        log_info "启动应用进行测试..."
        
        # 后台启动应用
        java -jar target/cloud-native-app-1.0.0.jar &
        app_pid=$!
        
        # 等待应用启动
        log_info "等待应用启动 (最多 60 秒)..."
        for i in {1..60}; do
            if check_http_service "http://localhost:8080/api/health" 200 5; then
                break
            fi
            if [ $i -eq 60 ]; then
                log_error "应用启动超时"
                kill $app_pid 2>/dev/null || true
                exit 1
            fi
            sleep 1
        done
        
        # 测试接口
        log_info "测试应用接口..."
        
        # 测试 hello 接口
        hello_response=$(curl -s http://localhost:8080/api/hello)
        if echo "$hello_response" | grep -q "hello"; then
            log_success "Hello 接口正常: $hello_response"
        else
            log_error "Hello 接口异常: $hello_response"
        fi
        
        # 测试健康检查接口
        health_response=$(curl -s http://localhost:8080/api/health)
        if echo "$health_response" | grep -q "UP"; then
            log_success "健康检查接口正常: $health_response"
        else
            log_error "健康检查接口异常: $health_response"
        fi
        
        # 测试监控接口
        if check_http_service "http://localhost:8080/actuator/prometheus" 200 5; then
            log_success "Prometheus 指标端点正常"
        else
            log_error "Prometheus 指标端点异常"
        fi
        
        # 简单限流测试
        log_info "测试限流功能..."
        local rate_limit_triggered=false
        for i in {1..15}; do
            status_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/hello)
            if [ "$status_code" = "429" ]; then
                rate_limit_triggered=true
                break
            fi
            sleep 0.1
        done
        
        if [ "$rate_limit_triggered" = true ]; then
            log_success "限流功能正常工作"
        else
            log_warning "限流功能可能未触发或配置过高"
        fi
        
        # 停止应用
        log_info "停止测试应用..."
        kill $app_pid 2>/dev/null || true
        wait $app_pid 2>/dev/null || true
    fi
    
    echo ""
    
    # 8. Kubernetes 配置检查
    if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
        log_info "8. 检查 Kubernetes 配置..."
        
        # 验证 YAML 文件
        for yaml_file in k8s/*.yaml; do
            if kubectl apply --dry-run=client -f "$yaml_file" &> /dev/null; then
                log_success "YAML 配置有效: $yaml_file"
            else
                log_error "YAML 配置无效: $yaml_file"
            fi
        done
        
        echo ""
    fi
    
    # 9. 脚本权限检查
    log_info "9. 检查脚本权限..."
    
    local scripts=(
        "scripts/load-test.sh"
        "scripts/advanced_load_test.py"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                log_success "脚本可执行: $script"
            else
                log_warning "脚本不可执行: $script (运行 chmod +x $script)"
            fi
        else
            log_error "脚本不存在: $script"
        fi
    done
    
    echo ""
    
    # 验证总结
    log_info "验证完成！"
    echo "======================================="
    log_success "云原生应用项目验证通过"
    echo ""
    log_info "后续步骤:"
    echo "  1. 构建 Docker 镜像: docker build -t cloud-native-app:latest ."
    echo "  2. 部署到 Kubernetes: kubectl apply -f k8s/"
    echo "  3. 配置 CI/CD 流水线"
    echo "  4. 设置监控告警"
    echo "  5. 执行性能测试"
    echo ""
    log_info "文档参考:"
    echo "  - README.md - 项目概述"
    echo "  - docs/DEPLOYMENT_GUIDE.md - 详细部署指南"
    echo ""
}

# 脚本入口
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
