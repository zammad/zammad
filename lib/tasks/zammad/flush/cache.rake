# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :flush do

    desc 'Flushes all caches'
    task :cache do # rubocop:disable Rails/RakeEnvironment
      FileUtils.rm_rf(Rails.root.join('tmp/cache*'))
    end
  end
end
