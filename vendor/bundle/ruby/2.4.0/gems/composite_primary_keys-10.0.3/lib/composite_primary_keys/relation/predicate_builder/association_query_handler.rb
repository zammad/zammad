module ActiveRecord
  class PredicateBuilder
    class AssociationQueryHandler
      def call(attribute, value)
        queries = {}

        table = value.associated_table
        if value.base_class
          queries[table.association_foreign_type.to_s] = value.base_class.name
        end

        # CPK
        # queries[table.association_foreign_key.to_s] = value.ids
        # predicate_builder.build_from_hash(queries)
        if table.association_foreign_key.is_a?(Array)
          values = case value.value
                    when Relation
                      value.ids.map {|record| record.ids}
                    when Array
                      value.ids
                    else
                      [value.ids]
                    end

          CompositePrimaryKeys::Predicates.cpk_in_predicate(attribute.relation, table.association_foreign_key, values)
        else
          queries[table.association_foreign_key.to_s] = value.ids
          predicate_builder.build_from_hash(queries)
        end
      end
    end
  end
end
