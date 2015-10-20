# --
# RPM spec file for RHEL7 of the OTRS package
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
#
# please file bugfixes or comments on http://bugs.otrs.org
#
# --
Summary:      Zammad 
Name:         zammad
Version:      0.0
License:    GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007
Group:        Applications/Mail
Provides:     zammad
Requires(pre): /usr/sbin/useradd, /usr/bin/getent
Requires(postun): /usr/sbin/userdel
Requires:     cronie httpd 
Autoreqprov:  no
Release:      01
Source0:      zammad-%{version}.tar.bz2
BuildArch:    noarch
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
<DESCRIPTION>

%prep
/usr/bin/getent group zammad || /usr/bin/groupadd zammad
/usr/bin/getent passwd zammad || /usr/sbin/useradd -g zammad -d /opt/zammad -s /bin/bash zammad  
#%setup

%build
# copy config file


%install
# delete old RPM_BUILD_ROOT
rm -rf $RPM_BUILD_ROOT
# set DESTROOT
export DESTROOT="opt/zammad/"
# create RPM_BUILD_ROOT DESTROOT
mkdir -p $RPM_BUILD_ROOT/$DESTROOT
# copy files
cd $RPM_BUILD_ROOT/$DESTROOT/../..
pwd
tar xfj ../../SOURCES/zammad-%{version}.tar.bz2 -C $DESTROOT
#cp -Rv /opt/zammad $RPM_BUILD_ROOT/$DESTROOT

# install init-Script
#install -d -m 755 $RPM_BUILD_ROOT/etc/rc.d/init.d
#install -d -m 755 $RPM_BUILD_ROOT/etc/sysconfig


# copy apache2-httpd.include.conf to /etc/httpd/conf.d/zzz_otrs.conf
#install -m 644 scripts/apache2-httpd.include.conf $RPM_BUILD_ROOT/etc/httpd/conf.d/zzz_otrs.conf

# set permission
export OTRSUSER=otrs
#useradd $OTRSUSER || :
#useradd apache || :
#groupadd apache || :
#$RPM_BUILD_ROOT/opt/otrs/bin/otrs.SetPermissions.pl --web-group=apache

%pre
# remember about the installed version
#if test -e /opt/otrs/RELEASE; then
#    cat /opt/otrs/RELEASE|grep VERSION|sed 's/VERSION = //'|sed 's/ /-/g' > /tmp/otrs-old.tmp
#fi
# useradd
export ZUSER=zammad
echo -n "Check Zammad user ... "
if id $ZUSER >/dev/null 2>&1; then
    echo "$ZUSER exists."
    # update home dir
    usermod -d /opt/zammads $ZUSER
else
    useradd $ZUSER -d /opt/zammad -s /bin/bash -g zammad -c 'Zammad user' && echo "$ZUSER added."
fi


%post

# run OTRS rebuild config, delete cache, if the system was already in use (i.e. upgrade).
export OTRSUSER=zammad


%clean
#rm -rf $RPM_BUILD_ROOT

%files
#%config(noreplace) /etc/sysconfig/otrs
#%config /etc/httpd/conf.d/zzz_otrs.conf
#/etc/rc.d/init.d/otrs
/opt/zammad
#<FILES>

%changelog
* Mon Dec 17 2012 - mb@otrs.com
- Added dependencies to Digest::SHA, Net::LDAP and Crypt::SSLeay, available from base repositories.
- Removed dependency on Time::HiRes in favor of perl-core package.

