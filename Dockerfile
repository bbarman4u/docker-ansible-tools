FROM alpine:3.13.2

# Sets environment variables
ENV ANSIBLE_VERSION=2.10.7
ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING False
ENV ANSIBLE_RETRY_FILES_ENABLED False
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PATH /ansible/bin:$PATH
ENV PYTHONPATH /ansible/lib

RUN mkdir /etc/ansible /ansible ~/.ssh /ansible/playbooks

RUN apk add --no-cache \
		bzip2 \
		file \
		gzip \
		libffi \
		libffi-dev \
		krb5 \
		krb5-dev \
		krb5-libs \
		musl-dev \
		openssh \
		openssl-dev \
		python3-dev=3.8.10-r0 \
		py3-cffi \
		py3-cryptography=3.3.2-r0 \
		py3-setuptools=51.3.3-r0 \
		sshpass \
		tar \
		&& \
	apk add --no-cache --virtual build-dependencies \
		gcc \
		make \
		&& \
	python3 -m ensurepip --upgrade \
	  && \
	pip3 install \
		ansible==2.10.7 \
		botocore==1.20.32 \
		boto==2.49.0 \
		PyYAML==5.4.1 \
		boto3==1.17.32 \
		awscli==1.19.32 \
		pywinrm[kerberos]==0.4.1 \
		&& \
	apk del build-dependencies \
		&& \
	rm -rf /root/.cache
# Over rides SSH Hosts Checking
RUN echo "host *" >> ~/.ssh/config &&\
    echo "StrictHostKeyChecking no" >> ~/.ssh/config

WORKDIR /ansible/playbooks

# Sets entry point (same as running ansible-playbook)
ENTRYPOINT ["ansible-playbook"]

# Can also use ["ansible"] if wanting it to be an ad-hoc command version
#ENTRYPOINT ["ansible"]

CMD ["--version"]