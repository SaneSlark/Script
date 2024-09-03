#!/bin/sh
#Easy install Jopens6.1 in FreeBSD13 by SaneSlark

# 1. Install the third party software
pkg update -y 
pkg upgrade -y   
pkg install -y openjdk11            # 安装Java 11
pkg install -y mysql57-server       # 安装MySQL数据库版本5.7

# 2. Install Jopens6.1
cd /root/jopens                     # 进入安装包文件夹
pkg install -y jopens-libs-*.txz    # 安装jopens组件库
pkg install -y wildfly*.txz         # 安装wildfly组件
pkg install -y jopens-*.txz         # 安装所有jopens文件
pkg install -y gmt*.txz             # 安装GMT模块

# 3. Install vim editor
pkg install -y vim

# End of script
sleep 6

# configure the jopens6.1  
echo " 开始配置各项jopens服务的配置"
echo "-------------------------------------------------"
echo " 1. my.cnf文件添加mysql_conf的字符集和超时设置"
echo "-------------------------------------------------"
# 定义MySQL配置文件的路径
mysql_conf="/usr/local/etc/mysql/my.cnf"

# 替换已有的配置项
sed -i.bak -e 's/^bind-address.*$/bind-address=0.0.0.0/' \
            -e 's/^lower_case_table_names.*$/lower_case_table_names=0/' "$mysql_conf"

# 检查 [mysqld] 部分是否存在
if ! grep -q "^\[mysqld\]" "$mysql_conf"; then
    echo "[mysqld]" >> "$mysql_conf"
fi

# 检查并添加新的配置项到 [mysqld] 部分
for option in "transaction_isolation=READ-COMMITTED" \
              "innodb_lock_wait_timeout=1200" \
              "interactive_timeout=864000" \
              "wait_timeout=864000" \
              "character-set-server=utf8"; do
    if ! grep -q "^$option" "$mysql_conf"; then
        # 使用 awk 在 [mysqld] 部分下添加配置项
        awk -v option="$option" '/^\[mysqld\]/ {print; print option; next}1' "$mysql_conf" > temp_conf && mv temp_conf "$mysql_conf"
    fi
done
echo "MySQL configuration has been updated."
sleep 6

echo "-------------------------------------------------"
echo " 2. rc.conf中配置并激活MySQL、WildFly、box服务"
echo "-------------------------------------------------"
# 定义rc.conf文件的路径
rc_conf="/etc/rc.conf"

# 备份rc.conf文件
rc_conf_bak="/etc/rc.conf.bak"
if [ ! -f "$rc_conf_bak" ]; then
    cp "$rc_conf" "$rc_conf_bak"
    echo "rc.conf has been backed up to rc.conf.bak."
else
    echo "Backup of rc.conf already exists."
fi

# 添加MySQL服务配置
if ! grep -q "^mysql_enable=" "$rc_conf"; then
    echo 'mysql_enable="YES"' >> "$rc_conf"
    echo "MySQL service has been enabled in rc.conf."
else
    echo "MySQL service is already enabled in rc.conf."
fi

# 添加WildFly服务配置
if ! grep -q "^wildfly21_enable=" "$rc_conf"; then
    echo 'wildfly21_enable="YES"' >> "$rc_conf"
    echo 'wildfly21_flags="-Xms4g -Xmx16g -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=512M"' >> "$rc_conf"
    echo 'wildfly21_args="-c standalone-full.xml -Djboss.bind.address=0.0.0.0 -DJOPENS_HOME=/usr/local/jopens -Dagnitude.standard=1999 -Djopens.jeew.maxStn=5000 -Dhawtdispatch.threads=2"' >> "$rc_conf"
    echo 'wildfly21_kill9="YES"' >> "$rc_conf"
    echo 'wildfly21_sleep="600"' >> "$rc_conf"
    echo "WildFly service has been added to rc.conf."
else
    echo "WildFly service is already present in rc.conf."
fi

# 添加mdconfig配置
if ! grep -q "^mdconfig_md0=" "$rc_conf"; then
    echo 'mdconfig_md0="-t malloc -s 1g"' >> "$rc_conf"
    echo 'mdconfig_md0_owner="jopens"' >> "$rc_conf"
    echo 'mdconfig_md0_perms="755"' >> "$rc_conf"
    echo "mdconfig settings have been added to rc.conf."
else
    echo "mdconfig settings are already present in rc.conf."
fi

# 激活box服务
if ! grep -q "^box_enable=" "$rc_conf"; then
    echo 'box_enable="YES"' >> "$rc_conf"
    echo 'box_flags="-Xmx1g -Dcn.org.gddsn.sss.port.MiniSeedStreamEncoder.fast=true"' >> "$rc_conf"
    echo "Box service has been activated in rc.conf."
else
    echo "Box service is already activated in rc.conf."
fi
echo "All configurations have been applied successfully."
sleep 6

echo "-------------------------------------------------"
echo " 3. 初始化mysql数据库，并导入Jopens的mysql脚本" 
echo "-------------------------------------------------"
# 启动MySQL服务
service mysql-server start
sleep 6
# 获取初始密码
cat /root/.mysql_secret
echo "MySQL的初始密码"
echo "-------------------------------------------------"
# 提醒用户更改MySQL root密码
echo "手动输入：ALTER USER 'root'@'localhost' IDENTIFIED BY 'rootme';"
# 提醒用户创建jopens数据库
echo "手动输入：CREATE DATABASE jopens;"
echo "-------------------------------------------------"
# 用户进入MySQL模式
mysql -u root -p

# 循环等待用户按回车键
while true; do
    read -r -p "Press Enter to continue: " input
    if [ -z "$input" ]; then
        break
    else
        echo "Invalid input. Please press Enter to continue."
    fi
done

echo "-------------------------------------------------"
echo "注释掉jopens-6.0-mysql.sql中的特定行"
sed -i.bak '/GRANT ALL ON jopens.* TO root'\''%'\'' IDENTIFIED BY '\''rootme'\'';/s/^/-- /' /usr/local/jopens/lib/schema/jopens-6.0-mysql.sql
echo "-------------------------------------------------"
echo "执行SQL文件来初始化数据库"
mysql -f -u root -p </usr/local/jopens/lib/schema/jopens-6.0-mysql.sql
echo "-------------------------------------------------"
echo "为远程用户注册数据库访问控制权限"
echo "-------------------------------------------------"
echo "手动输入：GRANT ALL ON jopens.* TO 'root'@'192.168.%' IDENTIFIED BY 'rootme';"
echo "手动输入：FLUSH PRIVILEGES;"
echo "-------------------------------------------------"
mysql -u root -p 
echo "Database initialization and remote user access setup completed successfully."

# 循环等待用户按回车键
while true; do
    read -r -p "Press Enter to continue: " input
    if [ -z "$input" ]; then
        break
    else
        echo "Invalid input. Please press Enter to continue."
    fi
done

echo "-------------------------------------------------"
echo " 4. 更改WildFly启动参数和JAVA_OPTS值" 
echo "-------------------------------------------------"
# 定义文件路径
standalone_conf="/usr/local/wildfly21/bin/standalone.conf"
standalone_xml="/usr/local/wildfly21/standalone/configuration/standalone-full.xml"
echo "Copy the original standalone_conf"
cp "$standalone_conf" "$standalone_conf.bak"
cp "$standalone_xml" "$standalone_xml.bak"
echo "Define the new JAVA_OPTS values"
sed -i '' 's/-Xms64m -Xmx512m -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m/-Xms8g -Xmx16g -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=512m/g' "$standalone_conf"
# 更新standalone-full.xml配置
# 替换带有GD字符的省份代码为GU
sed -i '' 's/GD/GU/g' "$standalone_xml"
echo "WildFly configuration has been updated successfully."
sleep 6

echo "-------------------------------------------------"
echo " 5. AWS模块波形数据文件存储目录，并设置权限和符号链接"
echo "-------------------------------------------------"
# 创建存储目录并设置权限
mkdir -p /home/jopens/tank
chown jopens:jopens /home/jopens/tank
# 创建历史记录文件夹
mkdir -p /home/jopens/tank/.history
chown jopens:jopens /home/jopens/tank/.history
# 创建根目录下的/online目录并设置权限
mkdir -p /online
chown jopens:jopens /online
# 创建符号链接
ln -sf /online /home/jopens/tank/online

echo "AWS module directories and permissions have been set up successfully."
sleep 6

echo "-------------------------------------------------"
echo " 6. /etc/fstab文件添加文件系统挂载配置 "
echo "-------------------------------------------------"
# 定义fstab文件的路径
fstab_file="/etc/fstab"
# 备份/etc/fstab文件
cp "$fstab_file" "$fstab_file.bak"

# 检查并添加fdesc挂载点
if ! grep -q "^fdesc[[:space:]]*/dev/fd[[:space:]]*fdescfs" "$fstab_file"; then
    echo "fdesc   /dev/fd         fdescfs         rw      0       0" >> "$fstab_file"
fi
# 检查并添加proc挂载点
if ! grep -q "^proc[[:space:]]*/proc[[:space:]]*procfs" "$fstab_file"; then
    echo "proc    /proc           procfs          rw      0       0" >> "$fstab_file"
fi
# 检查并添加tmpfs挂载点
if ! grep -q "^tmpfs[[:space:]]*/online[[:space:]]*tmpfs" "$fstab_file"; then
    echo "tmpfs   /online         tmpfs           rw,size=2g       0       0" >> "$fstab_file"
fi

# 挂载所有未挂载的挂载点
mount -a
# 显示当前挂载的文件系统
df -h
echo "Mount points have been added to $fstab_file and mounted successfully."
sleep 6

echo "-------------------------------------------------"
echo " 7. /etc/crontab定时任务，每天0点删除365天前的文件"
echo "-------------------------------------------------"
# 定义crontab文件的路径
crontab_file="/etc/crontab"
# 备份/etc/crontab文件
cp "$crontab_file" "$crontab_file.bak"

# 添加定时任务到crontab文件
if ! grep -q "Delete jopens aws expired data" "$crontab_file"; then
    echo "# Delete jopens aws expired data" >> "$crontab_file"
    echo "0 0 * * * root find /home/jopens/tank/waveform -type f -ctime +365d -delete" >> "$crontab_file"
    echo "Crontab task has been added to $crontab_file."
else
    echo "Crontab task already exists in $crontab_file."
fi
echo "The crontab task has been successfully."
sleep 6

echo "-------------------------------------------------"
echo " 8. hosts 自定义修改"
echo "-------------------------------------------------"
# 定义hosts文件和备份文件的路径
hosts_file="/etc/hosts"
hosts_bak="/etc/hosts.bak"

# 备份/etc/hosts文件，如果备份不存在
if [ ! -f "$hosts_bak" ]; then
    cp "$hosts_file" "$hosts_bak"
    echo "The hosts file has been backed up to $hosts_bak."
else
    echo "A backup of the hosts file already exists."
fi

# 获取非本地环回接口的IP地址
new_ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)

# 尝试获取系统的FQDN
domain_name=$(hostname -f)

# 添加新的IP和FQDN映射到/etc/hosts
if ! grep -q "$new_ip" "$hosts_file"; then
    echo "$new_ip $domain_name" >> "$hosts_file"
    echo "New FQDN and IP mapping added to $hosts_file."
else
    echo "The IP mapping already exists in $hosts_file."
fi
tail -n 1 $hosts_file
sleep 6

echo "-------------------------------------------------"
echo " 9. 启动MySQL、WildFly和jopens-box服务"
echo "-------------------------------------------------"

# 启动或重启MySQL服务
echo "Checking MySQL service status."
if service mysql-server status >/dev/null 2>&1; then
    echo "MySQL service is running. Restarting."
    service mysql-server restart
else
    echo "Starting MySQL service."
    service mysql-server start
fi
sleep 6

# 启动或重启WildFly服务
echo "Checking WildFly service status."
if service wildfly21 status >/dev/null 2>&1; then
    echo "WildFly service is running. Restarting."
    service wildfly21 restart
else
    echo "Starting WildFly service."
    service wildfly21 start
fi
sleep 6

# 启动或重启jopens-box服务
echo "Checking jopens-box service status."
if service jopens-box status >/dev/null 2>&1; then
    echo "jopens-box service is running. Restarting."
    service jopens-box restart
else
    echo "Starting jopens-box service."
    service jopens-box start
fi
echo "services have been started successfully."
sleep 6

echo "-------------------------------------------------"
echo " 10. 更新MySQL中ProfileUser表的allowAddr字段"
echo "-------------------------------------------------"
# 更新ProfileUser表
echo "手动输入：UPDATE ProfileUser SET allowAddr='192.168.1.0/24' WHERE user='root';"
echo "-------------------------------------------------"
mysql -u root -p jopens

echo "-------------------------------------------------"
echo "   All services have been started successfully."
echo "-------------------------------------------------"
