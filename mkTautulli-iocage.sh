#!/bin/bash
#iocage Tautulli jail creation script

#User-defined vars
version='11.2-RELEASE'
name='tautulli'
pkglist='tautullipkglist'
notes='Tautulli: A Plex logging and monitoring application'
#Put your desire MAC address here (useful for DHCP reservations)
macaddr='01234567890a'
#Should point to a dataset in a volume where Tautulli db/files will be stored outside of the jail
tautulli_data_src='/path/on/volume/to/tautullidataset'
#Path to Tautulli db, don't change unless you know what you're doing
tautulli_data_dest='/var/db/tautulli'

#Install nano, ca_root_ns, and tautulli
echo '{"pkgs":["ca_root_nss","tautulli"]}' > /tmp/$pkglist

#Create the jail
iocage create -r $version -n $name -p /tmp/$pkglist vnet='on' host_hostname="$name" boot='on' notes="$notes" \
	interfaces='vnet0:bridge0' dhcp='on' vnet0_mac="$macaddr" bpf='yes'

#Cleanup temp file
rm -f /tmp/$pkglist

#Enable Tautulli on boot and start the service
iocage exec $name "pkg update && pkg upgrade; \
	printf '\n#Tautulli\ntautulli_enable=\"YES\"\n' >> /etc/rc.conf; \
	service tautulli start"

#Stop jail to add mount
iocage stop $name

#Add mountpoint
iocage fstab -a $name "$tautulli_data_src $tautulli_data_dest nullfs ro 0 0"

#Change pkg to use the latest releases instead of quarterly, update pkg repo and upgrade existing pkgs, add rad motd
iocage exec $name "sed -i '' 's/quarterly/latest/' /etc/pkg/FreeBSD.conf; \
	pkg update && pkg upgrade -y; \
	chown -R tautulli:tautulli /var/db/tautulli; \
	tee /etc/motd << 'EOF'
 ______   ______     __  __     ______   __  __     __         __         __    
/\__  _\ /\  __ \   /\ \/\ \   /\__  _\ /\ \/\ \   /\ \       /\ \       /\ \   
\/_/\ \/ \ \  __ \  \ \ \_\ \  \/_/\ \/ \ \ \_\ \  \ \ \____  \ \ \____  \ \ \  
   \ \_\  \ \_\ \_\  \ \_____\    \ \_\  \ \_____\  \ \_____\  \ \_____\  \ \_\ 
    \/_/   \/_/\/_/   \/_____/     \/_/   \/_____/   \/_____/   \/_____/   \/_/ 
                                                                                
EOF"