# Ansible Development Machine in a Docker

## Introduction
Ansible development is fairly simple if you are on a Mac OS or on a Linux machine. But for developers working on windows machines it is often a struggle to reliably verify and test their ansible playbooks. This ansible development environment wrapped in a docker container, hopes to solve some of those struggles.


## Getting Started
- Current Tech Stack Versions:
  - Alpine Linux: `3.13.2`
  - Ansible: `2.10.7`
  - AWS CLI: `1.19.32`
  
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
- Your ansible code (of course) such as play books, inventory file, ansible.cfg, etc.


## Using the ansible docker image
### Key Points to Understand
- The docker image expects the following required and optional components which is explained in more detail later below:
  - Playbook Path Volume Mount (Required)
  - SSH Key Pair Path Volume Mount (Optional)
  - Ansible Specific Execution Commands
  - Ansible specific configuration files such as inventory file, ansible.cfg(optional)

### Syntax for running the docker image 
- The general syntax for executing the playbooks/adhoc ansible commands with the docker image is below -
- Execution Syntax (Generic):
  ```
    docker run -it --rm -v <Requierd Ansible Playbook Code Volume Mount Path> -v <Optional SSH Key Pair Volume Mount Path> <Docker Image to Run> <Ansible Commands to Execute> <Any Optional Extra Arguments to pass to Ansible>
  ```
- Execution Syntax(Adhoc Ansible Commands): 
  ```
    docker run -it --rm -v <Requierd Ansible Playbook Code Volume Mount Path> -v <Optional SSH Key Pair Volume Mount Path> <Docker Image to Run> ansible <host pattern> -m <module name> <additional arguments>
  ```
- Execution Syntax(Ansible Playbook Commands): 
  ```
    docker run -it --rm -v <Requierd Ansible Playbook Code Volume Mount Path> -v <Optional SSH Key Pair Volume Mount Path> <Docker Image to Run> ansible-playbook  <ansible playbook file name> <inventory file> <additional arguments>
  ```

- Note you don't need to build a local image, you can reference directly from the docker hub specific image versions.

#### Playbook Path Volume Mount (Required)
- For using the locally built Image or the image pulled from the docker hub, you need to mount the path of the location of your working directory where the playbook, inventory file, etc. exists. Typically it will be the current directory where your playbook file exists which you can mount by passing `PWD` command. 
- The playbooks are expected to be mounted inside the container in a working directory of `/home/ansible/playbooks`. We can also set it to read only by using the flag like `ro` to avoid any files being modified by container on the host.
- Example(On Windows/Linux/Mac):
  ```
  -v ${PWD}:/home/ansible/playbooks:ro

  ```
- Note: If you are not using `PWD` ensure you path the full path to the location of the playbook

#### SSH Key Pair Path Volume Mount (Optional)
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
    -v ${HOME}/.ssh:/tmp/.ssh/:ro
    ```

## Playbook Execution

### Demo Execution
- If you have checked out this git repo, change to the `demo` directory and try out the following examples to get going i.e. `cd demo`

- Sample Ansible adhoc command that runs `ping` against `localhost`:
  ```
    docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 ansible localhost -m ping -i inventory2

  ```
- Sample Ansible adhoc command that runs `setup` against `localhost`:
  ```
    docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 ansible localhost -m ping -i inventory2

  ```

- Sample Ansible Playbook command that executes `demo-playbook1.yml` against `localhost`:
  ```
   docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 ansible-playbook demo-playbook1.yml

  ```
- Sample Ansible Playbook command that executes `demo-playbook2.yml` against `localhost` by passing the `HOSTS` variable:
  ```
   docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 ansible-playbook demo-playbook2.yml -e HOSTS=localhost

  ```
- Sample Ansible Playbook command that executes `demo-playbook2.yml` against `pwd_all` by passing the `HOSTS` variable & using an inventory file `inventory2`:
  ```
   docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 ansible-playbook demo-playbook2.yml -e HOSTS=pwd_all -i inventory2

  ```
- Note: For real life practical usage, substitute your own reachable hosts that is set up with passwordless authentication in the inventory file (refer to below sections)

### Advanced Usage
#### Passwordless Authentication with SSH Keys
- If connecting to a remote host via SSH, consider passwordless authentication by mounting the ssh keys from the host
- Note: You need to provide path of the mounted ansible SSH private key file in the inventory file, syntax: `ansible_ssh_private_key_file=/home/ansible/.ssh/<my private key file>`
    - Example: `ansible_ssh_private_key_file=/home/ansible/.ssh/id_rsa`

- Execution Syntax: 

  ```
  docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro -v "${HOME}/.ssh:/tmp/.ssh/:ro" bb8docker/docker-ansible-tools:2.10.7 ansible-playbook <playbook-name> -i <inventory-path> <additional arguments>
  ```

- Example: Execute a playbook with passing HOSTS variable to playbook and mounting SSH Keys
   ```
    docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro -v "${HOME}/.ssh:/tmp/.ssh/:ro" bb8docker/docker-ansible-tools:2.10.7 ansible-playbook demo-playbook2.yml -i inventory2 -e HOSTS=pwd_all
   ```

#### Asking for Password with out SSH Keys
- If connecting to a remote host via SSH where you can't add ssh keys on the remote host, consider passing the argument asking for password for the remote user e.g. `-k` or `--ask-pass`
- Execution Syntax: 
  ```
  docker run -it --rm --volume ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 ansible-playbook <playbook-name> -i <inventory-path> <additional arguments>
  ```

- Example:
   ```
    docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 ansible-playbook demo-playbook2.yml -i inventory2 -e HOSTS=pwd_all -k
   ```

## Using Powershell Aliases for running the docker commands
- If you are tired of typing these long commands every time especially for the parts that don't change often, you can set powershell aliases and can make your life that much easier so that you are typing only required commands just like you would have done if you had ansible installed natively.
- Here is a sample powershell function that you can use or feel free to customize it to your preferred command and then you can re run your commands with the short cut alias.
- Type this on a powershell window `notepad $PROFILE`. The very first time it will ask to create and save a file named like `Microsoft.PowerShell_profile.ps1` to your powershell profile path.
- Add entries like below to that file and open up a new powershell window to use these aliases. We are using the `Set-Alias` commandlet which will be saved and be persistent with this method.
  ```
    function Run-AnsibleDockerPlaybookWithSSHKeys {
        docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro -v "${HOME}/.ssh:/tmp/.ssh/:ro" bb8docker/docker-ansible-tools:2.10.7 $args
    }
    Set-Alias ssh-play Run-AnsibleDockerPlaybookWithSSHKeys

    function Run-AnsibleDockerPlaybookWithOutSSHKeys {
        docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 $args
    }
    Set-Alias ask-passwd-play Run-AnsibleDockerPlaybookWithOutSSHKeys

    function Run-AnsibleDockerGenericCommands {
        docker run -it --rm -v ${PWD}:/home/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 $args
    }
    Set-Alias ansible-tools Run-AnsibleDockerGenericCommands
  ```
- Examples while using the alias (refer to the Demo Execution Section & other examples for use without the alias) 
    - Sample Ansible adhoc command that runs `ping` against `localhost`:
      ```
        ansible-tools ansible localhost -m ping -i inventory2

      ```

    - Sample Ansible Playbook command that executes `demo-playbook1.yml` against `localhost`:
      ```
      ansible-tools ansible-playbook demo-playbook1.yml

      ```
    - Sample Ansible Playbook command that executes `demo-playbook2.yml` against `localhost` by passing the `HOSTS` variable:
      ```
      ansible-tools ansible-playbook demo-playbook2.yml -e HOSTS=localhost

      ```
    - Sample Ansible Playbook command that executes `demo-playbook2.yml` against `pwd_all` by passing the `HOSTS` variable & using an inventory file `inventory2`:
      ```
      ansible-tools ansible-playbook demo-playbook2.yml -e HOSTS=pwd_all -i inventory2

      ```
    - Sample Ansible Playbook command that executes a playbook with passing HOSTS variable to playbook and mounting SSH Keys
      ```
        ssh-play ansible-playbook demo-playbook2.yml -i inventory2 -e HOSTS=pwd_all
      ```
    - Sample Ansible Playbook command that executes a playbook that asks for password
      ```
        ask-passwd-play ansible-playbook demo-playbook2.yml -i inventory2 -e HOSTS=pwd_all -k
      ```
      
## Ansible Configurations
### ansible.cfg
- The entry point script `docker-entrypoint.sh` will copy over an `ansible.cfg` file if found in the current directory for the playbook execution to another directory `/home/ansible/config` which has the right permissions and will set the environment variable `ANSIBLE_CONFIG` to this directory so that the ansible configurations can take effect.
- This is important if you want to apply some local ansible configurations during the execution of the playbook
- Sample ansible.cfg:
  ```
  [defaults]
  inventory = inventory
  host_key_checking = false
  callback_whitelist = profile_tasks

  [ssh_connection]
  scp_if_ssh = smart
  ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s
  control_path = /dev/shm/cp%%h-%%p-%%r
  control_path_dir = /dev/shm/ansible_control_path
  ```

### Inventory File Configurations
- Specify different host specific configurations in the inventory file in ini or YAML format.
- Important: You need to specify the full path to the SSH Private Key file (present on the docker container) against your host details in the inventory file
- Sample Inventory File (ini format):
  ```
  [pwd_all]
  node1 ansible_host=ip172-18-0-25-c33n7gnnjsv000eor760@direct.labs.play-with-docker.com ansible_port=22 ansible_user=root ansible_ssh_private_key_file=/home/ansible/.ssh/id_rsa ansible_python_interpreter=/usr/bin/python3
  ```

## Local Development 
- Key Components to modify for upgrade or enhancements
  - Dockerfile
  - scripts/docker-entrypoint.sh
  - .dockerignore

### Building the image locally for enhancing the functionalities in the docker image
- Update the Dockerfile with the relevant ansible version and the related dependencies
- Build the docker image tagging with the included ansible version such as  `docker build . -t docker-ansible-tools:2.10.7`
- If pushing to a remote repository such as docker hub from the local, please login to the remote repository, from docker CLI, retag the image with the repository name and desired tag and push it. 
  - Example:
    ```
    docker tag docker-ansible-tools:2.10.7 bb8docker/docker-ansible-tools:2.10.7
    docker push bb8docker/docker-ansible-tools:2.10.7
    ```

## Source Code
- Github Link for this is [bbarman4u/docker-ansible-tools](https://github.com/bbarman4u/docker-ansible-tools)

## References:
- Heavily inspired and built by referencing the work done by [jmal98/ansiblecm](https://github.com/jmal98/ansiblecm) and [geektechdude/ansible_container](https://github.com/geektechdude/ansible_container)
- Very good reference article for newcomers to docker with ansible by [Josh Duffney at Duffney.io](https://duffney.io/containers-for-ansible-development/)
- Thanks to Nick Janetakis for idea for the SSH problem on Windows, [detailed article here](https://nickjanetakis.com/blog/docker-tip-56-volume-mounting-ssh-keys-into-a-docker-container)
- For a more advanced replacement for ansible development container (does not work on windows 10 yet without WSL2) is [cytopia/docker-ansible](https://github.com/cytopia/docker-ansible)
- [Must have powershell aliases for docker](https://blog.sixeyed.com/your-must-have-powershell-aliases-for-docker/)
