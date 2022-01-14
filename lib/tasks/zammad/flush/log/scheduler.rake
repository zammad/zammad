# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :flush do

    namespace :log do

      desc 'Flushes the log Rails file of the given or active environment'
      task :rails, [:env] do |_task, args| # rubocop:disable Rails/RakeEnvironment
        env = args.fetch(:env, Rails.env)
        File.write(Rails.root.join('log', "#{env}.log"), '')
      end
    end
  end
end
