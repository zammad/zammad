class Sequencer
  class Unit
    module Import
      module Common
        module ObjectAttribute
          class SanitizedName < Sequencer::Unit::Common::Provider::Named

            private

            def sanitized_name
              # model_no
              # model_nos
              # model_name
              # model_name
              without_double_underscores.gsub(/_id(s?)$/, '_no\1')
            end

            def without_double_underscores
              # model_id
              # model_ids
              # model_name
              # model_name
              without_spaces_and_slashes.gsub(/_{2,}/, '_')
            end

            def without_spaces_and_slashes
              # model_id
              # model_ids
              # model___name
              # model_name
              unsanitized_name.gsub(%r{[\s\/]}, '_').underscore
            end

            def unsanitized_name
              # Model ID
              # Model IDs
              # Model / Name
              # Model Name
              raise 'Missing implementation for unsanitized_name method'
            end
          end
        end
      end
    end
  end
end
