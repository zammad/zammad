#!/bin/bash
#
# packager.io preinstall script
#

PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

# install epel-release & nginx on centos because it does not work via dependencies
if [ -n "$(which yum)" ]; then
    yum install -y epel-release

    yum install -y nginx
fi

