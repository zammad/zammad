# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    class UntranslatedRelationSort < BaseSort
      def self.applicable?(input, locale, object)
        return false if locale.blank?

        attr = ObjectManager::Attribute.get(object: object.name, name: column_name(input, object))
        return false if attr.nil?

        attr.data_option[:relation].present? && !attr.data_option[:translate]
      end

      def calculate_sorting
        case assoc.class_name
        when 'User'
          calculate_user_sorting
        else
          {
            order: "#{assoc.klass.quoted_table_name}.#{quote_column('name')} #{collate} #{input[:direction]}",
            joins: assoc.name,
            group: "#{assoc.klass.quoted_table_name}.#{quote_column('name')}",
          }
        end
      end

      private

      def calculate_user_sorting
        table_name  = "_advanced_sorting_table_#{object.table_name}_#{assoc.foreign_key}"
        column_name = "_advanced_sorting_#{object.table_name}_#{assoc.foreign_key}"
        join        = "INNER JOIN #{quote_table('users')} #{quote_table(table_name)} ON #{quote_table_column(table_name, 'id')} = #{quote_table_column(object.table_name, assoc.foreign_key)}"
        select      = calculate_sorting_select(table_name, column_name)

        {
          order:  "#{quote_column(column_name)} #{input[:direction]}",
          select: select,
          joins:  join,
          group:  "#{quote_table_column(table_name, 'firstname')}, #{quote_table_column(table_name, 'lastname')}, #{quote_table_column(table_name, 'email')}, #{quote_table_column(table_name, 'phone')}, #{quote_table_column(table_name, 'mobile')}, #{quote_table_column(table_name, 'login')}",
        }
      end

      def calculate_sorting_select(table_name, column_name)
        <<~SQL.squish
          case
          when character_length(#{quote_table_column(table_name, 'firstname')}) > 0 OR character_length(#{quote_table_column(table_name, 'lastname')}) > 0
            THEN trim(concat(#{quote_table_column(table_name, 'firstname')}, ' ', #{quote_table_column(table_name, 'lastname')}))
          when character_length(#{quote_table_column(table_name, 'email')}) > 0 THEN #{quote_table_column(table_name, 'email')}
          when character_length(#{quote_table_column(table_name, 'phone')}) > 0 THEN #{quote_table_column(table_name, 'phone')}
          when character_length(#{quote_table_column(table_name, 'mobile')}) > 0 THEN #{quote_table_column(table_name, 'mobile')}
          when character_length(#{quote_table_column(table_name, 'login')}) > 0 THEN #{quote_table_column(table_name, 'login')}
          else '-'
          end
          #{collate}
          as #{quote_column(column_name)}
        SQL
      end

      def assoc
        @assoc ||= object.reflect_on_association(column.delete_suffix('_id'))
      end

      def quote_column(name)
        assoc.klass.connection.quote_column_name(name)
      end

      def quote_table(name)
        assoc.klass.connection.quote_table_name(name)
      end

      def quote_table_column(table, column)
        "#{assoc.klass.connection.quote_table_name(table)}.#{quote_column(column)}"
      end
    end
  end
end
