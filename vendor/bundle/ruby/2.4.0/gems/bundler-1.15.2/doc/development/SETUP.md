# Development setup

Bundler doesn't use a Gemfile to list development dependencies, because when we tried it we couldn't tell if we were awake or it was just another level of dreams. To work on Bundler, you'll probably want to do a couple of things.

1. Install `groff-base` and `graphviz` packages using your package manager, e.g for ubuntu

      $ sudo apt-get install graphviz groff-base -y

   and for OS X (with brew installed)

      $ brew install graphviz homebrew/dupes/groff

2. Install Bundler's development dependencies

      $ bin/rake spec:deps

3. Run the test suite, to make sure things are working

      $ bin/rake spec

4. Set up a shell alias to run Bundler from your clone, e.g. a Bash alias:

      `$ alias dbundle='ruby -I /path/to/bundler/lib /path/to/bundler/exe/bundle'`

## Debugging with `pry`

To dive into the code with Pry: `RUBYOPT=-rpry dbundle` to require pry and then run commands.
