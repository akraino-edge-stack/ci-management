#!/bin/bash
#
# Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DOCKER_REPO='nexus3.akraino.org:10003'

set -e -u -x -o pipefail

echo '---> Starting build-docker'

case "$PROJECT" in
portal_user_interface)
    CON_NAME='akraino-portal'
    VERSION=`xmlstarlet sel -N "x=http://maven.apache.org/POM/4.0.0" -t -v "/x:project/x:version" AECPortalMgmt/pom.xml`

    XMLFILE="${NEXUS_URL}/service/local/repositories/snapshots/content/org/akraino/${PROJECT}/${VERSION}/maven-metadata.xml"
    curl -O "${XMLFILE}"
    V2=`grep value maven-metadata.xml | sed -e 's;</value>;;' -e 's;.*<value>;;' | uniq`
    WARFILE="${NEXUS_URL}/service/local/repositories/snapshots/content/org/akraino/${PROJECT}/${VERSION}/${PROJECT}-${V2}.war"
    curl -O "${WARFILE}"

    ln $(basename ${WARFILE}) AECPortalMgmt.war
    (
        echo 'FROM tomcat:8.5.31'
        echo 'COPY AECPortalMgmt.war /usr/local/tomcat/webapps'
    ) > Dockerfile
    ;;

camunda_workflow)
    CON_NAME='akraino-camunda-workflow-engine'
    VERSION=`xmlstarlet sel -N "x=http://maven.apache.org/POM/4.0.0" -t -v "/x:project/x:version" akraino/pom.xml`

    XMLFILE="${NEXUS_URL}/service/local/repositories/snapshots/content/org/akraino/${PROJECT}/${VERSION}/maven-metadata.xml"
    curl -O "${XMLFILE}"
    V2=`grep value maven-metadata.xml | sed -e 's;</value>;;' -e 's;.*<value>;;' | uniq`
    JARFILE="${NEXUS_URL}/service/local/repositories/snapshots/content/org/akraino/${PROJECT}/${VERSION}/${PROJECT}-${V2}.jar"
    curl -O ${JARFILE}
    ;;

postgres_db_schema)
    CON_NAME='akraino_schema_db'
    source $WORKSPACE/version.properties

    # Note: for some reason the project name is in the path twice for tar files
    XMLFILE="${NEXUS_URL}/service/local/repositories/snapshots/content/org/akraino/yaml_builds/yaml_builds/${VERSION}/maven-metadata.xml"
    curl -O "${XMLFILE}"
    V2=`grep value maven-metadata.xml | sed -e 's;</value>;;' -e 's;.*<value>;;' | uniq`
    TGZFILE="${NEXUS_URL}/service/local/repositories/snapshots/content/org/akraino/yaml_builds/yaml_builds/${VERSION}/yaml_builds-${V2}.tgz"
    curl -O "${TGZFILE}"
    (mkdir yaml_builds; cd yaml_builds; tar xfv ../$(basename ${TGZFILE}))
    mv yaml_builds/templates akraino-j2templates
    ;;

*)
    echo unknown project "$PROJECT"
    exit 1
    ;;
esac

# Append stream, if it is not the master stream
if [ "${STREAM}" != "master" ]
then
    VERSION="${VERSION}-${STREAM}"
fi

# Build and push the Docker container
docker build -f Dockerfile -t ${CON_NAME}:${VERSION} .
docker tag ${CON_NAME}:${VERSION} ${DOCKER_REPO}/${CON_NAME}:${VERSION}
docker push ${DOCKER_REPO}/${CON_NAME}:${VERSION}

set +u +x
