module ActiveRecord
  class Relation
    class WhereClause
      silence_warnings do
        def to_h(table_name = nil)
          equalities = predicates.grep(Arel::Nodes::Equality)

          # CPK Adds this line, because ours are coming in with AND->{EQUALITY, EQUALITY}
          equalities = predicates.grep(Arel::Nodes::And).map(&:children).flatten.grep(Arel::Nodes::Equality) if equalities.empty?

          if table_name
            equalities = equalities.select do |node|
              node.left.relation.name == table_name
            end
          end

          binds = self.binds.map { |attr| [attr.name, attr.value] }.to_h

          equalities.map do |node|
            name = node.left.name
            [name, binds.fetch(name.to_s) {
              case node.right
              when Array then node.right.map(&:val)
              when Arel::Nodes::Casted, Arel::Nodes::Quoted
                node.right.val
              end
            }]
          end.to_h
        end
      end
    end
  end
end
