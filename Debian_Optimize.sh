#!/bin/bash

echo "
#----------------------------------------------------------
# Debian 系统优化脚本
#
# 作者: SaneSlark (由 ChatGPT AI 驱动)
# 版本: 1.25
# 日期: 2024-08-25
#
# 说明:
#   此脚本用于优化 Debian 系统，提供以下选项：
#     1. 修改提示语
#     2. 更新 apt 源
#     3. 设置全局命令
#     4. 设置 ls 命令(仅限root用户有效)
#     5. 重命名主机名
#     6. 配置网络
#
# 使用方法:
#   1. 运行 chmod +x Debian_Optimize.sh
#   2. 执行 sudo ./Debian_Optimize.sh
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

# 函数定义
# IPv4 地址正则表达式
IPV4_REGEX='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

# 子网掩码正则表达式
SUBNET_MASK_REGEX='^(255\.){3}(0|128|192|224|240|248|252)$|^(255\.){2}(255|254|252|248|240|224|192|128|0)\.0$|^255\.(255|254|252|248|240|224|192|128|0)\.0\.0$'

# 函数：验证 IP 地址格式
validate_ip() {
  local ip="$1"
  # 使用 grep 和 -E 选项来验证 IPv4 地址
  if echo "$ip" | grep -E -q "$IPV4_REGEX"; then
    echo "${GREEN}IP 地址格式正确.${NC}"
    return 0
  else
    echo "${RED}IP 地址格式错误，请检查！ (例如：192.168.1.1)${NC}" >&2
    return 1
  fi
}

# 函数：验证子网掩码格式
validate_subnet_mask() {
  local mask="$1"
  # 使用 grep 和 -E 选项来验证子网掩码
  if echo "$mask" | grep -E -q "$SUBNET_MASK_REGEX"; then
    echo "${GREEN}子网掩码格式正确.${NC}"
    return 0
  else
    echo "${RED}子网掩码格式错误，请检查！ (例如：255.255.255.0)${NC}" >&2
    return 1
  fi
}

# 配置网络
configure_network() {
  echo  "${YELLOW}请选择网络配置方式:${NC}"
  echo  "  ${GREEN}1)${NC} 使用 DHCP 自动获取 IP 地址"
  echo  "  ${GREEN}2)${NC} 手动设置静态 IP 地址"
  read -p "请输入选项 (1-2): " network_option

  case $network_option in
    1)

      local interfacesbak="/etc/network/interfaces.bak"
      
      # 检查 /etc/network/interfaces  是否已备份，如果没有则备份
      if [ ! -f "$interfacesbak" ]; then
          echo "${YELLOW}备份 /etc/network/interfaces 到 $interfacesbak${NC}"
          cp /etc/network/interfaces "$interfacesbak"
      else
          echo "${YELLOW}备份文件 $interfacesbak 已存在，跳过备份操作${NC}"
      fi

      echo  "${YELLOW}正在配置 DHCP 网络...${NC}"

      # 检查是否存在使用DHCP的接口配置
      if grep -q '^iface\s\+[^ ]*\s\+inet\s\+dhcp' /etc/network/interfaces; then
          echo "已存在使用DHCP的接口配置，不执行操作。"
      else
      # 如果不存在使用DHCP的接口配置，则进行以下操作：
      # 将静态IP配置转换为DHCP
      if grep -q '^iface\s[^ ]*\sinet\s\+static' /etc/network/interfaces; then
          sed -i '/^iface\s[^ ]*\sinet\s\+static/s/\(static\)/dhcp/' /etc/network/interfaces
      fi
      fi

      if grep -q 'address\|netmask\|gateway' /etc/network/interfaces; then
          sed -i '/address/d;/netmask/d;/gateway/d' /etc/network/interfaces
      fi

      cat /etc/network/interfaces
      echo  "${GREEN}DHCP 网络配置完成!${NC}"

      read -p "按任意键返回主菜单或输入 q 重启网络并退出脚本: " choice
      if [ "$choice" = "q" -o "$choice" = "Q" ]; then
        systemctl restart networking.service
        exit 0
      else
        main_menu
      fi
      ;;

    2)
      local interfacesbak="/etc/network/interfaces.bak"
      
      # 检查 /etc/network/interfaces  是否已备份，如果没有则备份
      if [ ! -f "$interfacesbak" ]; then
          echo "${YELLOW}备份 /etc/network/interfaces 到 $interfacesbak${NC}"
          cp /etc/network/interfaces "$interfacesbak"
      else
          echo "${YELLOW}备份文件 $interfacesbak 已存在，跳过备份操作${NC}"
      fi

      # 提示用户输入 IP 地址，直到输入有效
      while true; do
        read -p "请输入IP 地址: " ip_address
        if validate_ip "$ip_address"; then
          break
        else
          echo "IP 地址格式不正确，请重新输入。"
        fi
      done
      
      # 提示用户输入子网掩码，直到输入有效
      while true; do
        read -p "子网掩码: " subnet_mask
        if validate_subnet_mask "$subnet_mask"; then
          break
        else
          echo "子网掩码格式不正确，请重新输入。"
        fi
      done
      
      # 提示用户输入网关地址，直到输入有效
      while true; do
        read -p "网关地址: " gateway
        if validate_ip "$gateway"; then
          break
        else
          echo "网关地址格式不正确，请重新输入。"
        fi
      done
      
      # 提示用户输入 DNS 服务器地址，直到输入有效
      while true; do
        read -p "DNS 服务器: " dns_server
        if validate_ip "$dns_server"; then
          break
        else
          echo "DNS 服务器地址格式不正确，请重新输入。"
        fi
      done

      echo  "${YELLOW}正在配置静态 IP 地址...${NC}"
      sleep 3
      # 检查是否存在iface后跟inet static的配置块
      if grep -q '^iface\s\+[^ ]*\s\+inet\s\+static' /etc/network/interfaces; then
          echo "存在静态配置块，开始更新配置..."
          # 如果静态配置块已存在，则更新address、netmask和gateway
          if ! sed -i \
              -e "s/^\(address\s\+\)[0-9.]*/\1$ip_address/" \
              -e "s/^\(netmask\s\+\)[0-9.]*/\1$subnet_mask/" \
              -e "s/^\(gateway\s\+\)[0-9.]*/\1$gateway/" \
              /etc/network/interfaces; then
              echo "更新静态配置失败！"
              exit 1
          fi
      else
          # 如果静态配置块不存在，检查是否存在iface后跟inet dhcp的配置块
          if grep -q '^iface\s\+[^ ]*\s\+inet\s\+dhcp' /etc/network/interfaces; then
              echo "不存在静态配置块，但存在DHCP配置块，开始转换为静态配置..."
              # 将dhcp替换为static，并添加address、netmask和gateway配置
              if ! sed -i \
                  -e "s/^\(iface\s\+[^ ]*\s\+inet\s\+\)dhcp/\1static/" \
                  -e "/^\(iface\s\+[^ ]*\s\+inet\s\+static\)/a\
                  address $ip_address\n\
                  netmask $subnet_mask\n\
                  gateway $gateway" \
                  /etc/network/interfaces; then
                  echo "转换DHCP配置为静态配置失败！"
                  exit 1
              fi
          else
              echo "没有找到iface inet static或iface inet dhcp的配置块，不进行任何操作。"
          fi
      fi
      sleep 3
      # 备份原始的 /etc/resolv.conf 文件
      cp /etc/resolv.conf /etc/resolv.conf.bak
      
      # 将用户输入的 DNS 服务器写入 /etc/resolv.conf 的第一行
      if ! sed -i "1c\nameserver $dns_server" /etc/resolv.conf; then
           echo "修改 /etc/resolv.conf 文件失败！"
           exit 1
      fi
      
      cat /etc/network/interfaces

      echo  "${GREEN}静态 IP 地址配置完成!${NC}"

      read -p "按任意键返回主菜单或输入 q 重启网络并退出脚本: " choice
      if [ "$choice" = "q" -o "$choice" = "Q" ]; then
        systemctl restart networking.service
        exit 0
      else
        main_menu
      fi
      ;;
    *)
      echo  "${RED}无效的选项!${NC}"
      ;;
  esac
}

# 设置全局命令
set_aliases() {

  # 定义文件和备份路径
 
  local profile_bak="/etc/profile.bak"
  local skel_bashrc_bak="/etc/skel/.bashrc.bak"
  
  # 检查 /etc/profile 是否已备份，如果没有则备份
  if [ ! -f "$profile_bak" ]; then
      echo "${YELLOW}备份 /etc/profile 到 $profile_bak${NC}"
      cp /etc/profile "$profile_bak"
  else
      echo "${YELLOW}备份文件 $profile_bak 已存在，跳过备份操作${NC}"
  fi
  # 检查 /etc/skel/.bashrc 是否已备份，如果没有则备份
  if [ ! -f "$skel_bashrc_bak" ]; then
      echo "${YELLOW}备份 /etc/skel/.bashrc 到 $skel_bashrc_bak${NC}"
      cp /etc/skel/.bashrc "$skel_bashrc_bak"
  else
      echo "${YELLOW}备份文件 $skel_bashrc_bak 已存在，跳过备份操作${NC}"
  fi

  echo  "${YELLOW}正在设置全局命令...${NC}"

  sed -i '$i\
  export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:$PATH' /etc/profile
  
  sleep 3

  . /etc/profile
  
  echo  "${YELLOW}正在为用户添加命令...${NC}"
  sed -i "s/^# *alias ll='ls -l'$/alias ll='ls -l'/" /etc/skel/.bashrc
  sed -i "s/^# *alias la='ls -A'$/alias la='ls -A'/" /etc/skel/.bashrc
  sed -i "s/^# *alias l='ls -CF'$/alias l='ls -CF'/" /etc/skel/.bashrc

  sed -i "s/.*# *alias dir='dir --color=auto'.*/alias dir='dir --color=auto'/" /etc/skel/.bashrc

  echo  "${GREEN}设置完成!${NC}"
  read -p "按任意键返回主菜单或输入 q 退出脚本: " choice
  if [ "$choice" = "q" -o "$choice" = "Q" ]; then
    exit 0
  else
    main_menu
  fi
}

# 设置 ls 命令颜色和格式
set_ls_color() {
  echo  "${YELLOW}正在设置 ls 命令颜色和格式...${NC}"
  sleep 3

  sed -i "s/^# export LS_OPTIONS='-\-color=auto'$/export LS_OPTIONS='-\-color=auto'/" /root/.bashrc
  sed -i 's/^# *eval \"$(dircolors)"$/eval \"$(dircolors)"/' /root/.bashrc
  sed -i "s/^# *alias ls='ls \$LS_OPTIONS'$/alias ls='ls \$LS_OPTIONS'/" /root/.bashrc
  sed -i "s/^# *alias ll='ls \$LS_OPTIONS -l'$/alias ll='ls \$LS_OPTIONS -l'/" /root/.bashrc
  sed -i "s/^# *alias l='ls \$LS_OPTIONS -lA'$/alias l='ls \$LS_OPTIONS -lA'/" /root/.bashrc
  
  echo  "${YELLOW}仅限root用户有效${NC}"
  
  . /root/.bashrc
  cat /root/.bashrc
  
  echo  "${GREEN}ls 命令颜色和格式设置完成!${NC}"
  
  sleep 3
  read -p "按任意键返回主菜单或输入 q 退出脚本: " choice
  if [ "$choice" = "q" -o "$choice" = "Q" ]; then
    exit 0
  else
    main_menu
  fi
}

# 更新 apt 源
update_apt_sources() {

# 定义 sources.list 文件路径
  local sources_file="/etc/apt/sources.list"
  local backup_file="/etc/apt/sources.list.bak"

  echo "${YELLOW}检查 sources.list 文件...${NC}"
  sleep 3
  if [ -f "$backup_file" ]; then
    echo "${YELLOW}备份文件已存在，跳过备份操作${NC}"
    sleep 3
  else
    echo "${YELLOW}备份 sources.list 文件到 ${backup_file}${NC}"
    sleep 3
    cp /etc/apt/sources.list "$backup_file"
  fi

  # 使用 grep 检查未注释的 'deb cdrom' 行
  if grep -qE '^deb cdrom' "$sources_file"; then
    # 仅注释掉匹配 'deb cdrom' 的行
    sed -i '/^deb cdrom/s/^/#/' "$sources_file"
    echo "注释 'deb cdrom' 的源"
    sleep 3
  else
    echo "'deb cdrom' 已注释，不需要操作"
  fi
  echo  "${YELLOW}增加国内源...${NC}"

  #echo "deb https://mirrors.ustc.edu.cn/debian/ bullseye main contrib non-free" | tee -a /etc/apt/sources.list > /dev/null

  # 获取系统版本号
  version_id=$(grep -Po 'VERSION_ID="\K.*?(?=")' /etc/os-release)
  
  # 判断版本号并设置软件源
  if [ -z "$version_id" ]; then
      echo "无法获取系统版本号，请检查 /etc/os-release 文件。"
      exit 1
  fi
  
  # 根据系统版本号设置软件源URL
  case "$version_id" in
      12)
          source_url="https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm"
          ;;
      11)
          source_url="https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye"
          ;;
      *)
          echo "不支持的系统版本：$version_id"
          exit 1
          ;;
  esac
  
  # 检查是否已经添加了该软件源
  if grep -q "deb $source_url" /etc/apt/sources.list; then
      echo "软件源 '$source_url' 已存在，不需要重复添加。"
  else
      # 添加软件源
      if echo "deb $source_url main contrib non-free" | tee -a /etc/apt/sources.list > /dev/null; then
          echo "软件源 '$source_url' 添加成功！"
      else
          echo "添加软件源 '$source_url' 失败，请检查权限和路径。"
          exit 1
      fi
  fi

  sleep 3
  
  echo  "${YELLOW}更新 apt 源...${NC}"

  apt update

  echo  "${YELLOW}安装 sudo vim...${NC}"

  apt install sudo vim -y

  echo  "${GREEN}apt 源更新完成!${NC}"

  read -p "按任意键返回主菜单或输入 q 退出脚本: " choice
  if [ "$choice" = "q" -o "$choice" = "Q" ]; then
    exit 0
  else
    main_menu
  fi
}

#重命名主机名
update_hostname() {

  read -p "请输入主机名: " hostname_option

  echo  "${YELLOW}更新主机名...${NC}"
  # 设置主机名
  hostnamectl set-hostname "$hostname_option"
  # 显示新的主机名
  hostname

  echo  "${GREEN}更新完成!${NC}"

  read -p "按任意键返回主菜单或输入 q 退出脚本: " choice
  if [ "$choice" = "q" -o "$choice" = "Q" ]; then
    exit 0
  else
    main_menu
  fi
}

# 修改提示语
modify_prompt() {

  # 定义 sources.list 文件的备份路径
  local backup_motd="/etc/motd.bak"
  if [ -f "$backup_motd" ]; then
    echo "${YELLOW}发现 motd 备份文件已存在，跳过备份操作.${NC}"
  else
    echo "${YELLOW}备份 motd 文件到 ${backup_motd}${NC}"
    cp /etc/motd "$backup_motd"
  fi

  echo  "  ${GREEN}1)${NC} 清空提示语"
  echo  "  ${GREEN}2)${NC} 手动设置提示语"
  read -p "请输入选项 (1-2): " motd_option

  case $motd_option in
    1)
      echo  "${YELLOW}正在清空提示语...${NC}"
      
       > /etc/motd

      echo  "${GREEN}提示语修改完成!${NC}"

      read -p "按任意键返回主菜单或输入 q 退出脚本: " choice
      if [ "$choice" = "q" -o "$choice" = "Q" ]; then
        exit 0
      else
        main_menu
      fi
      ;;

    2)

      # 获取用户输入，并对输入进行简单过滤
      read -p "请输入自定义的 MOTD 内容 (请勿输入命令): " motd_message
      
      # 使用 printf 格式化输出，避免命令注入
      printf "%s" "$motd_message" > /etc/motd
      
      cat /etc/motd
      echo "MOTD 已更新。"

      read -p "按任意键返回主菜单或输入 q 退出脚本: " answer
      if [ "$answer" = "q" -o "$answer" = "Q" ]; then
        exit 0
      else
        main_menu
      fi
      ;;
    *)
      echo  "${RED}无效的选项!${NC}"
      ;;
  esac
}

# 主菜单
main_menu() {
  local choice
  while true; do
    #clear
    echo "
##################################
# Debian 12 系统优化脚本 #
##################################
"
    echo "${YELLOW}请选择要执行的操作:${NC}"
    echo "  ${GREEN}1)${NC} 修改提示语"
    echo "  ${GREEN}2)${NC} 更新 apt 源"
    echo "  ${GREEN}3)${NC} 设置全局命令"
    echo "  ${GREEN}4)${NC} 设置 ls 命令(仅限root用户有效)"
    echo "  ${GREEN}5)${NC} 修改主机名称"
    echo "  ${GREEN}6)${NC} 配置网络"
    echo "  ${GREEN}q)${NC} 退出"

    read -p "请输入选项 (1-6 或 q): " choice

    case $choice in
      1)
        modify_prompt
        ;;
      2)
        update_apt_sources
        ;;
      3)
        set_aliases
        ;;
      4)
        set_ls_color
        ;;
      5)
        update_hostname
        ;;
      6)
        configure_network
        ;;
      q)
        echo "${GREEN}退出脚本.${NC}"
        exit 0
        ;;
      *)
        echo "${RED}无效的选项!${NC}"
        while true; do

        read -p "按任意键返回主菜单 或输入 'q' 退出脚本: " answer

        if [ "$answer" = "q" ] || [ "$answer" = "Q" ]; then
          echo "退出脚本。"
          exit 0
        else
          main_menu
        fi
        done
        ;;
    esac
  done
}

# 调用主菜单
main_menu
