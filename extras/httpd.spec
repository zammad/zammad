%define contentdir /var/www
%define suexec_caller apache
%define mmn 20120211

Summary: Apache HTTP Server
Name: httpd
Version: 2.4.3
Release: 1%{?dist}
URL: http://httpd.apache.org/
Vendor: Apache Software Foundation
Source0: http://www.apache.org/dist/httpd/httpd-%{version}.tar.bz2
License: Apache License, Version 2.0
Group: System Environment/Daemons
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildRequires: autoconf, perl, pkgconfig, findutils
BuildRequires: zlib-devel, libselinux-devel
BuildRequires: apr-devel >= 1.4.0, apr-util-devel >= 1.4.0, pcre-devel >= 5.0
Requires: initscripts >= 8.36, /etc/mime.types
Obsoletes: httpd-suexec
Requires(pre): /usr/sbin/useradd
Requires(post): chkconfig
Provides: webserver
Provides: mod_dav = %{version}-%{release}, httpd-suexec = %{version}-%{release}
Provides: httpd-mmn = %{mmn}

%description
Apache is a powerful, full-featured, efficient, and freely-available
Web server. Apache is also the most popular Web server on the
Internet.

%package devel
Group: Development/Libraries
Summary: Development tools for the Apache HTTP server.
Obsoletes: secureweb-devel, apache-devel
Requires: apr-devel, apr-util-devel, pkgconfig, libtool
Requires: httpd = %{version}-%{release}

%description devel
The httpd-devel package contains the APXS binary and other files
that you need to build Dynamic Shared Objects (DSOs) for the
Apache HTTP Server.

If you are installing the Apache HTTP server and you want to be
able to compile or develop additional modules for Apache, you need
to install this package.

%package manual
Group: Documentation
Summary: Documentation for the Apache HTTP server.
Requires: httpd = %{version}-%{release}
Obsoletes: secureweb-manual, apache-manual

%description manual
The httpd-manual package contains the complete manual and
reference guide for the Apache HTTP server. The information can
also be found at http://httpd.apache.org/docs/.

%package tools
Group: System Environment/Daemons
Summary: Tools for use with the Apache HTTP Server

%description tools
The httpd-tools package contains tools which can be used with 
the Apache HTTP Server.

%package -n mod_authnz_ldap
Group: System Environment/Daemons
Summary: LDAP modules for the Apache HTTP server
BuildRequires: openldap-devel
Requires: httpd = %{version}-%{release}, httpd-mmn = %{mmn}

%description -n mod_authnz_ldap
The mod_authnz_ldap module for the Apache HTTP server provides
authentication and authorization against an LDAP server, while
mod_ldap provides an LDAP cache.

%package -n mod_lua
Group: System Environment/Daemons
Summary: Lua language module for the Apache HTTP server
BuildRequires: lua-devel
Requires: httpd = %{version}-%{release}, httpd-mmn = %{mmn}

%description -n mod_lua
The mod_lua module for the Apache HTTP server allows the server to be
extended with scripts written in the Lua programming language.

%package -n mod_proxy_html
Group: System Environment/Daemons
Summary: Proxy HTML filter modules for the Apache HTTP server
BuildRequires: libxml2-devel
Requires: httpd = %{version}-%{release}, httpd-mmn = %{mmn}

%description -n mod_proxy_html
The mod_proxy_html module for the Apache HTTP server provides
a filter to rewrite HTML links within web content when used within
a reverse proxy environment. The mod_xml2enc module provides
enhanced charset/internationalisation support for mod_proxy_html.

%package -n mod_socache_dc
Group: System Environment/Daemons
Summary: Distcache shared object cache module for the Apache HTTP server
BuildRequires: distcache-devel
Requires: httpd = %{version}-%{release}, httpd-mmn = %{mmn}

%description -n mod_socache_dc
The mod_socache_dc module for the Apache HTTP server allows the shared
object cache to use the distcache shared caching mechanism.

%package -n mod_ssl
Group: System Environment/Daemons
Summary: SSL/TLS module for the Apache HTTP server
BuildRequires: openssl-devel
Requires(post): openssl, /bin/cat
Requires(pre): httpd
Requires: httpd = %{version}-%{release}, httpd-mmn = %{mmn}

%description -n mod_ssl
The mod_ssl module provides strong cryptography for the Apache Web
server via the Secure Sockets Layer (SSL) and Transport Layer
Security (TLS) protocols.

%prep
%setup -q

# Safety check: prevent build if defined MMN does not equal upstream MMN.
vmmn=`echo MODULE_MAGIC_NUMBER_MAJOR | cpp -include include/ap_mmn.h | sed -n '
/^2/p'`
if test "x${vmmn}" != "x%{mmn}"; then
   : Error: Upstream MMN is now ${vmmn}, packaged MMN is %{mmn}.
   : Update the mmn macro and rebuild.
   exit 1
fi

%build
# forcibly prevent use of bundled apr, apr-util, pcre
rm -rf srclib/{apr,apr-util,pcre}

%configure \
	--enable-layout=RPM \
	--libdir=%{_libdir} \
	--sysconfdir=%{_sysconfdir}/httpd/conf \
	--includedir=%{_includedir}/httpd \
	--libexecdir=%{_libdir}/httpd/modules \
	--datadir=%{contentdir} \
        --with-installbuilddir=%{_libdir}/httpd/build \
        --enable-mpms-shared=all \
        --with-apr=%{_prefix} --with-apr-util=%{_prefix} \
	--enable-suexec --with-suexec \
	--with-suexec-caller=%{suexec_caller} \
	--with-suexec-docroot=%{contentdir} \
	--with-suexec-logfile=%{_localstatedir}/log/httpd/suexec.log \
	--with-suexec-bin=%{_sbindir}/suexec \
	--with-suexec-uidmin=500 --with-suexec-gidmin=100 \
        --enable-pie \
        --with-pcre \
        --enable-mods-shared=all \
        --enable-ssl --with-ssl --enable-socache-dc --enable-bucketeer \
        --enable-case-filter --enable-case-filter-in \
        --disable-imagemap

make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install

# for holding mod_dav lock database
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/lib/dav

# create a prototype session cache
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/cache/mod_ssl
touch $RPM_BUILD_ROOT%{_localstatedir}/cache/mod_ssl/scache.{dir,pag,sem}

# Make the MMN accessible to module packages
echo %{mmn} > $RPM_BUILD_ROOT%{_includedir}/httpd/.mmn

# Set up /var directories
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/log/httpd
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/cache/httpd/cache-root

# symlinks for /etc/httpd
ln -s ../..%{_localstatedir}/log/httpd $RPM_BUILD_ROOT/etc/httpd/logs
ln -s ../..%{_localstatedir}/run $RPM_BUILD_ROOT/etc/httpd/run
ln -s ../..%{_libdir}/httpd/modules $RPM_BUILD_ROOT/etc/httpd/modules
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/httpd/conf.d

# install SYSV init stuff
mkdir -p $RPM_BUILD_ROOT/etc/rc.d/init.d
install -m755 ./build/rpm/httpd.init \
	$RPM_BUILD_ROOT/etc/rc.d/init.d/httpd
install -m755 ./build/rpm/htcacheclean.init \
        $RPM_BUILD_ROOT/etc/rc.d/init.d/htcacheclean

# install log rotation stuff
mkdir -p $RPM_BUILD_ROOT/etc/logrotate.d
install -m644 ./build/rpm/httpd.logrotate \
	$RPM_BUILD_ROOT/etc/logrotate.d/httpd

# Remove unpackaged files
rm -rf $RPM_BUILD_ROOT%{_libdir}/httpd/modules/*.exp \
       $RPM_BUILD_ROOT%{contentdir}/cgi-bin/* 

# Make suexec a+rw so it can be stripped.  %%files lists real permissions
chmod 755 $RPM_BUILD_ROOT%{_sbindir}/suexec

%pre
# Add the "apache" user
/usr/sbin/useradd -c "Apache" -u 48 \
	-s /sbin/nologin -r -d %{contentdir} apache 2> /dev/null || :

%post
# Register the httpd service
/sbin/chkconfig --add httpd
/sbin/chkconfig --add htcacheclean

%preun
if [ $1 = 0 ]; then
	/sbin/service httpd stop > /dev/null 2>&1
        /sbin/service htcacheclean stop > /dev/null 2>&1
	/sbin/chkconfig --del httpd
        /sbin/chkconfig --del htcacheclean
fi

%post -n mod_ssl
umask 077

if [ ! -f %{_sysconfdir}/httpd/conf/server.key ] ; then
%{_bindir}/openssl genrsa -rand /proc/apm:/proc/cpuinfo:/proc/dma:/proc/filesystems:/proc/interrupts:/proc/ioports:/proc/pci:/proc/rtc:/proc/uptime 1024 > %{_sysconfdir}/httpd/conf/server.key 2> /dev/null
fi

FQDN=`hostname`
if [ "x${FQDN}" = "x" ]; then
   FQDN=localhost.localdomain
fi

if [ ! -f %{_sysconfdir}/httpd/conf/server.crt ] ; then
cat << EOF | %{_bindir}/openssl req -new -key %{_sysconfdir}/httpd/conf/server.key -x509 -days 365 -out %{_sysconfdir}/httpd/conf/server.crt 2>/dev/null
--
SomeState
SomeCity
SomeOrganization
SomeOrganizationalUnit
${FQDN}
root@${FQDN}
EOF
fi

%check
# Check the built modules are all PIC
if readelf -d $RPM_BUILD_ROOT%{_libdir}/httpd/modules/*.so | grep TEXTREL; then
   : modules contain non-relocatable code
   exit 1
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)

%doc ABOUT_APACHE README CHANGES LICENSE NOTICE

%dir %{_sysconfdir}/httpd
%{_sysconfdir}/httpd/modules
%{_sysconfdir}/httpd/logs
%{_sysconfdir}/httpd/run
%dir %{_sysconfdir}/httpd/conf
%dir %{_sysconfdir}/httpd/conf.d
%config(noreplace) %{_sysconfdir}/httpd/conf/httpd.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/magic
%config(noreplace) %{_sysconfdir}/httpd/conf/mime.types
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-autoindex.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-dav.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-default.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-info.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-languages.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-manual.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-mpm.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-multilang-errordoc.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-userdir.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-vhosts.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/proxy-html.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-autoindex.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-dav.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-default.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-info.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-languages.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-manual.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-mpm.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-multilang-errordoc.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-userdir.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-vhosts.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/proxy-html.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/original/httpd.conf

%config %{_sysconfdir}/logrotate.d/httpd
%config %{_sysconfdir}/rc.d/init.d/httpd
%config %{_sysconfdir}/rc.d/init.d/htcacheclean

%{_sbindir}/fcgistarter
%{_sbindir}/htcacheclean
%{_sbindir}/httpd
%{_sbindir}/apachectl
%attr(4510,root,%{suexec_caller}) %{_sbindir}/suexec

%dir %{_libdir}/httpd
%dir %{_libdir}/httpd/modules
%{_libdir}/httpd/modules/mod_access_compat.so
%{_libdir}/httpd/modules/mod_actions.so
%{_libdir}/httpd/modules/mod_alias.so
%{_libdir}/httpd/modules/mod_allowmethods.so
%{_libdir}/httpd/modules/mod_asis.so
%{_libdir}/httpd/modules/mod_auth_basic.so
%{_libdir}/httpd/modules/mod_auth_digest.so
%{_libdir}/httpd/modules/mod_auth_form.so
%{_libdir}/httpd/modules/mod_authn_anon.so
%{_libdir}/httpd/modules/mod_authn_core.so
%{_libdir}/httpd/modules/mod_authn_dbd.so
%{_libdir}/httpd/modules/mod_authn_dbm.so
%{_libdir}/httpd/modules/mod_authn_file.so
%{_libdir}/httpd/modules/mod_authn_socache.so
%{_libdir}/httpd/modules/mod_authz_core.so
%{_libdir}/httpd/modules/mod_authz_dbd.so
%{_libdir}/httpd/modules/mod_authz_dbm.so
%{_libdir}/httpd/modules/mod_authz_groupfile.so
%{_libdir}/httpd/modules/mod_authz_host.so
%{_libdir}/httpd/modules/mod_authz_owner.so
%{_libdir}/httpd/modules/mod_authz_user.so
%{_libdir}/httpd/modules/mod_autoindex.so
%{_libdir}/httpd/modules/mod_bucketeer.so
%{_libdir}/httpd/modules/mod_buffer.so
%{_libdir}/httpd/modules/mod_cache_disk.so
%{_libdir}/httpd/modules/mod_cache.so
%{_libdir}/httpd/modules/mod_case_filter.so
%{_libdir}/httpd/modules/mod_case_filter_in.so
%{_libdir}/httpd/modules/mod_cgid.so
%{_libdir}/httpd/modules/mod_charset_lite.so
%{_libdir}/httpd/modules/mod_data.so
%{_libdir}/httpd/modules/mod_dav_fs.so
%{_libdir}/httpd/modules/mod_dav_lock.so
%{_libdir}/httpd/modules/mod_dav.so
%{_libdir}/httpd/modules/mod_dbd.so
%{_libdir}/httpd/modules/mod_deflate.so
%{_libdir}/httpd/modules/mod_dialup.so
%{_libdir}/httpd/modules/mod_dir.so
%{_libdir}/httpd/modules/mod_dumpio.so
%{_libdir}/httpd/modules/mod_echo.so
%{_libdir}/httpd/modules/mod_env.so
%{_libdir}/httpd/modules/mod_expires.so
%{_libdir}/httpd/modules/mod_ext_filter.so
%{_libdir}/httpd/modules/mod_file_cache.so
%{_libdir}/httpd/modules/mod_filter.so
%{_libdir}/httpd/modules/mod_headers.so
%{_libdir}/httpd/modules/mod_heartbeat.so
%{_libdir}/httpd/modules/mod_heartmonitor.so
%{_libdir}/httpd/modules/mod_include.so
%{_libdir}/httpd/modules/mod_info.so
%{_libdir}/httpd/modules/mod_lbmethod_bybusyness.so
%{_libdir}/httpd/modules/mod_lbmethod_byrequests.so
%{_libdir}/httpd/modules/mod_lbmethod_bytraffic.so
%{_libdir}/httpd/modules/mod_lbmethod_heartbeat.so
%{_libdir}/httpd/modules/mod_log_config.so
%{_libdir}/httpd/modules/mod_log_debug.so
%{_libdir}/httpd/modules/mod_log_forensic.so
%{_libdir}/httpd/modules/mod_logio.so
%{_libdir}/httpd/modules/mod_mime_magic.so
%{_libdir}/httpd/modules/mod_mime.so
%{_libdir}/httpd/modules/mod_mpm_event.so
%{_libdir}/httpd/modules/mod_mpm_prefork.so
%{_libdir}/httpd/modules/mod_mpm_worker.so
%{_libdir}/httpd/modules/mod_negotiation.so
%{_libdir}/httpd/modules/mod_proxy_ajp.so
%{_libdir}/httpd/modules/mod_proxy_balancer.so
%{_libdir}/httpd/modules/mod_proxy_connect.so
%{_libdir}/httpd/modules/mod_proxy_express.so
%{_libdir}/httpd/modules/mod_proxy_fcgi.so
%{_libdir}/httpd/modules/mod_proxy_fdpass.so
%{_libdir}/httpd/modules/mod_proxy_ftp.so
%{_libdir}/httpd/modules/mod_proxy_http.so
%{_libdir}/httpd/modules/mod_proxy_scgi.so
%{_libdir}/httpd/modules/mod_proxy.so
%{_libdir}/httpd/modules/mod_ratelimit.so
%{_libdir}/httpd/modules/mod_reflector.so
%{_libdir}/httpd/modules/mod_remoteip.so
%{_libdir}/httpd/modules/mod_reqtimeout.so
%{_libdir}/httpd/modules/mod_request.so
%{_libdir}/httpd/modules/mod_rewrite.so
%{_libdir}/httpd/modules/mod_sed.so
%{_libdir}/httpd/modules/mod_session_cookie.so
%{_libdir}/httpd/modules/mod_session_crypto.so
%{_libdir}/httpd/modules/mod_session_dbd.so
%{_libdir}/httpd/modules/mod_session.so
%{_libdir}/httpd/modules/mod_setenvif.so
%{_libdir}/httpd/modules/mod_slotmem_plain.so
%{_libdir}/httpd/modules/mod_slotmem_shm.so
%{_libdir}/httpd/modules/mod_socache_dbm.so
%{_libdir}/httpd/modules/mod_socache_memcache.so
%{_libdir}/httpd/modules/mod_socache_shmcb.so
%{_libdir}/httpd/modules/mod_speling.so
%{_libdir}/httpd/modules/mod_status.so
%{_libdir}/httpd/modules/mod_substitute.so
%{_libdir}/httpd/modules/mod_suexec.so
%{_libdir}/httpd/modules/mod_unique_id.so
%{_libdir}/httpd/modules/mod_unixd.so
%{_libdir}/httpd/modules/mod_userdir.so
%{_libdir}/httpd/modules/mod_usertrack.so
%{_libdir}/httpd/modules/mod_version.so
%{_libdir}/httpd/modules/mod_vhost_alias.so
%{_libdir}/httpd/modules/mod_watchdog.so

%dir %{contentdir}
%dir %{contentdir}/cgi-bin
%dir %{contentdir}/html
%dir %{contentdir}/icons
%dir %{contentdir}/error
%dir %{contentdir}/error/include
%{contentdir}/icons/*
%{contentdir}/error/README
%{contentdir}/html/index.html
%config(noreplace) %{contentdir}/error/*.var
%config(noreplace) %{contentdir}/error/include/*.html

%attr(0700,root,root) %dir %{_localstatedir}/log/httpd

%attr(0700,apache,apache) %dir %{_localstatedir}/lib/dav
%attr(0700,apache,apache) %dir %{_localstatedir}/cache/httpd/cache-root

%{_mandir}/man1/*
%{_mandir}/man8/suexec*
%{_mandir}/man8/apachectl.8*
%{_mandir}/man8/httpd.8*
%{_mandir}/man8/htcacheclean.8*
%{_mandir}/man8/fcgistarter.8*

%files manual
%defattr(-,root,root)
%{contentdir}/manual
%{contentdir}/error/README

%files tools
%defattr(-,root,root)
%{_bindir}/ab
%{_bindir}/htdbm
%{_bindir}/htdigest
%{_bindir}/htpasswd
%{_bindir}/logresolve
%{_bindir}/httxt2dbm
%{_sbindir}/rotatelogs
%{_mandir}/man1/htdbm.1*
%{_mandir}/man1/htdigest.1*
%{_mandir}/man1/htpasswd.1*
%{_mandir}/man1/httxt2dbm.1*
%{_mandir}/man1/ab.1*
%{_mandir}/man1/logresolve.1*
%{_mandir}/man8/rotatelogs.8*
%doc LICENSE NOTICE

%files -n mod_authnz_ldap
%defattr(-,root,root)
%{_libdir}/httpd/modules/mod_ldap.so
%{_libdir}/httpd/modules/mod_authnz_ldap.so

%files -n mod_lua
%defattr(-,root,root)
%{_libdir}/httpd/modules/mod_lua.so

%files -n mod_proxy_html
%defattr(-,root,root)
%{_libdir}/httpd/modules/mod_proxy_html.so
%{_libdir}/httpd/modules/mod_xml2enc.so

%files -n mod_socache_dc
%defattr(-,root,root)
%{_libdir}/httpd/modules/mod_socache_dc.so

%files -n mod_ssl
%defattr(-,root,root)
%{_libdir}/httpd/modules/mod_ssl.so
%config(noreplace) %{_sysconfdir}/httpd/conf/original/extra/httpd-ssl.conf
%config(noreplace) %{_sysconfdir}/httpd/conf/extra/httpd-ssl.conf
%attr(0700,apache,root) %dir %{_localstatedir}/cache/mod_ssl
%attr(0600,apache,root) %ghost %{_localstatedir}/cache/mod_ssl/scache.dir
%attr(0600,apache,root) %ghost %{_localstatedir}/cache/mod_ssl/scache.pag
%attr(0600,apache,root) %ghost %{_localstatedir}/cache/mod_ssl/scache.sem

%files devel
%defattr(-,root,root)
%{_includedir}/httpd
%{_bindir}/apxs
%{_sbindir}/checkgid
%{_bindir}/dbmmanage
%{_sbindir}/envvars*
%{_mandir}/man1/dbmmanage.1*
%{_mandir}/man1/apxs.1*
%dir %{_libdir}/httpd/build
%{_libdir}/httpd/build/*.mk
%{_libdir}/httpd/build/instdso.sh
%{_libdir}/httpd/build/config.nice
%{_libdir}/httpd/build/mkdir.sh

