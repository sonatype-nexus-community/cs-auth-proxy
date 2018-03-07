FROM centos/httpd
MAINTAINER Jason Swank <jswank@sonatype.com>

RUN yum install -y \
  less \
  mod_ssl openssl mod_auth_mellon mod_auth_openidc \
  && yum clean all

COPY httpd/conf.d/ /etc/httpd/conf.d/
COPY httpd/saml2/ /etc/httpd/saml2/

COPY debug /var/www/cgi-bin/debug

COPY update-idp-xml.sh /update-idp-xml.sh

RUN echo "OK" > /var/www/html/index.html

EXPOSE 8000
