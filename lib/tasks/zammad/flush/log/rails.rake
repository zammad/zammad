# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :flush do

    namespace :log do

      desc 'Flushes all scheduler log files'
      task :scheduler do # rubocop:disable Rails/RakeEnvironment
        %w[err out].each do |suffix|
          File.write(Rails.root.join('log', "scheduler_#{suffix}.log"), '')
        end
      end
    end
  end
end
