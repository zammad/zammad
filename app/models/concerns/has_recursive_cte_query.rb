# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Building block for self-referencing tree lookups (ancestors/descendants/depth), letting callers
# focus on where a tree walk starts instead of repeating the CTE plumbing that walks it.
module HasRecursiveCteQuery
  extend ActiveSupport::Concern

  MAX_DEPTH_LIMIT = 99

  class_methods do
    # Name of the CTE built by #with_recursive_tree_cte. A single fixed name is fine since each
    # call builds its own independent top-level query — no two recursive CTEs from this concern
    # ever coexist in the same query.
    #
    # @return [String] the CTE name
    def recursive_tree_cte_name
      'recursive_tree'
    end

    # Name of the depth counter column produced by #with_recursive_tree_cte, 0 at the seed row(s)
    # and incrementing once per level. Derived from the table name rather than fixed, so it can
    # never collide with an existing instance method on this class (e.g. Group already defines
    # #depth).
    #
    # @return [String] the depth column name
    def recursive_tree_depth_column
      "#{table_name}_#{recursive_tree_cte_name}_depth"
    end
  end

  class_methods do
    # Combines `anchor` and `recursive` into a single CTE, and returns it as a relation of this
    # class that can be chained further (e.g. #where, #reorder).
    #
    # @param name [String, Symbol] name of the CTE
    # @param anchor [ActiveRecord::Relation] the seed rows
    # @param recursive [ActiveRecord::Relation] the branch joining back to `name`, one step per
    #   tree level
    def with_recursive_cte(name, anchor:, recursive:)
      with_recursive(name.to_sym => [anchor, recursive]).from("#{name} AS #{table_name}")
    end

    # Builds a recursive CTE that walks a self-referencing `parent_id` tree one level at a time,
    # starting from `seed`, guarding against cycles via a running array of visited ids. Defaults to
    # ordering by #recursive_tree_depth_column ascending (seed row(s) first), so callers get a safe
    # shallowest-first order for free; chain #reorder to change or drop it (e.g. `.reorder(nil)`
    # before `.distinct`, since PostgreSQL rejects `DISTINCT` combined with an `ORDER BY` expression
    # that isn't in a restricted `SELECT` list, such as after `.pluck`).
    #
    # @param direction [Symbol] :up walks from a row toward its parent (ancestors); :down walks
    #   from a row toward its children (descendants)
    # @param seed [ActiveRecord::Relation, ApplicationModel, nil] the anchor row(s) to start the
    #   walk from, or a single record to seed from directly (equivalent to
    #   `record.class.where(id: record.id)`), or nil for an empty walk (equivalent to `.none`)
    # @param max_depth [Integer] stops the walk from recursing past this depth
    def with_recursive_tree_cte(direction:, seed:, max_depth: MAX_DEPTH_LIMIT)
      cte          = recursive_tree_cte_name
      join_on      = direction == :up ? "#{table_name}.id = #{cte}.parent_id" : "#{table_name}.parent_id = #{cte}.id"
      depth_column = recursive_tree_depth_column

      seed = case seed
             when nil                    then none
             when ActiveRecord::Relation then seed
             else                             seed.class.where(id: seed.id)
             end

      anchor = seed.select("#{table_name}.*, 0 AS #{depth_column}, ARRAY[#{table_name}.id] AS recursive_tree_path")
      recursive = joins("INNER JOIN #{cte} ON #{join_on}")
        .where("NOT #{table_name}.id = ANY(#{cte}.recursive_tree_path)")
        .where("#{cte}.#{depth_column} < ?", max_depth)
        .select("#{table_name}.*, #{cte}.#{depth_column} + 1 AS #{depth_column}, #{cte}.recursive_tree_path || #{table_name}.id")

      with_recursive_cte(cte, anchor:, recursive:).reorder(depth_column)
    end
  end
end
