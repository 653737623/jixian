#!/bin/bash
set -e
if [ ! -f ashosts ];then
	echo 'no file "ashosts",please check '
	exit 0
fi
REPO=$(cat ashosts |grep -A1 '^\[repo]'|tail -1|awk '{print $1}')
if [ "${REPO}" != "" ];then
	sudo bash -c "echo \"deb http://${REPO} /\">/etc/apt/sources.list"
else
	echo 'please check file "ashosts",no [repo] in file'
	exit 0
fi
USER_NAME="$USER"
if [ "$1" == "" ];then
        sudoPASSWORD=$(cat hosts|grep ssh_pass|awk -F "=" '{print $2}'|sed 's?"??g')
else
        sudoPASSWORD="$1"
fi
if [ "$sudoPASSWORD" == "" ];then
        echo 'Please input password'
        echo "Example: bash $0 \"123456\""
        exit 0
fi
echo "USERNAME: $USER_NAME"
echo "PASSWORD: $sudoPASSWORD"
echo $sudoPASSWORD|sudo -S apt-get update
echo $sudoPASSWORD|sudo -S sudo apt install -y python3-paramiko ansible --allow-unauthenticated
if [ ! -f ~/.ssh/id_rsa ];then
        ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
fi
if [ $(cat /etc/ssh/ssh_config|grep "StrictHostKeyChecking no"|wc -l) -eq 0 ];then
	echo $sudoPASSWORD|sudo -S sed -i 's?#   StrictHostKeyChecking ask?StrictHostKeyChecking no?g' /etc/ssh/ssh_config
fi

cat ashosts|grep -E "^[0-9]"|awk '{print $1}'|sort|uniq>hoststmp
PUBK="$(cat ~/.ssh/id_rsa.pub)"
rm -f /tmp/ssh-tmp.py
cat >/tmp/ssh-tmp.py <<EOF
#!/usr/bin/python   
import paramiko  
import threading  
def ssh2(ip,username,passwd,cmd):  
    try:  
        ssh = paramiko.SSHClient()  
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())  
        ssh.connect(ip,22,username,passwd,timeout=5)  
        for m in cmd:  
            stdin, stdout, stderr = ssh.exec_command(m)  
            out = stdout.readlines()  
            for o in out:  
                print(o)  
        print("%s\tOK\n"%(ip))  
        ssh.close()  
    except :  
        print ("%s\tError\n"%(ip))  
if __name__=='__main__':  
    cmd = ['mkdir -p ~/.ssh','if [ \$(cat ~/.ssh/authorized_keys|grep \"${PUBK}\"|wc -l) -eq 0 ];then echo "${PUBK}" >> ~/.ssh/authorized_keys;fi','chmod 700 ~/.ssh','chmod 600  ~/.ssh/authorized_key','if [ \$(echo $sudoPASSWORD|cat /etc/sudoers|grep NOPASSWD|wc -l) -eq 0 ] ;then NU=\$(echo $sudoPASSWORD|sudo -S cat /etc/sudoers|grep -n "%sudo"|cut -d ":" -f1) ;echo $sudoPASSWORD|sudo -S sed -i "\${NU}s? ALL?NOPASSWD:ALL?g" /etc/sudoers;fi','sudo bash -c \"echo \'deb http://${REPO} /\'>/etc/apt/sources.list\"','sudo apt-get update && sudo apt install -y python --allow-unauthenticated']
    username = "$USER"
    passwd = "$sudoPASSWORD"
    threads = []
    print("Begin......")
    f = open('hoststmp','r')
    try:
        while True:
           lines = f.readline()
           ip = lines.split()[0] 
           #print(ip)
           a=threading.Thread(target=ssh2,args=(ip,username,passwd,cmd))   
           a.start() 
    except IndexError:
            pass
EOF
#sed -i "s?id_rsa.pub?`cat ~/.ssh/id_rsa.pub`?g" /tmp/ssh-tmp.py
python3 /tmp/ssh-tmp.py
sudo cp ashosts /etc/ansible/hosts
sudo sed -i 's?# command_warnings?command_warnings?g' /etc/ansible/ansible.cfg
sudo sed -i 's?#gathering = implicit?gathering = explicit?g' /etc/ansible/ansible.cfg
ansible -i ashosts all -m ping
rm -f hoststmp
