# Filing Issues: a guide

So! You're having problems with Bundler. This file is here to help. If you're running into an error, try reading the rest of this file for help. If you can't figure out how to solve your problem, there are also instructions on how to report a bug.

Before filing an issue, check our [troubleshooting guide](../TROUBLESHOOTING.md) for quick fixes to common issues.

## Documentation

Instructions for common Bundler uses can be found on the [Bundler documentation site](http://bundler.io/).

Detailed information about each Bundler command, including help with common problems, can be found in the [Bundler man pages](http://bundler.io/man/bundle.1.html) or [Bundler Command Line Reference](http://bundler.io/v1.11/commands.html).

## Reporting unresolved problems

Check our [troubleshooting common issues guide](../TROUBLESHOOTING.md) and see if your issues is resolved using the steps provided.

Hopefully the troubleshooting steps above resolved your problem! If things still aren't working the way you expect them to, please let us know so that we can diagnose and hopefully fix the problem you're having.

**The best way to report a bug is by providing a reproduction script.** See these examples:

* [Git environment variables causing install to fail.](https://gist.github.com/xaviershay/6207550)
* [Multiple gems in a repository cannot be updated independently.](https://gist.github.com/xaviershay/6295889)

A half working script with comments for the parts you were unable to automate is still appreciated.

If you are unable to do that, please include the following information in your report:

 - What you're trying to accomplish
 - The command you ran
 - What you expected to happen
 - What actually happened
 - The exception backtrace(s), if any
 - Everything output by running `bundle env`

If your version of Bundler does not have the `bundle env` command, then please include:

 - Your `Gemfile`
 - Your `Gemfile.lock`
 - Your Bundler configuration settings (run `bundle config`)
 - What version of bundler you are using (run `bundle -v`)
 - What version of Ruby you are using (run `ruby -v`)
 - What version of Rubygems you are using (run `gem -v`)
 - Whether you are using RVM, and if so what version (run `rvm -v`)
 - Whether you have the `rubygems-bundler` gem, which can break gem executables (run `gem list rubygems-bundler`)
 - Whether you have the `open_gem` gem, which can cause rake activation conflicts (run `gem list open_gem`)

If you have either `rubygems-bundler` or `open_gem` installed, please try removing them and then following the troubleshooting steps above before opening a new ticket.

[Create a gist](https://gist.github.com) containing all of that information, then visit the [Bundler issue tracker](https://github.com/bundler/bundler/issues) and [create a ticket](https://github.com/bundler/bundler/issues/new) describing your problem and linking to your gist.

Thanks for reporting issues and helping make Bundler better!
