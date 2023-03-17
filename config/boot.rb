# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Unfortunately, Rails empties ARGV when executing commands, so remember it now.
require_relative '../lib/argv_helper'

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
