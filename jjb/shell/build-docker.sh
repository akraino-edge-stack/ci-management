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

BUILD='0.0.1-20180626.021230-4'
WARFILE="https://nexus.akraino.org/repository/maven-snapshots/org/akraino/portal/portal/0.0.1-SNAPSHOT/portal-0.0.1-${BUILD}.war"
NEXUS='nexus3.akraino.org:10001'
VERSION=${VERSION:1.0}

set -e -u -x -o pipefail

echo '---> Starting build-docker'
docker ps
docker version

case "$PROJECT" in
portal_user_interface)
    CON_NAME='akraino-portal'
    curl -O ${WARFILE}
    basename=$( echo ${WARFILE} | sed 's;.*/;;' )
    ln $basename AECPortalMgmt.war

    (
        echo 'FROM tomcat:8.5.31'
        echo 'COPY AECPortalMgmt.war /usr/local/tomcat/webapps'
    ) > Dockerfile

    docker build -f Dockerfile -t ${CON_NAME}:${VERSION} .
    docker tag ${CON_NAME}:${VERSION} ${NEXUS}/${CON_NAME}:${VERSION}
    docker push ${NEXUS}/${CON_NAME}:${VERSION}
    ;;

camunda_workflow)
    CON_NAME="akraino-camunda-workflow-engine"

    jar=camunda_workflow-$build.jar
    WARFILE="https://nexus.akraino.org/repository/maven-snapshots/org/akraino/camunda_workflow/$version"
    curl -O ${WARFILE}
    docker build -f Dockerfile -t ${CON_NAME}:${VERSION} .
    docker tag ${CON_NAME}:${VERSION} ${NEXUS}/${CON_NAME}:${VERSION}
    docker push ${NEXUS}/${CON_NAME}:${VERSION}
    ;;

postgres_db_schema)
    CON_NAME="akraino_schema_db"
    git clone https://gerrit.akraino.org/r/yaml_builds
    mv yaml_builds/templates akraino-j2templates
    docker build -f Dockerfile -t ${CON_NAME}:${VERSION} .
    docker tag  ${CON_NAME}:${VERSION} ${NEXUS}/${CON_NAME}:${VERSION}
    docker push ${NEXUS}/${CON_NAME}:${VERSION}
    ;;

*)
    echo unknown project "$PROJECT"
    exit 1
    ;;
esac

set +u +x
