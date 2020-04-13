#!/usr/bin/env bash

# PreReq'd:
# helm install postgres bitnami/postgresql
# follow artifactory postgresql db setup:
# https://www.jfrog.com/confluence/display/JFROG/PostgreSQL
POSTGRES=$(helm ls | grep postgres | wc -l)

if [[ "$POSTGRES" =~ (0) ]]
then
  echo "External DB is required to run Jfrog Openshift Artifactory Helm chart"
  echo ""
  echo "Postgresql helm chart must be installed prior to installing this helm installer script."
  echo ""
  echo "helm install postgres bitnami/postgresql"
  echo ""
  echo "follow artifactory postgresql db setup:"
  echo "https://www.jfrog.com/confluence/display/JFROG/PostgreSQL"
  exit 1
else
  # patch the restricted scc to allow the pods to run as anyuid
  oc patch scc restricted --patch '{"fsGroup":{"type":"RunAsAny"},"runAsUser":{"type":"RunAsAny"},"seLinuxContext":{"type":"RunAsAny"}}' --type=merge

  # create the license secret
  oc create secret generic artifactory-license --from-file=artifactory.cluster.license

  # create the tls secret
  oc create secret tls tls-ingress --cert=tls.crt --key=tls.key
fi

# install via helm with default postgresql configuration
helm install artifactory-ha . \
               --set artifactory-ha.nginx.tlsSecretName=tls-ingress \
               --set artifactory-ha.artifactory.license.secret=artifactory-license,artifactory-ha.artifactory.license.dataKey=artifactory.cluster.license \
               --set artifactory-ha.database.type=postgresql \
               --set artifactory-ha.database.driver=org.postgresql.Driver \
               --set artifactory-ha.database.url=jdbc:postgresql://postgres-postgresql:5432/artifactory \
               --set artifactory-ha.database.user=artifactory \
               --set artifactory-ha.database.password=password