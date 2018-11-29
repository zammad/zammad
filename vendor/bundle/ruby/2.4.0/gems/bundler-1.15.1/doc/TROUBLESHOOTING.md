# Troubleshooting common issues

Stuck using Bundler? Browse these common issues before [filing a new issue](contributing/ISSUES.md).

## Permission denied when installing bundler

Certain operating systems such as MacOS and Ubuntu have versions of Ruby that require elevated privileges to install gems.

    ERROR:  While executing gem ... (Gem::FilePermissionError)
      You don't have write permissions for the /Library/Ruby/Gems/2.0.0 directory.

There are multiple ways to solve this issue. You can install bundler with elevated privilges using `sudo` or `su`.

    sudo gem install bundler

If you cannot elevated your privileges or do not want to globally install Bundler, you can use the `--user-install` option.

    gem install bundler --user-install

This will install Bundler into your home directory. Note that you will need to append `~/.gem/ruby/<ruby version>/bin` to your `$PATH` variable to use `bundle`.

## Heroku errors

Please open a ticket with [Heroku](https://www.heroku.com) if you're having trouble deploying. They have a professional support team who can help you resolve Heroku issues far better than the Bundler team can. If the problem that you are having turns out to be a bug in Bundler itself, [Heroku support](https://www.heroku.com/support) can get the exact details to us.

## Other problems

First, figure out exactly what it is that you're trying to do (see [XY Problem](http://xyproblem.info/)). Then, go to the [Bundler documentation website](http://bundler.io) and see if we have instructions on how to do that.

Second, check [the compatibility
list](http://bundler.io/compatibility.html), and make sure that the version of Bundler that you are using works with the versions of Ruby and Rubygems that you are using. To see your versions:

    # Bundler version
    bundle -v

    # Ruby version
    ruby -v

    # Rubygems version
    gem -v

If these instructions don't work, or you can't find any appropriate instructions, you can try these troubleshooting steps:

    # Remove user-specific gems and git repos
    rm -rf ~/.bundle/ ~/.gem/bundler/ ~/.gems/cache/bundler/

    # Remove system-wide git repos and git checkouts
    rm -rf $GEM_HOME/bundler/ $GEM_HOME/cache/bundler/

    # Remove project-specific settings
    rm -rf .bundle/

    # Remove project-specific cached gems and repos
    rm -rf vendor/cache/

    # Remove the saved resolve of the Gemfile
    rm -rf Gemfile.lock

    # Uninstall the rubygems-bundler and open_gem gems
    rvm gemset use global # if using rvm
    gem uninstall rubygems-bundler open_gem

    # Try to install one more time
    bundle install
