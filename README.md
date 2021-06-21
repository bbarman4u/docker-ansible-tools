# Ansible Development Machine in a Docker

## Introduction
Ansible development is fairly simple if you are on a Mac OS or on a Linux machine. But for developers working on windows machines it is often a struggle to reliably verify and test their ansible playbooks. This ansible development environment wrapped in a docker container, hopes to solve some of those struggles.


## Getting Started
- Current Tech Stack Versions:
  - Ansible: `2.10.7`
  - Alpine: `3.13.2`
- Docker Hub Images Available at:
  - [bb8docker/docker-ansible-tools](https://hub.docker.com/r/bb8docker/docker-ansible-tools)
- Features supported:
  - Execution of adhoc ansible commands
  - Execution of ansible-playbooks
  - Execution of ansible commands through passwordless SSH using ssh keys from the host machine
  - Execution of ansible commands using by asking for password interactively
  - Work around for ansible.cfg in the current directory being ignored on windows
  - Work around for SSH Key not inhereting right permission on Windows with the SSH Keys volume mounted (thereby passwordless authentication not working)


### Pre-requisites
- Docker Desktop
- VS Code for development (optional)

### Building the image locally
- Update the Dockerfile with the relevant ansible version and the related dependencies
- Build the docker image tagging with the included ansible version such as  `docker build . -t docker-ansible-tools:2.10.7`
- If pushing to a remote repository such as docker hub from the local, please login to the remote repository, from docker CLI, retag the image with the repository name and desired tag and push it. 
  - Example:
    ```
    docker tag docker-ansible-tools:2.10.7 bb8docker/docker-ansible-tools:2.10.7
    docker push bb8docker/docker-ansible-tools:2.10.7
    ```

## Using the ansible docker image
### Playbook Path Volume Mount (Required)
- For using the locally built Image or the image pulled from the docker hub, you need to mount the path of the location of your working directory where the playbook, inventory file, etc. exists.
- The playbooks are expected to be mounted inside the container in a working directory of `/home/ansible/playbooks`. We can also set it to read only to avoid any files being modified by container on the host.
- Example(On Windows):
  ```
  -v ${PWD}:/home/ansible/playbooks:ro

  ```
- Example (On Linux/Mac):

  ```
   -v $(PWD):/home/ansible/playbooks:ro 

  ```
### SSH Key Path Volume Mount (Optional)
- This is required only if you want to use passwordless authentication via SSH Keys for the remote hosts.
- The host SSH keys (generated using ssh-keygen) are expected to be mounted inside the container in a working directory of `/tmp/.ssh`. We can also set it to read only to avoid any files being modified by container on the host.
- The mounted SSH Keys get copied over to the final path of `/home/ansible/.ssh` by the docker entry point shell script `docker-entrypoint.sh` thereby applying the right permissions. So in your ansible inventory file, please provide path to your SSH Keys like this `ansible_ssh_private_key_file=/home/ansible/.ssh/<private key file name>`
-  Generate the SSH Keys for passwordless authentication and note down the path where the keys were placed on the host machine and also add the SSH keys to the remote server's authorized keys.
    - Example:
      ```
      ssh-keygen -b 2048 -t rsa

      ```

- Mount the SSH keys on your host machine to the container
  - Example (On Windows):
    ```
    -v "${HOME}/.ssh:/tmp/.ssh/:ro"
    ```

  - Example (On Linux/Mac):

    ```
    -v $HOME/.ssh:/tmp/.ssh/:ro
    ```

### Playbook Execution (Passwordless Authentication with SSH Keys)
- If connecting to a remote host via SSH, consider passwordless authentication by mounting the ssh keys from the host
- Execution Syntax: 

  ```
  docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro -v "${HOME}/.ssh:/tmp/.ssh/:ro" bb8docker/docker-ansible-tools:2.10.7 ansible-playbook <playbook-name> -i <inventory-path> <additional arguments>
  ```

- Example: Execute a playbook with passing HOSTS variable to playbook
   ```
    docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro -v "${HOME}/.ssh:/tmp/.ssh/:ro" bb8docker/docker-ansible-tools:2.10.7 ansible-playbook ping-playbook.yml -i inventory2 -e HOSTS=pwd_all
   ```

### Playbook Execution (Asking for Password with out SSH Keys)
- If connecting to a remote host via SSH where you can't add ssh keys on the remote host, consider passing the argument asking for password for the remote user e.g. `-k` or `--ask-pass`
- Execution Syntax: 
  ```
  docker run -it --rm --volume ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 ansible-playbook <playbook-name> -i <inventory-path> <additional arguments>
  ```

- Example:
   ```
    docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 ansible-playbook ping-playbook.yml -i inventory2 -e HOSTS=pwd_all -k
   ```

### Adhoc Command Execution
- Similar to the playbook execution, instead of using `ansible-playbook` command you can use the regular `ansible` commands.
- Execution Syntax: 
  ```
  docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro -v "${HOME}/.ssh:/tmp/.ssh/:ro" bb8docker/docker-ansible-tools:2.10.7 ansible <host pattern> -m <module name> <additional options>
  ```

- Example:
   ```
   docker run -it --rm --net=host -v ${PWD}:/home/ansible/playbooks:ro -v "${HOME}/.ssh:/tmp/.ssh/:ro" bb8docker/docker-ansible-tools:2.10.7 ansible pwd_all -m ping -i inventory2 -vv
   ```

## Source Code
- Github Link for this is [bbarman4u/docker-ansible-tools](https://github.com/bbarman4u/docker-ansible-tools)

## References:
- Heavily inspired and built by referencing the work done by [jmal98/ansiblecm](https://github.com/jmal98/ansiblecm) and [geektechdude/ansible_container](https://github.com/geektechdude/ansible_container)
- Very good reference article for newcomers to docker with ansible by [Josh Duffney at Duffney.io](https://duffney.io/containers-for-ansible-development/)
- Thanks to Nick Janetakis for idea for the SSH problem on Windows, [detailed article here](https://nickjanetakis.com/blog/docker-tip-56-volume-mounting-ssh-keys-into-a-docker-container)
