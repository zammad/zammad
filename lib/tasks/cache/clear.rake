# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :cache do
  desc 'Clears the rails cache'
  task clear: :environment do
    Rails.cache.clear
    puts 'done.'
  end
end
