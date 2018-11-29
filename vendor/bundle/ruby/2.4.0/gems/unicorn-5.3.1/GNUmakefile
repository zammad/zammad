# use GNU Make to run tests in parallel, and without depending on RubyGems
all:: test

RLFLAGS = -G2

MRI = ruby
RUBY = ruby
RAKE = rake
RAGEL = ragel
RSYNC = rsync
OLDDOC = olddoc
RDOC = rdoc

GIT-VERSION-FILE: .FORCE-GIT-VERSION-FILE
	@./GIT-VERSION-GEN
-include GIT-VERSION-FILE
-include local.mk
ruby_bin := $(shell which $(RUBY))
ifeq ($(DLEXT),) # "so" for Linux
  DLEXT := $(shell $(RUBY) -rrbconfig -e 'puts RbConfig::CONFIG["DLEXT"]')
endif
ifeq ($(RUBY_VERSION),)
  RUBY_VERSION := $(shell $(RUBY) -e 'puts RUBY_VERSION')
endif

RUBY_ENGINE := $(shell $(RUBY) -e 'puts((RUBY_ENGINE rescue "ruby"))')

MYLIBS = $(RUBYLIB)

# dunno how to implement this as concisely in Ruby, and hell, I love awk
awk_slow := awk '/def test_/{print FILENAME"--"$$2".n"}' 2>/dev/null

slow_tests := test/unit/test_server.rb test/exec/test_exec.rb \
  test/unit/test_signals.rb test/unit/test_upload.rb
log_suffix = .$(RUBY_ENGINE).$(RUBY_VERSION).log
T := $(filter-out $(slow_tests), $(wildcard test/*/test*.rb))
T_n := $(shell $(awk_slow) $(slow_tests))
T_log := $(subst .rb,$(log_suffix),$(T))
T_n_log := $(subst .n,$(log_suffix),$(T_n))
test_prefix = $(CURDIR)/test/$(RUBY_ENGINE)-$(RUBY_VERSION)

ext := ext/unicorn_http
c_files := $(ext)/unicorn_http.c $(ext)/httpdate.c $(wildcard $(ext)/*.h)
rl_files := $(wildcard $(ext)/*.rl)
base_bins := unicorn unicorn_rails
bins := $(addprefix bin/, $(base_bins))
man1_rdoc := $(addsuffix _1, $(base_bins))
man1_bins := $(addsuffix .1, $(base_bins))
man1_paths := $(addprefix man/man1/, $(man1_bins))
rb_files := $(bins) $(shell find lib ext -type f -name '*.rb')
inst_deps := $(c_files) $(rb_files) GNUmakefile test/test_helper.rb

ragel: $(ext)/unicorn_http.c
$(ext)/unicorn_http.c: $(rl_files)
	cd $(@D) && $(RAGEL) unicorn_http.rl -C $(RLFLAGS) -o $(@F)
$(ext)/Makefile: $(ext)/extconf.rb $(c_files)
	cd $(@D) && $(RUBY) extconf.rb
$(ext)/unicorn_http.$(DLEXT): $(ext)/Makefile
	$(MAKE) -C $(@D)
http: $(ext)/unicorn_http.$(DLEXT)

# only used for tests
http-install: $(ext)/unicorn_http.$(DLEXT)
	install -m644 $< lib/

test-install: $(test_prefix)/.stamp
$(test_prefix)/.stamp: $(inst_deps)
	mkdir -p $(test_prefix)/.ccache
	tar cf - $(inst_deps) GIT-VERSION-GEN | \
	  (cd $(test_prefix) && tar xf -)
	$(MAKE) -C $(test_prefix) clean
	$(MAKE) -C $(test_prefix) http-install shebang RUBY="$(RUBY)"
	> $@

# this is only intended to be run within $(test_prefix)
shebang: $(bins)
	$(MRI) -i -p -e '$$_.gsub!(%r{^#!.*$$},"#!$(ruby_bin)")' $^

t_log := $(T_log) $(T_n_log)
test: $(T) $(T_n)
	@cat $(t_log) | $(MRI) test/aggregate.rb
	@$(RM) $(t_log)

test-exec: $(wildcard test/exec/test_*.rb)
test-unit: $(wildcard test/unit/test_*.rb)
$(slow_tests): $(test_prefix)/.stamp
	@$(MAKE) $(shell $(awk_slow) $@)

# ensure we can require just the HTTP parser without the rest of unicorn
test-require: $(ext)/unicorn_http.$(DLEXT)
	$(RUBY) --disable-gems -I$(ext) -runicorn_http -e Unicorn

test-integration: $(test_prefix)/.stamp
	$(MAKE) -C t

check: test-require test test-integration
test-all: check

TEST_OPTS = -v
check_test = grep '0 failures, 0 errors' $(t) >/dev/null
ifndef V
       quiet_pre = @echo '* $(arg)$(extra)';
       quiet_post = >$(t) 2>&1 && $(check_test)
else
       # we can't rely on -o pipefail outside of bash 3+,
       # so we use a stamp file to indicate success and
       # have rm fail if the stamp didn't get created
       stamp = $@$(log_suffix).ok
       quiet_pre = @echo $(RUBY) $(arg) $(TEST_OPTS); ! test -f $(stamp) && (
       quiet_post = && > $(stamp) )2>&1 | tee $(t); \
         rm $(stamp) 2>/dev/null && $(check_test)
endif

# not all systems have setsid(8), we need it because we spam signals
# stupidly in some tests...
rb_setsid := $(RUBY) -e 'Process.setsid' -e 'exec *ARGV'

# TRACER='strace -f -o $(t).strace -s 100000'
run_test = $(quiet_pre) \
  $(rb_setsid) $(TRACER) $(RUBY) -w $(arg) $(TEST_OPTS) $(quiet_post) || \
  (sed "s,^,$(extra): ," >&2 < $(t); exit 1)

%.n: arg = $(subst .n,,$(subst --, -n ,$@))
%.n: t = $(subst .n,$(log_suffix),$@)
%.n: export PATH := $(test_prefix)/bin:$(PATH)
%.n: export RUBYLIB := $(test_prefix)/lib:$(MYLIBS)
%.n: $(test_prefix)/.stamp
	$(run_test)

$(T): arg = $@
$(T): t = $(subst .rb,$(log_suffix),$@)
$(T): export PATH := $(test_prefix)/bin:$(PATH)
$(T): export RUBYLIB := $(test_prefix)/lib:$(MYLIBS)
$(T): $(test_prefix)/.stamp
	$(run_test)

install: $(bins) $(ext)/unicorn_http.c
	$(prep_setup_rb)
	$(RM) -r .install-tmp
	mkdir .install-tmp
	cp -p bin/* .install-tmp
	$(RUBY) setup.rb all
	$(RM) $^
	mv .install-tmp/* bin/
	$(RM) -r .install-tmp
	$(prep_setup_rb)

setup_rb_files := .config InstalledFiles
prep_setup_rb := @-$(RM) $(setup_rb_files);$(MAKE) -C $(ext) clean

clean:
	-$(MAKE) -C $(ext) clean
	-$(MAKE) -C Documentation clean
	$(RM) $(ext)/Makefile
	$(RM) $(setup_rb_files) $(t_log)
	$(RM) -r $(test_prefix) man

man html:
	$(MAKE) -C Documentation install-$@

pkg_extra := GIT-VERSION-FILE lib/unicorn/version.rb LATEST NEWS \
             $(ext)/unicorn_http.c $(man1_paths)

NEWS:
	$(OLDDOC) prepare

.manifest: $(ext)/unicorn_http.c man NEWS
	(git ls-files && for i in $@ $(pkg_extra); do echo $$i; done) | \
	  LC_ALL=C sort > $@+
	cmp $@+ $@ || mv $@+ $@
	$(RM) $@+

PLACEHOLDERS = $(man1_rdoc)
doc: .document $(ext)/unicorn_http.c man html .olddoc.yml $(PLACEHOLDERS)
	find bin lib -type f -name '*.rbc' -exec rm -f '{}' ';'
	$(RM) -r doc
	$(OLDDOC) prepare
	$(RDOC) -f oldweb
	$(OLDDOC) merge
	install -m644 COPYING doc/COPYING
	install -m644 NEWS.atom.xml doc/NEWS.atom.xml
	install -m644 $(shell LC_ALL=C grep '^[A-Z]' .document) doc/
	install -m644 $(man1_paths) doc/
	tar cf - $$(git ls-files examples/) | (cd doc && tar xf -)

# publishes docs to https://bogomips.org/unicorn/
publish_doc:
	-git set-file-times
	$(MAKE) doc
	$(MAKE) doc_gz
	chmod 644 $$(find doc -type f)
	$(RSYNC) -av doc/ bogomips.org:/srv/bogomips/unicorn/
	git ls-files | xargs touch

# Create gzip variants of the same timestamp as the original so nginx
# "gzip_static on" can serve the gzipped versions directly.
doc_gz: docs = $(shell find doc -type f ! -regex '^.*\.gz$$')
doc_gz:
	for i in $(docs); do \
	  gzip --rsyncable -9 < $$i > $$i.gz; touch -r $$i $$i.gz; done

ifneq ($(VERSION),)
rfpackage := unicorn
pkggem := pkg/$(rfpackage)-$(VERSION).gem
pkgtgz := pkg/$(rfpackage)-$(VERSION).tgz

# ensures we're actually on the tagged $(VERSION), only used for release
verify:
	test x"$(shell umask)" = x0022
	git rev-parse --verify refs/tags/v$(VERSION)^{}
	git diff-index --quiet HEAD^0
	test `git rev-parse --verify HEAD^0` = \
	     `git rev-parse --verify refs/tags/v$(VERSION)^{}`

fix-perms:
	git ls-tree -r HEAD | awk '/^100644 / {print $$NF}' | xargs chmod 644
	git ls-tree -r HEAD | awk '/^100755 / {print $$NF}' | xargs chmod 755

gem: $(pkggem)

install-gem: $(pkggem)
	gem install --local $(CURDIR)/$<

$(pkggem): .manifest fix-perms
	gem build $(rfpackage).gemspec
	mkdir -p pkg
	mv $(@F) $@

$(pkgtgz): distdir = $(basename $@)
$(pkgtgz): HEAD = v$(VERSION)
$(pkgtgz): .manifest fix-perms
	@test -n "$(distdir)"
	$(RM) -r $(distdir)
	mkdir -p $(distdir)
	tar cf - $$(cat .manifest) | (cd $(distdir) && tar xf -)
	cd pkg && tar cf - $(basename $(@F)) | gzip -9 > $(@F)+
	mv $@+ $@

package: $(pkgtgz) $(pkggem)

release: verify package
	# push gem to Gemcutter
	gem push $(pkggem)
else
gem install-gem: GIT-VERSION-FILE
	$(MAKE) $@ VERSION=$(GIT_VERSION)
endif

$(PLACEHOLDERS):
	echo olddoc_placeholder > $@

.PHONY: .FORCE-GIT-VERSION-FILE doc $(T) $(slow_tests) man
.PHONY: test-install
