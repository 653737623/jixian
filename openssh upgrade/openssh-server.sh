cat >/etc/apt/sources.list<<EOF
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted
deb http://mirrors.aliyun.com/ubuntu/ xenial universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates universe
deb http://mirrors.aliyun.com/ubuntu/ xenial multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu xenial-security main restricted
deb http://mirrors.aliyun.com/ubuntu xenial-security universe
deb http://mirrors.aliyun.com/ubuntu xenial-security multiverse
EOF
cat>/lib/systemd/system/ssh.service<<EOF
[Unit]
Description=OpenBSD Secure Shell server
After=network.target auditd.service
ConditionPathExists=!/etc/ssh/sshd_not_to_be_run

[Service]
EnvironmentFile=-/etc/default/ssh
ExecStart=/usr/sbin/sshd \$SSHD_OPTS
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartPreventExitStatus=255
Type=simple

[Install]
WantedBy=multi-user.target
Alias=sshd.service
EOF

apt-get update
apt-get install -y libssl-dev libpam-dev zlib1g-dev gcc make
wget http://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.0p1.tar.gz
tar xf openssh-8.0p1.tar.gz 
cd openssh-8.0p1
./configure --with-pam --with-tcp-wrappers --with-md5-passwords --sysconfdir=/etc/ssh --sbindir=/usr/sbin  --bindir=/usr/bin
make -j4 && make install
sed -i 38d /etc/ssh/sshd_config
sed -i 31d /etc/ssh/sshd_config
sed -i 20d /etc/ssh/sshd_config
sed -i 19d /etc/ssh/sshd_config
sed -i 16d /etc/ssh/sshd_config
cat >file.txt<<EOF
/usr/bin/ssh
/usr/bin/scp
/usr/bin/ssh-add
/usr/bin/ssh-agent
/usr/bin/ssh-keygen
/usr/bin/ssh-keyscan
/usr/sbin/sshd
/usr/local/libexec/ssh-keysign
/usr/local/libexec/ssh-pkcs11-helper
/usr/bin/sftp
/usr/local/libexec/sftp-server
/usr/local/share/man/man1/ssh.1
/usr/local/share/man/man1/scp.1
/usr/local/share/man/man1/ssh-add.1
/usr/local/share/man/man1/ssh-agent.1
/usr/local/share/man/man1/ssh-keygen.1
/usr/local/share/man/man1/ssh-keyscan.1
/usr/local/share/man/man5/moduli.5
/usr/local/share/man/man5/sshd_config.5
/usr/local/share/man/man5/ssh_config.5
/usr/local/share/man/man8/sshd.8
/usr/local/share/man/man1/sftp.1
/usr/local/share/man/man8/sftp-server.8
/usr/local/share/man/man8/ssh-keysign.8
/usr/local/share/man/man8/ssh-pkcs11-helper.8
/etc/ssh/sshd_config
/var/empty
/lib/systemd/system/ssh.service
EOF
tar zcvf ../openssh-server8.0P1.tar.gz $(cat file.txt)
