#!/bin/bash
sudo apt -y update
sudo apt install -y apache2
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

cat <<EOF > /var/www/html/index.html
<html>
<h2>WebServer with IP: $myip</h2><br>
Build by Terraform<br>
Owner ${f_name} ${l_name}<br>
%{ for x in friends ~}
Hello to ${x} from ${f_name}<br>
%{ endfor ~}
</html>
EOF

sudo systemctl start apache2
sudo systemctl enable apache2
