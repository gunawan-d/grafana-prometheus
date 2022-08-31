#!/bin/bash

#NB : login as sudo
echo "=============================="
echo "====Installing Grafana========"
echo "=============================="
apt-get update -y
apt-get install -y gnupg2 curl software-properties-common
curl https://packages.grafana.com/gpg.key | sudo apt-key add -
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
apt update
apt -y install grafana
systemctl start grafana-server
systemctl enable grafana-server
systemctl status grafana-server

echo "====Success & run nginx reverse proxy======"


echo "=============================="
echo "====Installing Prometheus====="
echo "=============================="

wget https://github.com/prometheus/prometheus/releases/download/v2.27.1/prometheus-2.27.1.linux-amd64.tar.gz
tar xvf prometheus-2.27.1.linux-amd64.tar.gz
cd prometheus-2.27.1.linux-amd64
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

#move prometheus
mv prometheus promtool /usr/local/bin/
mv consoles/ console_libraries/ /etc/prometheus/
mv prometheus.yml /etc/prometheus/prometheus.yml
prometheus --version
promtool --version

#create group
groupadd --system prometheus
useradd -s /sbin/nologin --system -g prometheus prometheus
chown -R prometheus:prometheus /etc/prometheus/  /var/lib/prometheus/
chmod -R 775 /etc/prometheus/ /var/lib/prometheus/
touch /etc/systemd/system/prometheus.service
cat > /etc/systemd/system/prometheus.service<<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Restart=always
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090

[Install]
WantedBy=multi-user.target
EOF


#check service
systemctl start prometheus
systemctl enable prometheus
systemctl status prometheus