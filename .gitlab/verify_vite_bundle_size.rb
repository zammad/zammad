#!/usr/bin/env ruby
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'yaml'
require 'pathname'

class VerifyViteBundleSize

  FILENAME = Pathname.new(__dir__).join('../tmp/vite-bundle-stats.yml')

  # app/frontend/shared/components/Form/fields/FieldEditor/FieldEditorInput.vue is too big right now. We need to split it up.
  # For now, we allow a maximum chunk size of 550 KB.
  # TODO: Split up the file mentioned above and reduce the maximum chunk size to 500 KB.
  MAX_CHUNK_SIZE = 550 * 1_024

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
