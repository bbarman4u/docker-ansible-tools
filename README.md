# Ansible Development Machine in a Docker

## Introduction
Ansible development is fairly simple if you are on a Mac OS or on a Linux machine. But for developers working on windows machines it is often a struggle to reliably verify and test their ansible playbooks. This ansible development environment wrapped in a docker container, hopes to solve some of those struggles.


## Getting Started
- Current Tech Stack Versions:
  - Ansible: `2.10.7`
  - Alpine: `3.13.2`
- Docker Hub Images Available at:
  - [bb8docker/docker-ansible-tools](https://hub.docker.com/r/bb8docker/docker-ansible-tools)

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
### Path Volume Mount
- For using the locally built Image or the image pulled from the docker hub, you need to mount the path of the location of your working directory where the playbook, inventory file, etc. exists.
- The playbooks are expected to be mounted inside the container in a working directory of /ansible/playbooks. We can also set it to read only to avoid any files being modified by container on the host.
- Example(On Windows):
  ```
  --volume ${PWD}:/ansible/playbooks:ro

  ```
- Example (On Linux/Mac):

  ```
   --volume $(PWD):/ansible/playbooks:ro 

  ```

### Playbook Execution
- Default entry point is set to run the ansible-playbook i.e. `ENTRYPOINT ["ansible-playbook"]` 
- If connecting to a remote host via SSH, consider passing the argument asking for password for the remote user e.g. `-k` or `--ask-pass`
- Execution Syntax: 
  ```
  docker run -it --rm --volume ${PWD}:/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 <playbook-name> -i <inventory-path> <additional arguments>
  ```

- Examples:
   ```
   docker run -it --rm --volume ${PWD}:/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 my-playbook.yml -i inventory -e HOSTS=pwd_all -k
   ```

### Adhoc Command Execution
- You can override the default entry point by defining your custom entry point such as `--entrypoint ansible`
- If connecting to a remote host via SSH, consider passing the argument asking for password for the remote user e.g. `-k` or `--ask-pass`
- Execution Syntax: 
  ```
  docker run -it --entrypoint ansible --rm --volume ${PWD}:/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 <inventory host name> -m <module name> -i <inventory> -k
  ```

- Examples:
   ```
   docker run -it --entrypoint ansible --rm --volume ${PWD}:/ansible/playbooks:ro bb8docker/docker-ansible-tools:2.10.7 pwd_all -m ping -i inventory2 -k
   ```

## Source Code
- Github Link is [bbarman4u/docker-ansible-tools]](https://github.com/bbarman4u/docker-ansible-tools)

## References:
- Heavily inspired and built by referencing the work done by [jmal98/ansiblecm](https://github.com/jmal98/ansiblecm) and [geektechdude/ansible_container](https://github.com/geektechdude/ansible_container)
- Very good reference article for newcomers to docker with ansible by [Josh Duffney at Duffney.io](https://duffney.io/containers-for-ansible-development/)