#!/bin/bash
#
# Copyright (c) 2019 Red Hat. All rights reserved.
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

# ta-ci-build job takes around ~30 minutes to execution. 
# Introduced sleep of 10 minutes to avoid a build queue
# if multiple components change

if_image_being_built=`ps -eaf | grep -q "ta/build-tools/build_images.sh"`
if [ -z "$if_image_being_built" ]
then
	sleep 600
fi
