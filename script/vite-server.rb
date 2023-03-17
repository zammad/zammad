#!/usr/bin/env ruby
# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'socket'

HOST = ENV['ZAMMAD_BIND_IP'] || '127.0.0.1'
PORT = ENV['ZAMMAD_RAILS_PORT'] || 3000

# Waits for Puma server on configured port to become ready and then starts vite dev server
loop do
  begin
    TCPSocket.new(HOST, PORT.to_i)
    break
  rescue Errno::ECONNREFUSED
    puts "Waiting for Puma server at #{HOST}:#{PORT}..."
    sleep 1
  end
end

require 'rubygems'
require 'bundler/setup'

load Gem.bin_path('vite_ruby', 'vite')
