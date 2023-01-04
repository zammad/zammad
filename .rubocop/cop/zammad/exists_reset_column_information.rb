# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ExistsResetColumnInformation < Cop
        def_node_matcher :table?, <<-PATTERN
          $(send _ :change_table ... )
        PATTERN

        def_node_matcher :column?, <<-PATTERN
          $(send _ {:add_column :change_column :rename_column :remove_column} ... )
        PATTERN

        def_node_matcher :reset?, <<-PATTERN
          $( ... :reset_column_information )
        PATTERN

        def message(class_name)
          "Changes of the schema need to be followed by a #{class_name}.reset_column_information to have the right state of the db in the migration and future migrations."
        end

=begin

This rubocop will match all add, change, rename and remove column statements
and check if there are reset_column_information function calls existing for the model.

  good:

    change_column :smime_certificates, :not_after_at, :datetime, limit: 3

    SMIMECertificate.reset_column_information

  bad:

    change_column :smime_certificates, :not_after_at, :datetime, limit: 3

=end

        def column_classes
          @column_classes ||= {}
        end

        def table_classes
          @table_classes ||= {}
        end

        def reset_classes
          @reset_classes ||= {}
        end

        def column_class(node)
          node.children[2].children[0].to_s.classify
        end

        def reset_class(node)
          # simplify namespaced class names
          # Rubocop can't reliably convert table names to namespaced class names
          node.children[0].const_name.gsub '::', ''
        end

        def table_class(node)
          node.children[2].children[0].to_s.classify
        end

        def on_send(node)
          if column?(node)
            column_classes[column_class(node)] = node
          elsif table?(node)
            table_classes[table_class(node)] = node
          elsif reset?(node)
            reset_classes[reset_class(node)] = node
          end
        end

        def on_investigation_end
          column_classes.each do |key, value|
            next if reset_classes.key?(key)

            add_offense(value, message: message(key))
          end
          table_classes.each do |key, value|
            next if reset_classes.key?(key)

            add_offense(value, message: message(key))
          end
          super
        end
      end
    end
  end
end
