# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class ExistsDateTimePrecision < Cop
        def_node_matcher :column?, <<-PATTERN
          $(send _ {:add_column :change_column} (sym _) (sym _) (sym :datetime) ... )
        PATTERN

        def_node_matcher :column_limit?, <<-PATTERN
          (send ... (hash <(pair (sym :limit) $(int 3)) ...> ) )
        PATTERN

        def_node_matcher :table?, <<-PATTERN
          $(block
            (send _ {:create_table :alter_table} ... )
            ...
          )
        PATTERN

        def_node_matcher :table_column?, <<-PATTERN
          $(send (:lvar _) {:timestamps :datetime} ... )
        PATTERN

        MSG = 'Columns of type :timestamps and :datetime needs to have limit: 3.'.freeze

=begin

This rubocop will match all change_column/add_column/create_table/alter_table statements
and check if there are :datetime or :timestamps column which do not have the limit: 3 setting.

  good:

    change_column :smime_certificates, :not_after_at, :datetime, limit: 3

    create_table :sessions do |t|
      t.timestamps limit: 3, null: false
    end

  bad:

    change_column :smime_certificates, :not_after_at, :datetime, limit: 4

    create_table :sessions do |t|
      t.timestamps null: false
    end

=end

        def on_send(node)
          return add_offense(node) if invalid_column?(node)
          return add_offense(node) if invalid_table?(node)
        end

        def invalid_table?(node)
          table?(node&.parent&.parent) && table_column?(node) && !column_limit?(node)
        end

        def invalid_column?(node)
          column?(node) && !column_limit?(node)
        end

      end
    end
  end
end
