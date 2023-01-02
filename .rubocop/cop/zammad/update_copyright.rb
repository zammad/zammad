# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      # This cop updates the copyright information or inserts it if needed.
      class UpdateCopyright < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Copyright update required (use auto-correct to rectify this).'.freeze
        COPYRIGHT = "# Copyright (C) 2012-#{Date.today.year} Zammad Foundation, https://zammad-foundation.org/".freeze # rubocop:disable Rails/Date

        def on_new_investigation
          if processed_source.raw_source.include? '# Copyright (C) 2012-'
            update_copyright
          else
            insert_copyright
          end
        end

        def insert_copyright
          if processed_source.raw_source.start_with? '#!'
            # Keep shebang line, obviously.
            comment = processed_source.comments.first
            add_offense(comment) do |corrector|
              corrector.insert_after(
                comment,
                "\n#{COPYRIGHT}\n"
              )
            end
          else
            # Insert at the top if there is no shebang.
            file_start = range_between(0, 0)
            add_offense(file_start) do |corrector|
              corrector.insert_before(file_start, "#{COPYRIGHT}\n\n")
            end
          end
        end

        def update_copyright
          processed_source.comments.each do |comment|
            break if correct_copyright?(comment)
            next if !comment.text.include?('# Copyright (C) 2012-') # rubocop:disable Rails/NegateInclude

            add_offense(comment) do |corrector|
              corrector.replace(
                comment,
                replace_with(comment)
              )
            end

            break
          end
        end

        def correct_copyright?(comment)
          return false if !comment.text.eql? COPYRIGHT

          newline_after_copyright?(comment)
        end

        def newline_after_copyright?(comment)
          processed_source[comment.location.last_line].blank?
        end

        def replace_with(comment)
          return COPYRIGHT if newline_after_copyright?(comment)

          "#{COPYRIGHT}\n"
        end
      end
    end
  end
end
