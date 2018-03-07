FROM jboss/keycloak

ADD export.sh /tmp/export.sh
ADD realm.json /tmp/realm.json
CMD ["-b", "0.0.0.0", "-Dkeycloak.import=/tmp/realm.json"]
