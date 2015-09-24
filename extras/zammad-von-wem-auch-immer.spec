Name: zammad
Version: 0.1
Release: 1%{?dist}
Summary: Zammad Application
# Some of the gems compile, and thus this can't be noarch
BuildArch:        x86_64
Group: Application/Internet
License: AGPL
URL: https://github.com/martinie/zammmad
# XXX You'll have to create the logrotate script for your application
Source0: %{name}.logrotate
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

# XXX Building this rpm requires that bundle is available on the path of the user
# that is running rpmbuild. But I'm not sure how to require that there is a
# bundle in the path.
#BuildRequires: /usr/bin/bundle
# XXX Also require gem on the PATH
# BuildRequires: /usr/bin/gem

# XXX Note that you might not require all the below. It will depend on what your gems require to build.

# From docs: http://nokogiri.org/tutorials/installing_nokogiri.html
# and: https://github.com/thoughtbot/capybara-webkit/wiki/Installing-QT
# which hinted that I should look for something like qt webkit devel ...
BuildRequires: libxml2 gcc ruby-devel libxml2-devel libxslt libxslt-devel
# for...I forgot to record what gem requires this to build...
BuildRequires: qt-devel qtwebkit-devel
# for curb
BuildRequires: libcurl-devel
# for sqlite3
BuildRequires: sqlite-devel
# ^^ There may be more requirements above for building on a new dev/rpmbuild env

# XXX Remove if not using apache/passenger/mysql
# Assuming will run via passenger + apache
Requires: mod_passenger, httpd
# And use mysql as the db
Requires: mysql-server

# In order to rotate the logs
Requires: logrotate

# What repository to pull the actual code from
# (assuming git here, you'll need to change for svn or hg)
%define git_repo git@github.com:martini/%{name}.git

#
# DIRS
# - Trying to follow Linux file system hierarchy
#
%define appdir %{rails_home}/%{name}
%define docdir %{_docdir}/railsapps/%{name}
%define libdir %{_libdir}/railsapps/%{name}
%define logdir /var/log/railsapps/%{name}
%define configdir /etc/railsapps/%{name}
%define cachedir /var/cache/railsapps/%{name}
%define datadir /var/lib/railsapps/%{name}
%define logrotatedir /etc/logrotate.d/

%description
Some description of the application

%prep
rm -rf ./%{name}
git clone %{git_repo}
pushd %{name}
        git checkout v%{version}
popd


%build
pushd %{name}

        # Install all required gems into ./vendor/bundle using the handy bundle commmand
        bundle install --deployment
        
        # Compile assets, this only has to be done once AFAIK, so in the RPM is fine
        rm -rf ./public/assets/*
        bundle exec rake assets:precompile

        # For some reason bundler doesn't install itself, this is probably right,
        # but I guess it expects bundler to be on the server being deployed to
        # already. But the rails-helloworld app crashes on passenger looking for
        # bundler, so it would seem to me to be required. So, I used gem to install
        # bundler after bundle deployment. :) And the app then works under passenger.

        PWD=`pwd`
        cat > gemrc <<EOGEMRC
gemhome: $PWD/vendor/bundle/ruby/1.8
gempath:
- $PWD/vendor/bundle/ruby/1.8
EOGEMRC
        #gem --source %{gem_source} --config-file ./gemrc install bundler
        gem --config-file ./gemrc install bundler
        # Don't need the gemrc any more...
        rm ./gemrc

        # Some of the files in here have /usr/local/bin/ruby set as the bang
        # but that won't work, and makes the rpmbuild process add /usr/local/bin/ruby
        # to the dependencies. So I'm changing that here. Either way it prob won't
        # work. But at least this rids us of the dependencie that we can never meet.
        for f in `grep -ril "\/usr\/local\/bin\/ruby" ./vendor`; do
                sed -i "s|/usr/local/bin/ruby|/usr/bin/ruby|g" $f
                head -1 $f
        done

popd


%install
# Create all the defined directories
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{appdir}
mkdir -p $RPM_BUILD_ROOT/%{docdir}
mkdir -p $RPM_BUILD_ROOT/%{libdir}
mkdir -p $RPM_BUILD_ROOT/%{logdir}
mkdir -p $RPM_BUILD_ROOT/%{configdir}
mkdir -p $RPM_BUILD_ROOT/%{cachedir}
mkdir -p $RPM_BUILD_ROOT/%{datadir}
mkdir -p $RPM_BUILD_ROOT/%{logrotatedir}


# Start moving files into the proper place in the build root
pushd %{name}

        #
        # ./public/assets
        #

        # Again rake assets:precompile creates public/assets which
        # shouldn't be in /usr/share/railsapps/%{name} prob cache
        #rm -rf ./public/assets/*
        mv ./public/assets $RPM_BUILD_ROOT/%{cachedir}
        ln -s %{cachedir}/assets ./public/assets

        #
        # Doc
        #

        mv ./doc $RPM_BUILD_ROOT/%{docdir}

        #
        # Config
        #
        # - only doing database.yml now, might be wrong...
        # - XXX What other config files are there if any?

        mv ./config/database.yml $RPM_BUILD_ROOT/%{configdir}
        pushd config
                ln -s %{configdir}/database.yml ./database.yml
        popd

        #
        # lib
        #

        mv ./vendor $RPM_BUILD_ROOT/%{libdir}
        ln -s %{libdir}/vendor ./vendor

        #
        # tmp/cache
        #

        mv ./tmp $RPM_BUILD_ROOT/%{cachedir}
        ln -s %{cachedir}/tmp ./tmp

        #
        # log
        #

        # Only do logdir not logdir/log
        rm -rf ./log
        #rm ./log/development.log
        #rm ./log/test.log
        #mv ./log $RPM_BUILD_ROOT/%{logdir}
        ln -s %{logdir} ./log
        
        #
        # Everything left goes in appdir
        #

        mv ./* $RPM_BUILD_ROOT/%{appdir}

        #
        # logrotate
        #
        cp %{SOURCE0} $RPM_BUILD_ROOT/%{logrotatedir}/%{name}

popd

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{appdir}
%{libdir}
%{docdir}
%config %{configdir}/database.yml
# passenger runs as nobody apparently and then http as apache, and I'm not sure which
# needs which...so for now do nobody:apache...wonder if it should be set to run as apache?
%attr(770,nobody,apache) %{logdir}
%attr(770,nobody,apache) %{cachedir}
# %dir allows an empty directory, which this will be at an initial install
%attr(770,nobody,apache) %dir %{datadir}
%{logrotatedir}/%{name}
%doc


