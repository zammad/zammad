# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :flush do

    desc 'Flushes all caches'
    task :cache do # rubocop:disable Rails/RakeEnvironment
      FileUtils.rm_rf(Rails.root.join('tmp/cache*'))
    end
  end
end
