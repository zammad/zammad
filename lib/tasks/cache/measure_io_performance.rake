# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :cache do
  desc 'Measure cache IO performance (MB/s)'
  task measure_io_performance: :environment do
    key_base      = "io_test_#{SecureRandom.hex(8)}"
    data_size_mb  = 1000
    chunk_size    = 512 * 1024
    chunk_size_mb = chunk_size.to_f / 1024 / 1024
    chunks        = (data_size_mb / chunk_size_mb).ceil

    payload = 'a' * chunk_size

    write_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    chunks.times do |i|
      Rails.cache.write("#{key_base}_#{i}", payload)
    end
    write_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - write_start

    read_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    chunks.times do |i|
      Rails.cache.read("#{key_base}_#{i}")
    end
    read_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - read_start

    delete_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    chunks.times do |i|
      Rails.cache.delete("#{key_base}_#{i}")
    end
    delete_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - delete_start

    total_mb    = chunks * chunk_size_mb
    write_mbps  = total_mb / write_time
    read_mbps   = total_mb / read_time
    delete_mbps = total_mb / delete_time

    puts 'Cache IO Performance:'
    puts "Write:  #{format('%.2f', write_mbps)} MB/s"
    puts "Read:   #{format('%.2f', read_mbps)} MB/s"
    puts "Delete: #{format('%.2f', delete_mbps)} MB/s"
  end
end
