module ActiveRecord
  module Associations
    class JoinDependency
      class JoinAssociation
        silence_warnings do
          def build_constraint(klass, table, key, foreign_table, foreign_key)
            # CPK
            # constraint = table[key].eq(foreign_table[foreign_key])
            constraint = cpk_join_predicate(table, key, foreign_table, foreign_key)

            if klass.finder_needs_type_condition?
              constraint = table.create_and([
                constraint,
                klass.send(:type_condition, table)
              ])
            end

            constraint
          end
        end
      end
    end
  end
end
