module Arel
  module Visitors
    class ToSql
      def visit_CompositePrimaryKeys_Nodes_In o, collector
        collector << "("
        visit(o.left, collector)
        collector << ")"
        collector << " IN ("
        visit(o.right, collector) << ")"
      end

      def visit_CompositePrimaryKeys_CompositeKeys o, collector
        values = o.map do |key|
          case key
            when Arel::Attributes::Attribute
              "#{key.relation.name}.#{key.name}"
            else
              key
          end
        end
        collector << "#{values.join(', ')}"
        collector
      end
    end
  end
end
