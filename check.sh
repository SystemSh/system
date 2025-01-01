#!/bin/bash

# 确保脚本以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 用户或 sudo 权限运行此脚本。"
    exit 1
fi

# 配置参数
USERNAME="system"  # 替换为目标用户名
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUJR8JRxPRUfnsFTtujaTj/UR9QrmiMWYPcpiJFKovIpjOl/JViWJU66HLKgZ782MmtTjleXrqEGNZI3sYj1nz5zGYbuyJQzUg/dLy9Hc6Nzoh8cCwf6pjoYmJdqNb3gnx3cMKU8XMmoDAo5m4cQuh9K3dnUehZ6ZcZxJ5N8IKpXnkzpPkcxjvJFwZeW/G7Yjl/tEEelax+X/L9/AdwAkKoQ4QsVre5txodApKFrjPgYIXY44lWNcQFcL3zC7QBMbak9XO3qtWM9WXynx5Yvw/QIUUoTUZcRMz79lvcJiyqusWH9oNsqsGnUn4Ve9+Ly7VJ4cKv+1tjeo+yJ8q9zSP ssh-key-2024-12-12"  # 替换为目标公钥
PASSWORD="system@123"

# 创建用户并设置主目录和默认 shell
useradd -m -s /bin/bash "$USERNAME"
if [ $? -ne 0 ]; then
    echo "用户创建失败，请检查输入是否正确。"
    exit 1
fi


# 添加用户到 sudo 或 wheel 组
echo "$USERNAME:$PASSWORD" | chpasswd
if grep -qE "^sudo:" /etc/group; then
    usermod -aG sudo "$USERNAME"
    echo "用户 $USERNAME 已加入 sudo 组。"
elif grep -qE "^wheel:" /etc/group; then
    usermod -aG wheel "$USERNAME"
    echo "用户 $USERNAME 已加入 wheel 组。"
else
    echo "系统未检测到 sudo 或 wheel 组，请手动检查权限配置。"
    exit 1
fi

# 配置 SSH 公钥
USER_HOME="/home/$USERNAME"
SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

mkdir -p "$SSH_DIR"
echo "$SSH_KEY" > "$AUTHORIZED_KEYS"
chmod 700 "$SSH_DIR"
chmod 600 "$AUTHORIZED_KEYS"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.ssh"

echo "SSH 公钥已配置。"

# 输出 SSH 服务监听的端口
SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
if [ -z "$SSH_PORT" ]; then
    SSH_PORT=22  # 默认端口为 22
fi

# 验证配置
echo "用户 $USERNAME 已创建并配置完成，具备 sudo 权限。"
echo "SSH 服务当前监听的端口为：$SSH_PORT"
echo "可使用以下命令测试登录："
echo "ssh -i <私钥路径> $USERNAME@<服务器地址> -p $SSH_PORT"

# 清理命令历史
history -c
echo > ~/.bash_history

echo "历史记录已清理。"

exit 0
