#!/bin/sh

SOCKS5_IP=${SOCKS5_IP:-127.0.0.1}
SOCKS5_PORT=${SOCKS5:-28888}
RED_TCPORT=${RED_TCPORT:-6666}

sudo apt-get update -y
sudo apt-get install redsocks -y

cat <<EOF | sudo tee /etc/redsocks.conf
base {
 log_debug = on;
 log_info = on;
 log = "file:/root/proxy.log";
 daemon = on;
 redirector = iptables;
}

redsocks {
 local_ip = 0.0.0.0;
 local_port = ${RED_TCPORT};
 ip = $SOCKS5_IP;
 port = $SOCKS5_PORT;
 type = socks5;
}

EOF

sudo apt-get install iptables -y

echo  1 | sudo tee /proc/sys/net/ipv4/ip_forward

sudo iptables -t filter -F
sudo iptables -t mangle -F
sudo iptables -t nat -F

sudo iptables -t nat -N REDSOCKS
sudo iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
sudo iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports ${RED_TCPORT}

sudo iptables -t nat -A OUTPUT -p tcp  -j REDSOCKS
sudo iptables -t nat -A PREROUTING -p tcp  -j REDSOCKS

# NAT for internal network
sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j MASQUERADE

# DNAT all dns query to intel's internal dns server
sudo iptables -t nat -A PREROUTING  -p udp --dport 53  -j DNAT --to-destination 10.248.2.1
# DNAT all internal query to intel's ntp server
sudo iptables -t nat -A PREROUTING  -s 192.168.1.0/24 -p udp --dport 123  -j DNAT --to-destination 10.104.192.16

sudo service redsocks restart
