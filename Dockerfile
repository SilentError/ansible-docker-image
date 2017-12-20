FROM centos:6

# Installing pre-requisites
RUN yum clean all && \
    yum -y install epel-release && \
    yum -y install \
    acl \
    asciidoc \
    bzip2 \
    file \
    gcc \
    git \
    wget \
    make \
    openssh-clients \
    openssh-server \
    openssl-devel \
    libffi-devel \
    rpm-build \
    rubygems \
    sed \
    sudo \
    unzip \
    which \
    yum-utils \
    zip && \
    yum upgrade -y && \
    yum clean all && \
    rm -rf /var/cache/yum/*

# Compiling Python 2.7
RUN curl https://www.python.org/ftp/python/2.7.13/Python-2.7.13.tgz | tar zxv && \
    cd Python-2.7.13 && \
    ./configure && \
    make altinstall
RUN rm -rf Python-2.7.13
RUN curl -L https://bootstrap.pypa.io/get-pip.py > get-pip.py && python2.7 get-pip.py
RUN pip2.7 install --upgrade 'jinja2<2.9' pycrypto ansible-lint junit-xml six

# Setting Up Ansible
RUN /bin/sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers
RUN mkdir /etc/ansible/
RUN /bin/echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts
RUN ssh-keygen -q -t rsa1 -N '' -f /etc/ssh/ssh_host_key && \
    ssh-keygen -q -t dsa -N '' -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -q -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    for key in /etc/ssh/ssh_host_*_key.pub; do echo "localhost $(cat ${key})" >> /root/.ssh/known_hosts; done

# Installing GOSS
RUN curl -L https://github.com/aelsabbahy/goss/releases/download/v0.3.2/goss-linux-amd64 > /usr/local/bin/goss && chmod +rx /usr/local/bin/goss

ENV container=docker
# Add the plays and tests
ARG ANSIBLE_ROLE
ADD $ANSIBLE_ROLE /etc/ansible/roles/$ANSIBLE_ROLE
RUN { \
		echo '---'; \
		echo '- name: apply common configuration to all nodes'; \
		echo '  hosts: 127.0.0.1'; \
		echo '  connection: local'; \
		echo '  gather_facts: true'; \
		echo; \
		echo '  roles:'; \
	} > /etc/ansible/roles/site.yml \ 
	&& echo "    - { role: \"$ANSIBLE_ROLE\" }" >> /etc/ansible/roles/site.yml

CMD ["ls -la /"]
