#!/bin/bash -x
~/devstack/unstack.sh
for instance in `sudo virsh list --all --name`
do sudo virsh destroy $instance
    sudo virsh undefine $instance
done
sudo umount `mount | grep kube | cut -d " " -f 3`
sudo rm -rf /var/lib/docker && sudo rm -rf /opt/stack/data
