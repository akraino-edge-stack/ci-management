#!/bin/bash -ex
##############################################################################
# Copyright (c) 2019 ENEA and others.
# valentin.radulescu@enea.com
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# the clone of "https://gerrit.akraino.org/r/rec" is done in this
# workspace by the jenkins job with scm
sed -i 's/HOST_IP=/HOST_IP=$HOST_IP/' workflows/pod_create.sh
sed -i 's/CLOUDNAME=/CLOUDNAME=$CLOUDNAME/' workflows/pod_create.sh
sed -i 's/ADMIN_PASSWD=/ADMIN_PASSWD=$ADMIN_PASSWD/' workflows/pod_create.sh
chmod +x workflows/pod_create.sh
workflows/pod_create.sh
