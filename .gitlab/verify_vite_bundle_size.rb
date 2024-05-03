#!/usr/bin/env ruby
# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'yaml'
require 'pathname'

class VerifyViteBundleSize

  FILENAME = Pathname.new(__dir__).join('../tmp/vite-bundle-stats.yml')
  MAX_CHUNK_SIZE = 500 * 1_024

  def self.run
    puts 'Verifying vite bundle size…'
    YAML.load(FILENAME.read).each_pair do |chunk_name, chunk_files|
      chunk_size = 0
      chunk_files.each_value do |v|
        chunk_size += + v['gzip']
      end
      if chunk_size > MAX_CHUNK_SIZE
        raise "Chunk #{chunk_name} has a size of #{chunk_size}, which is higher than the allowed #{MAX_CHUNK_SIZE}.\n"
      end
    end

    puts "All chunks are smaller than the allowed #{MAX_CHUNK_SIZE}."
  end
end

VerifyViteBundleSize.run
