#!/bin/bash

user='sysadmin'
pass='superuser'
sshu='-o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no"'

install() {
    apk -V >/dev/null 2>&1
    [ $? -eq 0 ] && apk add $1; exit
    #apt
    #yum
}

sshremote() {
    sshpass -p $pass ssh $sshu $user@$bmcip "$cmd"
}

# check source


# validate apps
ssh -V >/dev/null 2>&1
[ $? -ne 0 ]; then
    dfsdf
 && echo -e "Component ssh not available, please install openssh!!!\n" && exit 127
sshpass -V >/dev/null 2>&1
[ $? -ne 0 ] && echo -e "Component sshpass not available, please install sshpass!!!\n" && exit 127
mini_httpd >/dev/null 2>&1

# sshpass -p superuser ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" sysadmin@192.168.1.239 "ls"
