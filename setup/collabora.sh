source /etc/mailinabox.conf # load global vars

echo "Installing Docker for Collabora"
apt install docker.io -y

echo "Adding PPA for Canonical Kernel Team and installing linux-virtual-lts-xenial (Collabora dependency)"
add-apt-repository ppa:canonical-kernel-team/ppa -y
apt-get update
apt install linux-virtual-lts-xenial -y


echo "Installing Collabora code (docker)"
docker pull collabora/code
COLLABORA_DOCKER="docker run -t -d -p 127.0.0.1:9980:9980 -e 'domain=$(echo $PRIMARY_HOSTNAME | sed -e 's/\./\\\\\./g')' --restart always --cap-add MKNOD collabora/code"
echo $COLLABORA_DOCKER | bash

echo "Generating Nginx proxy configuration for Collabora"
cat > /etc/nginx/conf.d/collabora.conf <<'EOF'
server {
    listen       80;
    server_name  collabora.PRIMAHOSTNAME;
    # static files
    location ^~ /loleaflet {
        proxy_pass https://localhost:9980;
        proxy_set_header Host $http_host;
    }
    # WOPI discovery URL
    location ^~ /hosting/discovery {
        proxy_pass https://localhost:9980;
        proxy_set_header Host $http_host;
    }
   # main websocket
   location ~ ^/lool/(.*)/ws$ {
       proxy_pass https://localhost:9980;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "Upgrade";
       proxy_set_header Host $http_host;
       proxy_read_timeout 36000s;
   }
   # download, presentation and image upload
   location ~ ^/lool {
       proxy_pass https://localhost:9980;
       proxy_set_header Host $http_host;
   }
   # Admin Console websocket
   location ^~ /lool/adminws {
       proxy_pass https://localhost:9980;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "Upgrade";
       proxy_set_header Host $http_host;
       proxy_read_timeout 36000s;
   }
}
EOF

sed -i -e "s/PRIMAHOSTNAME/${PRIMARY_HOSTNAME}/g" /etc/nginx/conf.d/local.conf]
nginx -s reload

echo "Downloading external certbot because we want to manage this certificate"
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
./certbot-auto --non-interactive --nginx --agree-tos --rsa-key-size 4096 --email hostmaster@$PRIMARY_HOSTNAME --redirect -d collabora.$PRIMARY_HOSTNAME