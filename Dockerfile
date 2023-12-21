FROM mysql:5.7

WORKDIR /root

RUN yum update -y && \
    yum install -y mysql-shell mysql-router-community && \
    yum install -y iproute net-tools telnet iputils
