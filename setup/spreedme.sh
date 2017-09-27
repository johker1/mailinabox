echo "Adding Spreed ME Web RTc Server Ubuntu Repo and Instalation"
apt-add-repository ppa:strukturag/spreed-webrtc-unstable -y
apt update
apt dist-upgrade -y
apt install -y spreed-webrtc

echo "Enabling spreedme in rc.local"
echo "service spreed-webrtc start" >> /etc/rc.local
echo "Starting spreedme"
service spreed-webrtc start

echo "Adding coturn REPO"
add-apt-repository ppa:fancycode/coturn -y
apt update
apt dist-upgrade -y

echo "Adding turn Server has dependency of Spreed Me"
apt install coturn -y

echo "Enabling TURNSERVER in Config"
echo TURNSERVER_ENABLED=1 > /etc/default/coturn

echo "Making TURNSERVER in Config"

cat > /etc/turnserver.conf <<'EOF'
no-stun
listening-port=8443
tls-listening-port=3478
fingerprint
lt-cred-mech
use-auth-secret
static-auth-secret=a1bd247113a1713e569c1cba6294eba9ad88bd1281b449420773047fd9137966
realm=$HOSTNAME
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
sessionSecret = a922aa7e7d24fc4db87c73528d8fe3456b903716e4fb80280e42d9ba2ef650e2
encryptionSecret = 692a2e89adc9834c9333bc578f472f5f7be1176e5d78e32c8d403c2c2a2e2676
authorizeRoomJoin = true
serverToken = 3e0b42e59ec1288420c177a53888b11d9c9e5b78930fee5b3b46d2c10679745e
serverRealm = local
extra = /usr/local/lib/owncloud/apps/spreedme/extra
plugin = extra/static/owncloud.js
turnURIs = turn:HOSTNAME:8443?transport=udp turn:HOSTNAME:8443?transport=tcp
turnSecret = a1bd247113a1713e569c1cba6294eba9ad88bd1281b449420773047fd9137966 
stunURIs = stun:stun.spreed.me:443 
[users]
enabled = true
mode = sharedsecret
sharedsecret_secret = 3ea124dcdcf3ca1c1d2dbba48ae525eb9f810abf4329476f98d0a27216a2bff5
EOF

sed -i -e "s/HOSTNAME/${HOSTNAME}/g" /etc/spreed/webrtc.conf

echo "Adding FW rule for 8443"
ufw allow 8443

cp conf/spreed_conf.php /usr/local/lib/owncloud/apps/spreedme/config/config.php