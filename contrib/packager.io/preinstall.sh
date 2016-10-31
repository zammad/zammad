#!/bin/bash
#
# packager.io preinstall script
#

PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

# install epel-release on centos (needed for nginx)
if [ -n "$(which yum)" ]; then
    yum install -y epel-release
fi

