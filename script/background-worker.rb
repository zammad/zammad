#!/usr/bin/env ruby
# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Dir.chdir dir

require 'bundler'
require File.join(dir, 'config', 'environment')

BackgroundServices::Cli.start(ARGV)
