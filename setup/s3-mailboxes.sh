source /etc/mailinabox.conf # load global vars
source setup/functions.sh # load our functions

apt_install awscli s3ql
echo "AWS ID"
read awsid
echo "AWS KEY"
read awskey
echo "AWS Region"
read awsregion
echo "Filesystem password"
read fspasswd
echo "Bucket Name"
read bucketname

mkdir $HOME/.aws/
cat > $HOME/.aws/config <<EOF
[default]
aws_access_key_id = $awsid
aws_secret_access_key = $awskey
region = $awsregion
EOF

cat > /root/authfile.s3ql <<EOF
[fs3]
storage-url: s3://$bucketname/
backend-login: $awsid
backend-password: $awskey
fs-passphrase: $fspasswd
EOF
chmod 400 /root/authfile.s3ql

cat > /etc/init.d/s3ql << 'EOF'
#! /bin/sh

### BEGIN INIT INFO
# Provides:          s3ql
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO


case "$1" in
  start)

    # Redirect stdout and stderr into the system log
    DIR=$(mktemp -d)
    mkfifo "$DIR/LOG_FIFO"
    logger -t s3ql -p local0.info < "$DIR/LOG_FIFO" &
    exec > "$DIR/LOG_FIFO"
    exec 2>&1
    rm -rf "$DIR"

    modprobe fuse
    fsck.s3ql --authfile /root/authfile.s3ql --batch s3://johker.xyz-mailboxes/
    exec mount.s3ql --allow-other --authfile /root/authfile.s3ql s3://johker.xyz-mailboxes/ /$

    ;;
  stop)
    umount.s3ql /mnt/s3fs
    ;;
  *)
    echo "Usage: /etc/init.d/s3ql{start|stop}"
    exit 1
    ;;
esac

exit 0
EOF

echo aws s3api create-bucket --bucket $bucketname --region $awsregion -create-bucket-configuration LocationConstraint=$awsregion  bash

mkfs.s3ql s3://$bucketname --authfile /root/authfile.s3ql

update-rc.d -f s3ql default
service s3ql start
update-rc.d s3ql enable