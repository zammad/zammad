module ActiveRecord
  module Associations
    class JoinDependency
      class Aliases # :nodoc:
        silence_warnings do
          def column_alias(node, column)
            # CPK
            #@alias_cache[node][column]
            if column.kind_of?(Array)
              column.map do |a_column|
                @alias_cache[node][a_column]
              end
            else
              @alias_cache[node][column]
            end
          end
        end
      end

      silence_warnings do
        def instantiate(result_set, &block)
          primary_key = aliases.column_alias(join_root, join_root.primary_key)

          seen = Hash.new { |i, object_id|
            i[object_id] = Hash.new { |j, child_class|
              j[child_class] = {}
            }
          }

          model_cache = Hash.new { |h,klass| h[klass] = {} }
          parents = model_cache[join_root]
          column_aliases = aliases.column_aliases join_root

          message_bus = ActiveSupport::Notifications.instrumenter

          payload = {
            record_count: result_set.length,
            class_name: join_root.base_klass.name
          }

          message_bus.instrument('instantiation.active_record', payload) do
            result_set.each { |row_hash|
              # CPK
              parent_key = if primary_key.kind_of?(Array)
                             primary_key.map {|key| row_hash[key]}
                           else
                             primary_key ? row_hash[primary_key] : row_hash
                           end

              parent = parents[parent_key] ||= join_root.instantiate(row_hash, column_aliases, &block)
              construct(parent, join_root, row_hash, result_set, seen, model_cache, aliases)
            }
          end

          parents.values
        end

        def construct(ar_parent, parent, row, rs, seen, model_cache, aliases)
          return if ar_parent.nil?

          parent.children.each do |node|
            if node.reflection.collection?
              other = ar_parent.association(node.reflection.name)
              other.loaded!
            elsif ar_parent.association_cached?(node.reflection.name)
              model = ar_parent.association(node.reflection.name).target
              construct(model, node, row, rs, seen, model_cache, aliases)
              next
            end

            key = aliases.column_alias(node, node.primary_key)

            # CPK
            if key.is_a?(Array)
              id = Array(key).map do |column_alias|
                row[column_alias]
              end
              # At least the first value in the key has to be set.  Should we require all values to be set?
              id = nil if id.first.nil?
            else # original
              id = row[key]
            end

            if id.nil? # duplicating this so it is clear what remained unchanged from the original
              nil_association = ar_parent.association(node.reflection.name)
              nil_association.loaded!
              next
            end

            model = seen[ar_parent.object_id][node.base_klass][id]

            if model
              construct(model, node, row, rs, seen, model_cache, aliases)
            else
              model = construct_model(ar_parent, node, row, model_cache, id, aliases)
              seen[ar_parent.object_id][node.base_klass][id] = model
              construct(model, node, row, rs, seen, model_cache, aliases)
            end
          end
        end
      end
    end
  end
end
