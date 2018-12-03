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

# Copied (and modified slightly) from edgexfoundry
# Do not fail this job as this is a stopgap for now.
set +e

# Look in our console log for the triggering build number
T=/tmp/ups.$$
curl $BUILD_URL/consoleText | grep "Started by upstream project" > $T
if [ -s $T ]
then
    # $T should contain "06:25:53 Started by upstream project "projname" build number 111"
    upstream_name=$(   awk -F '"' '{print $2}' < $T)
    upstream_number=$( awk -F '"' '{print $3}' < $T | awk -F ' ' '{print$3}')

    # This is the URL of the console log for the triggering job
    upstream_url="https://jenkins.akraino.org/job/$upstream_name/$upstream_number/consoleText"

    # This identifies the staging directory for the staging URL
    # https://nexus.akraino.org/content/repositories/autostaging-${AUTOSTAGING}/org/akraino/${PROJECT}/${VERSION}/${PROJECT}-${VERSION}.[jw]ar
    #    or
    # https://nexus.akraino.org/content/repositories/autostaging-${AUTOSTAGING}/${PROJECT}-${VERSION}.tgz
    #    e.g.
    # https://nexus.akraino.org/content/repositories/autostaging-1100/org/akraino/portal_user_interface/0.0.2/portal_user_interface-0.0.2.war
    # https://nexus.akraino.org/content/repositories/autostaging-1099/org/akraino/camunda_workflow/0.0.2/camunda_workflow-0.0.2.jar
    # https://nexus.akraino.org/content/repositories/autostaging-1091/airshipinabottle_deploy-0.0.1.tgz
    AUTOSTAGING=$(curl $upstream_url | grep "Completed uploading files to autostaging" | sed 's/.*-//' | tr -d '.')
fi
