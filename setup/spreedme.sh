source /etc/mailinabox.conf # load global vars

echo "Adding Spreed ME Web RTc Server Ubuntu Repo and Instalation"
apt-add-repository ppa:strukturag/spreed-webrtc-unstable -y

echo "Adding coturn REPO"
add-apt-repository ppa:fancycode/coturn -y

echo Updating system packages...
hide_output apt-get update
apt_get_quiet upgrade

apt_install spreed-webrtc

echo "Enabling spreedme in rc.local"
echo "service spreed-webrtc start" >> /etc/rc.local
echo "Starting spreedme"
service spreed-webrtc start

echo "Adding turn Server has dependency of Spreed Me"
apt_install coturn

echo "Enabling TURNSERVER"
echo TURNSERVER_ENABLED=1 > /etc/default/coturn

echo "Turn Config"


cat > /etc/turnserver.conf <<'EOF'
no-stun
listening-port=8443
tls-listening-port=3478
fingerprint
lt-cred-mech
use-auth-secret
static-auth-secret=SPREEDSECRET
realm=HOSTNAME
total-quota=100
bps-capacity=0
stale-nonce
no-loopback-peers
no-multicast-peers
EOF

echo "Adding TURNSERVER and spreedme to Webrtc Conf"

cat > /etc/spreed/webrtc.conf<<'EOF'
; Minimal Spreed WebRTC configuration for Nextcloud
[http]
listen = 127.0.0.1:8080
basePath = /webrtc/
root = /usr/share/spreed-webrtc-server/www
[app]
sessionSecret = SSECRET
encryptionSecret = ESECRET
authorizeRoomJoin = true
serverToken = STOKEN
serverRealm = local
extra = /usr/local/lib/owncloud/apps/spreedme/extra
plugin = extra/static/owncloud.js
turnURIs = turn:HOSTNAME:8443?transport=udp turn:HOSTNAME:8443?transport=tcp
turnSecret = SPREEDSECRET 
stunURIs = stun:stun.spreed.me:443 
[users]
enabled = true
mode = sharedsecret
sharedsecret_secret = SPREEDSECRET
EOF

echo "Adding FW rule for 8443"
ufw allow 8443

cp conf/spreed_conf.php /usr/local/lib/owncloud/apps/spreedme/config/config.php

SPREEDSECRET="$(openssl rand -hex 32)"
SSECRET="$(openssl rand -hex 32)"
ESECRET="$(openssl rand -hex 32)"
STOKEN="$(openssl rand -hex 32)"

sed -i -e "s/SSECRET/${SSECRET}/g" /etc/spreed/webrtc.conf
sed -i -e "s/ESECRET/${ESECRET}/g" /etc/spreed/webrtc.conf
sed -i -e "s/STOKEN/${STOKEN}/g" /etc/spreed/webrtc.conf
sed -i -e "s/SPREEDSECRET/${SPREEDSECRET}/g" /etc/spreed/webrtc.conf
sed -i -e "s/HOSTNAME/${PRIMARY_HOSTNAME}/g" /etc/spreed/webrtc.conf

sed -i -e "s/SPREEDSECRET/${SPREEDSECRET}/g" /etc/turnserver.conf
sed -i -e "s/HOSTNAME/${PRIMARY_HOSTNAME}/g" /etc/turnserver.conf

sed -i -e "s/SPREEDSECRET/${SPREEDSECRET}/g" /etc/default/coturn

sed -i -e "s/SPREEDSECRET/${SPREEDSECRET}/g" /usr/local/lib/owncloud/apps/spreedme/config/config.php

sed -i '/public function isSpreedMeAdmin() {/!b;n;creturn true;' /usr/local/lib/owncloud/apps/spreedme/user/user.php

service spreed-webrtc restart
service coturn restart
