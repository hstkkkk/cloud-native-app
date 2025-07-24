#!/bin/bash

# Cloud Native Application - 环境设置脚本
# 自动化设置开发环境和验证项目功能

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

# 显示帮助信息
show_help() {
    cat << EOF
云原生应用环境设置脚本

用法: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -i, --install-deps      安装开发依赖
    -b, --build             构建项目
    -t, --test              运行测试
    -d, --docker            构建 Docker 镜像
    -k, --kubernetes        部署到 Kubernetes
    -m, --monitoring        设置监控
    -l, --load-test         执行负载测试
    -c, --clean             清理环境
    -a, --all               执行所有步骤

示例:
    $0 --all                # 执行完整设置流程
    $0 -b -t -d             # 只构建、测试和制作镜像
    $0 --kubernetes         # 只部署到 Kubernetes
EOF
}

# 检查操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            OS="ubuntu"
        elif command -v yum &> /dev/null; then
            OS="centos"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    log_info "检测到操作系统: $OS"
}

# 安装开发依赖
install_dependencies() {
    log_info "开始安装开发依赖..."
    
    case $OS in
        "ubuntu")
            log_info "更新软件包列表..."
            sudo apt update
            
            # 安装 Java 17
            if ! command -v java &> /dev/null; then
                log_info "安装 OpenJDK 17..."
                sudo apt install -y openjdk-17-jdk
            fi
            
            # 安装 Maven
            if ! command -v mvn &> /dev/null; then
                log_info "安装 Maven..."
                sudo apt install -y maven
            fi
            
            # 安装 Docker
            if ! command -v docker &> /dev/null; then
                log_info "安装 Docker..."
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker $USER
                rm get-docker.sh
                log_warning "请重新登录以使 Docker 权限生效"
            fi
            
            # 安装 kubectl
            if ! command -v kubectl &> /dev/null; then
                log_info "安装 kubectl..."
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                rm kubectl
            fi
            
            # 安装 Python 依赖
            if command -v python3 &> /dev/null; then
                log_info "安装 Python 依赖..."
                python3 -m pip install --upgrade pip
                python3 -m pip install -r requirements.txt 2>/dev/null || log_warning "Python 依赖安装可选"
            fi
            ;;
            
        "centos")
            log_info "更新软件包列表..."
            sudo yum update -y
            
            # 安装 Java 17
            if ! command -v java &> /dev/null; then
                log_info "安装 OpenJDK 17..."
                sudo yum install -y java-17-openjdk-devel
            fi
            
            # 安装 Maven
            if ! command -v mvn &> /dev/null; then
                log_info "安装 Maven..."
                sudo yum install -y maven
            fi
            
            # 安装 Docker
            if ! command -v docker &> /dev/null; then
                log_info "安装 Docker..."
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker $USER
                sudo systemctl enable docker
                sudo systemctl start docker
                rm get-docker.sh
            fi
            ;;
            
        "macos")
            # 检查 Homebrew
            if ! command -v brew &> /dev/null; then
                log_info "安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # 安装依赖
            log_info "通过 Homebrew 安装依赖..."
            brew install openjdk@17 maven docker kubectl
            ;;
            
        *)
            log_warning "未知操作系统，请手动安装以下依赖:"
            echo "  - Java 17+"
            echo "  - Maven 3.6+"
            echo "  - Docker"
            echo "  - kubectl"
            ;;
    esac
    
    log_success "依赖安装完成"
}

# 构建项目
build_project() {
    log_info "开始构建项目..."
    
    # 选择 Maven 命令
    if [ -f "./mvnw" ]; then
        maven_cmd="./mvnw"
        log_info "使用 Maven Wrapper"
    elif command -v mvn &> /dev/null; then
        maven_cmd="mvn"
        log_info "使用系统 Maven"
    else
        log_error "未找到 Maven，请先安装"
        return 1
    fi
    
    # 清理和编译
    log_info "清理并编译项目..."
    $maven_cmd clean compile
    
    # 运行测试
    log_info "执行单元测试..."
    $maven_cmd test
    
    # 打包应用
    log_info "打包应用..."
    $maven_cmd package -DskipTests
    
    if [ -f "target/cloud-native-app-1.0.0.jar" ]; then
        log_success "项目构建成功"
        jar_size=$(du -h target/cloud-native-app-1.0.0.jar | cut -f1)
        log_info "JAR 包大小: $jar_size"
    else
        log_error "项目构建失败"
        return 1
    fi
}

# 运行测试
run_tests() {
    log_info "开始运行测试..."
    
    # Maven 测试
    if [ -f "./mvnw" ]; then
        ./mvnw test
    else
        mvn test
    fi
    
    # 集成测试 (可选)
    if [ -f "target/cloud-native-app-1.0.0.jar" ]; then
        log_info "启动应用进行集成测试..."
        
        # 后台启动应用
        java -jar target/cloud-native-app-1.0.0.jar &
        app_pid=$!
        
        # 等待启动
        sleep 10
        
        # 测试接口
        if curl -f http://localhost:8080/api/health &> /dev/null; then
            log_success "集成测试通过"
        else
            log_error "集成测试失败"
        fi
        
        # 停止应用
        kill $app_pid 2>/dev/null || true
    fi
    
    log_success "测试完成"
}

# 构建 Docker 镜像
build_docker() {
    log_info "开始构建 Docker 镜像..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，跳过镜像构建"
        return 1
    fi
    
    # 构建镜像
    log_info "构建 Docker 镜像..."
    docker build -t cloud-native-app:latest .
    
    # 检查镜像
    if docker images cloud-native-app:latest --format "{{.Repository}}" | grep -q cloud-native-app; then
        log_success "Docker 镜像构建成功"
        image_size=$(docker images cloud-native-app:latest --format "{{.Size}}")
        log_info "镜像大小: $image_size"
        
        # 测试运行
        log_info "测试容器运行..."
        container_id=$(docker run -d -p 8081:8080 cloud-native-app:latest)
        sleep 5
        
        if curl -f http://localhost:8081/api/health &> /dev/null; then
            log_success "容器运行测试通过"
        else
            log_warning "容器运行测试失败"
        fi
        
        # 清理测试容器
        docker stop $container_id &> /dev/null || true
        docker rm $container_id &> /dev/null || true
    else
        log_error "Docker 镜像构建失败"
        return 1
    fi
}

# 部署到 Kubernetes
deploy_kubernetes() {
    log_info "开始部署到 Kubernetes..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl 未安装，跳过 Kubernetes 部署"
        return 1
    fi
    
    # 检查集群连接
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到 Kubernetes 集群"
        return 1
    fi
    
    # 创建命名空间
    kubectl create namespace cloud-native --dry-run=client -o yaml | kubectl apply -f -
    
    # 部署 Redis (可选)
    log_info "部署 Redis..."
    kubectl apply -f k8s/redis.yaml -n cloud-native
    
    # 部署应用
    log_info "部署应用..."
    kubectl apply -f k8s/deployment.yaml -n cloud-native
    
    # 等待部署就绪
    log_info "等待 Pod 就绪..."
    kubectl wait --for=condition=ready pod -l app=cloud-native-app -n cloud-native --timeout=300s
    
    # 配置监控
    log_info "配置监控..."
    kubectl apply -f k8s/servicemonitor.yaml -n cloud-native 2>/dev/null || log_warning "ServiceMonitor 需要 Prometheus Operator"
    
    # 配置 HPA
    log_info "配置自动扩容..."
    kubectl apply -f k8s/hpa.yaml -n cloud-native
    
    # 显示部署状态
    log_info "部署状态:"
    kubectl get pods,svc,hpa -n cloud-native
    
    log_success "Kubernetes 部署完成"
}

# 设置监控
setup_monitoring() {
    log_info "开始设置监控..."
    
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl 未安装，跳过监控设置"
        return 1
    fi
    
    # 检查 Prometheus Operator
    if kubectl get crd servicemonitors.monitoring.coreos.com &> /dev/null; then
        log_info "检测到 Prometheus Operator，配置 ServiceMonitor..."
        kubectl apply -f k8s/servicemonitor.yaml -n cloud-native
    else
        log_warning "未检测到 Prometheus Operator"
        echo "如需监控功能，请安装 Prometheus Operator:"
        echo "  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
        echo "  helm install prometheus prometheus-community/kube-prometheus-stack"
    fi
    
    # 显示监控配置建议
    log_info "监控配置建议:"
    echo "1. 导入 Grafana Dashboard: monitoring/grafana-dashboard.json"
    echo "2. 配置 Prometheus 数据源"
    echo "3. 设置告警规则"
    
    log_success "监控设置完成"
}

# 执行负载测试
run_load_test() {
    log_info "开始执行负载测试..."
    
    # 检查应用是否运行
    local app_url="http://localhost:8080"
    
    # 检查 Kubernetes 部署
    if kubectl get svc cloud-native-app -n cloud-native &> /dev/null; then
        log_info "检测到 Kubernetes 部署，使用端口转发..."
        kubectl port-forward svc/cloud-native-app 8080:8080 -n cloud-native &
        port_forward_pid=$!
        sleep 3
    fi
    
    # 检查应用可用性
    if ! curl -f $app_url/api/health &> /dev/null; then
        log_error "应用不可访问: $app_url"
        return 1
    fi
    
    # 执行基础负载测试
    if [ -x "scripts/load-test.sh" ]; then
        log_info "执行 Bash 负载测试..."
        ./scripts/load-test.sh -u $app_url -r 100 -c 5 -t 30
    fi
    
    # 执行高级负载测试
    if [ -x "scripts/advanced_load_test.py" ] && command -v python3 &> /dev/null; then
        log_info "执行 Python 高级负载测试..."
        python3 scripts/advanced_load_test.py --url $app_url --requests 200 --concurrency 10 --duration 60
    fi
    
    # 清理端口转发
    if [ ! -z "$port_forward_pid" ]; then
        kill $port_forward_pid 2>/dev/null || true
    fi
    
    log_success "负载测试完成"
}

# 清理环境
clean_environment() {
    log_info "开始清理环境..."
    
    # 清理 Maven 构建产物
    if [ -f "pom.xml" ]; then
        log_info "清理 Maven 构建产物..."
        if [ -f "./mvnw" ]; then
            ./mvnw clean
        else
            mvn clean 2>/dev/null || true
        fi
    fi
    
    # 清理 Docker 镜像
    if command -v docker &> /dev/null; then
        log_info "清理 Docker 镜像和容器..."
        docker stop $(docker ps -q --filter ancestor=cloud-native-app) 2>/dev/null || true
        docker rm $(docker ps -aq --filter ancestor=cloud-native-app) 2>/dev/null || true
        docker rmi cloud-native-app:latest 2>/dev/null || true
        docker rmi cloud-native-app:test 2>/dev/null || true
    fi
    
    # 清理 Kubernetes 部署
    if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
        log_info "清理 Kubernetes 部署..."
        kubectl delete namespace cloud-native --ignore-not-found=true
    fi
    
    # 清理临时文件
    log_info "清理临时文件..."
    rm -f get-docker.sh
    rm -f kubectl
    
    log_success "环境清理完成"
}

# 执行所有步骤
run_all() {
    log_info "执行完整的设置和验证流程..."
    
    detect_os
    install_dependencies
    build_project
    run_tests
    build_docker
    deploy_kubernetes
    setup_monitoring
    run_load_test
    
    log_success "完整流程执行完成！"
    echo ""
    echo "======================================="
    echo "🎉 云原生应用项目设置完成！"
    echo "======================================="
    echo ""
    echo "📋 后续步骤:"
    echo "  1. 查看应用状态: kubectl get pods -n cloud-native"
    echo "  2. 访问应用接口: kubectl port-forward svc/cloud-native-app 8080:8080 -n cloud-native"
    echo "  3. 设置监控面板: 导入 monitoring/grafana-dashboard.json"
    echo "  4. 查看项目文档: docs/PROJECT_REPORT.md"
    echo ""
    echo "🔧 常用命令:"
    echo "  - 查看日志: kubectl logs -f deployment/cloud-native-app -n cloud-native"
    echo "  - 扩容应用: kubectl scale deployment cloud-native-app --replicas=3 -n cloud-native"
    echo "  - 查看监控: kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo ""
}

# 主函数
main() {
    # 默认不执行任何操作
    local install_deps=false
    local build=false
    local test=false
    local docker=false
    local kubernetes=false
    local monitoring=false
    local load_test=false
    local clean=false
    local all=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--install-deps)
                install_deps=true
                shift
                ;;
            -b|--build)
                build=true
                shift
                ;;
            -t|--test)
                test=true
                shift
                ;;
            -d|--docker)
                docker=true
                shift
                ;;
            -k|--kubernetes)
                kubernetes=true
                shift
                ;;
            -m|--monitoring)
                monitoring=true
                shift
                ;;
            -l|--load-test)
                load_test=true
                shift
                ;;
            -c|--clean)
                clean=true
                shift
                ;;
            -a|--all)
                all=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定参数，显示帮助
    if [[ "$install_deps" == false && "$build" == false && "$test" == false && 
          "$docker" == false && "$kubernetes" == false && "$monitoring" == false && 
          "$load_test" == false && "$clean" == false && "$all" == false ]]; then
        show_help
        exit 0
    fi
    
    # 执行相应的操作
    if [[ "$all" == true ]]; then
        run_all
    else
        detect_os
        
        [[ "$clean" == true ]] && clean_environment
        [[ "$install_deps" == true ]] && install_dependencies
        [[ "$build" == true ]] && build_project
        [[ "$test" == true ]] && run_tests
        [[ "$docker" == true ]] && build_docker
        [[ "$kubernetes" == true ]] && deploy_kubernetes
        [[ "$monitoring" == true ]] && setup_monitoring
        [[ "$load_test" == true ]] && run_load_test
    fi
}

# 脚本入口
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
