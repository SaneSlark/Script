#!/bin/sh

echo "
#----------------------------------------------------------
# Fail2Ban自动安装和配置脚本
#
# 作者: Hehua (由 Google AI 驱动)
# 版本: 1.12
# 日期: 2024-08-08
#
# 说明:
#   此脚本用于多款Linux 系统，提供安全防护，可自动封锁可疑ssh攻击者。
#
# 使用方法:
#   1. 运行 chmod +x Fail2Ban.sh
#   2. 执行 sudo ./Fail2Ban.sh
#-----------------------------------------------------------
"
# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 确保脚本以 root 权限运行
if [ "$HOME" != "/root" ]; then
  echo "${RED} 请以 root 权限运行此脚本!${NC}"
  echo " "
  exit 1
fi

# 自动判断操作系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "debian" ]; then
            # 读取 /etc/os-release 中的 VERSION_ID 变量，获取版本号
            version_id=$VERSION_ID
            # 判断版本号是否为 12
            if [ "$version_id" = "12" ]; then
                os_choice="1"
            # 判断版本号是否为 11
            elif [ "$version_id" = "11" ]; then
                os_choice="2"
            fi
        elif [ "$ID" = "ubuntu" ]; then
            os_choice="2"
        elif [ "$ID_LIKE" = "rhel fedora" ]; then
            os_choice="4"
        fi
    elif [ "$(uname)" = "FreeBSD" ]; then
        os_choice="3"
    else
        os_choice=""
    fi
}

echo "自动检测操作系统类型"
detect_os
sleep 3

# 如果自动检测失败，则提示用户手动选择
if [ -z "$os_choice" ]; then
    echo "自动检测操作系统失败。请选择操作系统类型:"
    echo "1 - Debian"
    echo "2 - Ubuntu"
    echo "3 - FreeBSD"
    echo "4 - CentOS/Fedora/RHEL"
    read -r os_choice
fi

# 根据用户选择执行不同的命令

case "$os_choice" in
    1)
        echo "Installing Fail2Ban on Debian."
        apt-get update
        apt-get install -y fail2ban
        apt-get install -y iptables
        JAIL_CONF_PATH="/etc/fail2ban/jail.conf"
        LOG_PATH="/var/log/journal"
        backend="systemd"
        SERVICE_MANAGER="systemctl"
        ;;

    2)

        echo "Installing Fail2Ban on Ubuntu."
        apt-get update
        apt-get install -y fail2ban
        apt-get install -y iptables
        JAIL_CONF_PATH="/etc/fail2ban/jail.conf"
        LOG_PATH="/var/log/auth.log"
        backend="systemd"
        SERVICE_MANAGER="systemctl"
        ;;
    3)
        echo "Installing Fail2Ban on FreeBSD."
        pkg install -y py39-fail2ban
        JAIL_CONF_PATH="/usr/local/etc/fail2ban/jail.conf"
        LOG_PATH="/var/log/auth.log"
        backend="auto"
        SERVICE_MANAGER="service"
        ;;

    4)
        echo "Installing Fail2Ban on CentOS/Fedora/RHEL."
        yum install -y fail2ban
        JAIL_CONF_PATH="/etc/fail2ban/jail.conf"
        LOG_PATH="/var/log/secure"
        backend="systemd"
        SERVICE_MANAGER="systemctl"
        ;;
    *)
        echo "Unsupported operating system choice."
        exit 1
        ;;
esac

sleep 5

# 通用配置步骤（适用于所有支持的系统）
echo "Copying configuration file."
cp "$JAIL_CONF_PATH" "${JAIL_CONF_PATH%.conf}.local"

# 定义jail.local文件的路径
jail_local="${JAIL_CONF_PATH%.conf}.local"

# 更新sshd jail配置
echo "Updating sshd jail configuration."

# 检查 [sshd] 部分是否存在
if ! grep -q "^\[sshd\]" "$jail_local"; then
    echo "[sshd]" >> "$jail_local"
fi

# 根据操作系统选择sed的原地编辑选项
SED_INPLACE=""
if [ "$os_choice" = "3" ]; then
    SED_INPLACE="-i ''"
else
    SED_INPLACE="-i"
fi

# 使用sed替换port, logpath和backend配置项
sed $SED_INPLACE "/^\[sshd\]/,/^\[/ s|^port.*$|port = ssh|" "$jail_local"
sed $SED_INPLACE "/^\[sshd\]/,/^\[/ s|^logpath.*$|logpath = $LOG_PATH|" "$jail_local"
sed $SED_INPLACE "/^\[sshd\]/,/^\[/ s|^backend.*$|backend = $backend|" "$jail_local"

# 检查并添加新的配置项到 [sshd] 部分
for option in "maxretry = 6" "findtime = 100000" "bantime = 1000000" "enabled = true"; do
    if ! grep -q "^$option" "$jail_local"; then
        # 使用 awk 在 [sshd] 部分下添加配置项
        awk -v option="$option" "/^\[sshd\]/ {print; print option; next}1" "$jail_local" > temp_conf && mv temp_conf "$jail_local"
    fi
done

# 设置Fail2Ban开机自启
echo "Enabling Fail2Ban to start on boot."
if [ "$os_choice" = "3" ]; then
    sysrc fail2ban_enable="YES"
else
    $SERVICE_MANAGER enable fail2ban
fi

# 启动Fail2Ban服务
echo "Starting Fail2Ban service."
if [ "$os_choice" = "3" ]; then
    $SERVICE_MANAGER fail2ban onestart
else
    $SERVICE_MANAGER start fail2ban
fi

# 重启Fail2Ban服务以应用更改
echo "Restarting Fail2Ban service."
if [ "$os_choice" = "3" ]; then
    $SERVICE_MANAGER fail2ban onerestart
else
    $SERVICE_MANAGER restart fail2ban
fi

sleep 5
echo "Fail2Ban installation and basic configuration completed."
