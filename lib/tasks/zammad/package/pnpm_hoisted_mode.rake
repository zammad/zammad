# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'yaml'

def pnpm_write_config_atomically(path, content)
  tmp = "#{path}.tmp.#{Process.pid}"
  File.write(tmp, content)
  File.rename(tmp, path)
ensure
  FileUtils.rm_f(tmp)
end

def pnpm_restore_node_linker(path, original_value)
  current = File.exist?(path) ? (YAML.safe_load_file(path) || {}) : {}
  original_value.nil? ? current.delete('nodeLinker') : current['nodeLinker'] = original_value
  current.empty? ? FileUtils.rm_f(path) : pnpm_write_config_atomically(path, current.to_yaml)
rescue => e
  warn "WARNING: Failed to restore pnpm config (#{path}): #{e.message}"
  warn "WARNING: You may need to manually remove or reset 'nodeLinker' in that file."
end

namespace :zammad do

  namespace :package do

    desc 'Put PNPM node linker into hoisted mode if preserve symlinks option is active.'
    task pnpm_hoisted_mode: :environment do
      next if ENV['PRESERVE_SYMLINKS'].blank?

      puts 'Preserve symlinks option activated, putting PNPM node linker into hoisted mode'

      # pnpm v11 no longer reads non-auth settings from pnpm_config_* env vars.
      # nodeLinker must be set via pnpm-workspace.yaml or the global user config.
      config_file = Rails.root.join('pnpm-workspace.yaml').to_s

      config               = File.exist?(config_file) ? (YAML.safe_load_file(config_file) || {}) : {}
      original_node_linker = config['nodeLinker']
      config['nodeLinker'] = 'hoisted'

      pnpm_write_config_atomically(config_file, config.to_yaml)

      at_exit { pnpm_restore_node_linker(config_file, original_node_linker) }
    end
  end
end

# Execute new task as a pre-requisite of Rails assets precompile task.
#   This will make sure all PNPM dependencies are installed in hoisted mode, if preserve symlinks option is active.
#   https://github.com/zammad/zammad/issues/5273
Rake::Task['assets:precompile'].enhance(['zammad:package:pnpm_hoisted_mode'])
