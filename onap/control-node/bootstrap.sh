sudo apt-get install openvswitch-switch -y
sudo ovs-vsctl add-br br-ex || echo 'Please delete old br-ex using ovs-vsctl del-br br-ex'
ip=$(ip a s ens2f1 | grep inet | grep -v inet6 | sed "s/.*inet//" | cut -f2 -d' ')
sudo ip address flush ens2f1
sudo ovs-vsctl add-port br-ex ens2f1
sudo ip a a $ip dev br-ex
sudo ip link set dev br-ex up
sudo ip link set dev ens2f1 up

#change default route to cloud-client1(192.168.1.1)
sudo ip -4 r add default via 192.168.1.1

echo "-----ip address of all interfaces-----"
sudo ip -4 addr
echo "-----all ip routes-----"
sudo ip -4 route

