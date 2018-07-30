#!/bin/bash
# p2p穿透
ip=$1
if [ $# -ne 1 ];then
    echo "Usage: $0 vip"
    exit
fi

if [ ! -d /etc/n2n ]; then
    mkdir /etc/n2n
fi
for i in git cmake build-essential libcurl4-openssl-dev libssl-dev; do
  which $i > /dev/null
    if [ $? -ne 0 ]; then
      apt -y install $i
  fi
done

git clone https://github.com/meyerd/n2n.git
mkdir n2n/n2n_v2/bin && cd n2n/n2n_v2/bin
cmake .. && make && make install

if [ $? -eq 0 ];then
cat > /lib/systemd/system/n2n_cli.service <<EOF
[Unit]
Description=p2p client
After=network.target

[Service]
EnvironmentFile=/etc/n2n/n2n.conf
ExecStart=/usr/local/sbin/edge -a \$IPADDR -c edge0 -k oeasy -l \$SERVER \$OPTIONS
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/n2n/n2n.conf <<EOF
IPADDR=$ip/8
SERVER="123.58.38.174:6930"
OPTIONS='-f'
EOF
else
    echo "install failed."
    exit
fi


systemctl enable n2n_cli
systemctl start n2n_cli

echo "安装完成,您的远程访问IP为 $ip"
