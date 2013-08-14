%define user zammad
%define group zammad
%define basedir /opt/zammad

Summary: A request tracking tool.
Name: zammad
Version: 0.4
Release: 1%{?dist}.zammad
Copyright: AGPL
Group: Applications/Web
Source: http://download.zammad.org/latest.tar.bz2
URL: http://zammad.org/documentation
Vendor: Zammad Foundation
Packager: Roy Kaldung <roy@kaldung.com>
Requires: nginx >= 1.4, libv8
Requires(pre): shadow-utils
Requires(post): chkconfig

%description
Zammad is a web based open source helpdesk/ticket system
with many features to manage customer telephone calls and 
e-mails. It is distributed under the GNU AFFERO General 
Public License (AGPL) and tested on Linux, Solaris, AIX, 
FreeBSD, OpenBSD and Mac OS 10.x. Do you receive many 
e-mails and want to answer them with a team of agents? 
You're going to love Zammad!

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{basedir}
mkdir -p $RPM_BUILD_ROOT/etc
cd $RPM_BUILD_ROOT/etc
ln -s $RPM_BUILD_ROOT%{basedir}/config etc/zammad

%files
%doc /opt/zammad/doc/README
%doc /opt/zammad/doc/X-Headers.txt
/opt/zammad/doc/app
/opt/zammad/
%config /opt/zammad/config


%pre
/usr/bin/getent group %{group} > /dev/null || /usr/sbin/groupadd -r %{group}
/usr/bin/getent passwd %{user} > /dev/null || /usr/sbin/useradd -M -n -g %{group}-r -d /opt/zammad -s /sbin/nologin %{user}

