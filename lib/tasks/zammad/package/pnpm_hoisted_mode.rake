# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :package do

    desc 'Put PNPM node linker into hoisted mode if preserve symlinks option is active.'
    task pnpm_hoisted_mode: :environment do
      next if ENV['PRESERVE_SYMLINKS'].blank?

      puts 'Preserve symlinks option activated, putting PNPM node linker into hoisted mode'
      ENV['PNPM_NODE_LINKER'] = 'hoisted'
    end
  end
end

# Execute new task as a pre-requisite of Rails assets precompile task.
#   This will make sure all PNPM dependencies are installed in hoisted mode, if preserve symlinks option is active.
#   https://github.com/zammad/zammad/issues/5273
Rake::Task['assets:precompile'].enhance(['zammad:package:pnpm_hoisted_mode'])
