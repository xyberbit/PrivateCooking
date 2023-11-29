DHCP and Static IP Coexistenace  
netsh interface ipv4 set interface interface=*"IF-NAME"* dhcpstaticipcoexistence=enabled  
netsh interface ipv4 add address *"IF-NAME" IP-ADDRESS IP-MASK*  
