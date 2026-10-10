data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "wordpress" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress.id]
  }
}

resource "aws_db_subnet_group" "private" {
  name       = "main-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  instance_class         = "db.t3.micro"
  engine                 = "mysql"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_instance" "wordpress" {
  ami                    = data.aws_ami.linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.wordpress.id]
  iam_instance_profile   = var.instance_profile_name
user_data_replace_on_change = true
user_data =<<-EOF
#!/bin/bash
set -euxo pipefail
dnf install -y httpd wget tar php php-cli php-fpm \
php-mysqlnd php-json php-gd php-xml php-mbstring \
mariadb105-server

systemctl enable --now httpd mariadb php-fpm
systemctl status httpd mariadb php-fpm --no-pager
ss -lntp | grep -E ':80|:3306'

echo '<?php phpinfo(); ?>' | tee /var/www/html/info.php
curl -I http://localhost/info.php
rm -f /var/www/html/info.php

cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
rm -f /var/www/html/index.html
cp -a wordpress/. /var/www/html/
chown -R apache:apache /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
systemctl restart httpd php-fpm
curl -I http://localhost

cd /var/www/html
cat >wp-config.php<<'WP'
<?php
define('DB_NAME', '${var.db_name}');
define('DB_USER', '${var.db_username}');
define('DB_PASSWORD', '${var.db_password}');
define('DB_HOST', '${aws_db_instance.mysql.address}');
$table_prefix = 'wp_';
require_once __DIR__ . '/wp-settings.php';
WP
chown -R apache:apache /var/www/html
EOF
}