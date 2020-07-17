#!/bin/bash
set -e
if [ $(grep wheel /etc/group|wc -l) -eq 0 ];then
	groupadd wheel
	usermod -aG wheel sdn
fi
if [ $(grep wheel /etc/sudoers|wc -l) -eq 0 ];then
	echo '%wheel   ALL=(ALL:ALL) NOPASSWD:ALL'>>/etc/sudoers
fi
if [ $(grep -E "^\s*auth\s*required\s*.*pam_wheel.so\s*group\s*\=\s*wheel" /etc/pam.d/su |wc -l) -eq 0 ];then
	sed -i '7iauth required pam_wheel.so group=wheel' /etc/pam.d/su
fi
#密码过期时间
PD=$(grep -E "^PASS_MAX_DAYS" /etc/login.defs|awk '{print $2}' )
if [ "$PD" != "" -a "$PD" != "90" ];then
	L=$(grep -E -n "^PASS_MAX_DAYS" /etc/login.defs|awk -F ":" '{print $1}')
	echo $L
	sed -i -e $L"s?$PD?90?g" /etc/login.defs
fi
#log
cd /var/log
F="maillog boot.log spooler cron messages secure"
for i in $F;do
	if [ ! -f $i ];then
		touch $i
	fi
	chmod 644 $i
done
#ssh禁止root登录
if [ $(cat /etc/ssh/sshd_config|grep prohibit-password|wc -l) -ge 1 ];then
	sed -i -e "s?prohibit-password?no?g" /etc/ssh/sshd_config
fi
PRL=$(grep -E "^PermitRootLogin" /etc/ssh/sshd_config|awk '{print $2}')
if [ "$PRL" != "" -a "$PRL" != "no" ];then
	L=$(grep -E -n ^PermitRootLogin /etc/ssh/sshd_config|awk -F ":" '{print $1}')
	echo $L
	sed -i -e $L"s?$PRL?no?g" /etc/ssh/sshd_config
	grep -E "^PermitRootLogin" /etc/ssh/sshd_config
fi
#锁定账号
if [ $(cat /etc/passwd|grep nobody|grep /usr/sbin/nologin|wc -l) -eq 1  ];then
	sed -i -e '/^nobody/s?/usr/sbin/nologin?/bin/false?g' /etc/passwd
fi 


#umask
#sed -i -e '/^UMASK/s?022?027?g' /etc/login.defs 

