FROM       centos:centos7
MAINTAINER Jason Swank <jswank@sonatype.com>

RUN yum install -y \
  openldap-servers openldap-clients \
  && yum clean all

ADD ldap/ /tmp/

RUN /tmp/restore-ldap.sh

EXPOSE 389
USER root
CMD /usr/sbin/slapd -u ldap -d 256
