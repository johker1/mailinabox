source /etc/mailinabox.conf # load global vars
source setup/functions.sh # load our functions
if [ ! -f $HOME/.aws/config ]; then
apt_install awscli s3ql
echo "AWS ID"
read awsid
echo "AWS KEY"
read awskey
echo "AWS Region"
read awsregion
echo "Bucket Name"
read bucketname

mkdir $HOME/.aws/
cat > $HOME/.aws/config <<EOF
  [default]
  aws_access_key_id = $awsid
  aws_secret_access_key = $awskey
  region = $awsregion
EOF

cat > /authfile.s3ql <<EOF
[fs3]
storage-url: s3://$bucketname/
backend-login: $awsid
backend-password: $awskey
EOF
chmod 400 /authfile.s3ql

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
    fsck.s3ql --authfile /authfile.s3ql --batch s3://BUCKETNAME/
    exec mount.s3ql --allow-other --authfile /authfile.s3ql s3://BUCKETNAME/ /home/user-data/mail/mailboxes/

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
sed -i -e "s/BUCKETNAME/${bucketname}/g" /etc/init.d/s3ql

chmod +x /etc/init.d/s3ql

echo aws s3api create-bucket --bucket $bucketname --region $awsregion --create-bucket-configuration LocationConstraint=$awsregion | bash

mkfs.s3ql s3://$bucketname/ --authfile /authfile.s3ql --plain

update-rc.d -f s3ql defaults
service s3ql start
update-rc.d s3ql enable >> /dev/null
fi