#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

# used to generate ci reports, see ci_reporter documentation
require 'ci/reporter/rake/rspec'
Zammad::Application.load_tasks
