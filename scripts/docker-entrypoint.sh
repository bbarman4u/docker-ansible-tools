#!/usr/bin/env sh
set -e

ANSIBLE_SSH_DIR="/home/ansible/.ssh"
ANSIBLE_CONFIG_DIR="/home/ansible/config"
HOST_SSH_DIR="/tmp/.ssh"
PLAYBOOK_DIR="/home/ansible/playbooks"


# Work around for SSH keys on windows not retaining host permissions
[ -d $HOST_SSH_DIR ] && \
cp -R $HOST_SSH_DIR/* $ANSIBLE_SSH_DIR && \
chmod 700 $ANSIBLE_SSH_DIR && \
chmod 400 $ANSIBLE_SSH_DIR/*

# Work around for ansible.cfg in the current dir getting ignored for being in a world writeable directory 
[ -d $PLAYBOOK_DIR ] && [ -f $PLAYBOOK_DIR/ansible.cfg ] && \
mkdir $ANSIBLE_CONFIG_DIR && cp $PLAYBOOK_DIR/ansible.cfg $ANSIBLE_CONFIG_DIR/. && \
export ANSIBLE_CONFIG=$ANSIBLE_CONFIG_DIR

#Execute the passed on commands
exec "$@"