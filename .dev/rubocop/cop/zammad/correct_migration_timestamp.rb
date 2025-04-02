# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      # This cop checks if migration file name begins with a valid timestamp
      # https://github.com/zammad/zammad/issues/3702
      class CorrectMigrationTimestamp < Base
        MSG = 'Migration filename must begin with a valid timestamp'.freeze

        def on_new_investigation
          file_path = processed_source.file_path

          return if !migration?(file_path)
          return if config.file_to_exclude?(file_path) || config.allowed_camel_case_file?(file_path)
          return if filename_good?(file_path)

          add_global_offense(MSG)
        end

        private

        def migration?(file_path)
          match_path? %r{(?<!spec/)db/(migrate|addon/[^/]+)/.+\.rb}, file_path
        end

        def filename_good?(file_path)
          filename = File.basename(file_path)

          # the check makes trouble in old addons which do not match the rubocop.
          # since we can't disable the rubocop for whatever reason is was the only solution.
          return true if filename[0..3].to_i < 2021

          filename.match? %r{^20\d{12}_}
        end
      end
    end
  end
end
