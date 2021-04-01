#! /bin/bash
echo "Running start-up script"
# Auto-Mount Unformatted Block Storage
# NOTE: assumes unformatted disk is largest size (>8Gb)
DISK=`lsblk -d -o NAME -x SIZE -p | awk 'END{print $NF}'`
MOUNTPOINT=/mnt/scratch
mkfs -t ext4 $DISK
mkdir $MOUNTPOINT
mount $DISK $MOUNTPOINT
chown -R ec2-user:users $MOUNTPOINT
chmod -R g+rw $MOUNTPOINT
echo "Ephemeral disk mounted to $MOUNTPOINT"
