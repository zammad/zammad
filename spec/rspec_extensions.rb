# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Add basic example group slicing functionality to RSpec.
#
# To load it, use: rspec --require ./spec/rspec_extensions.rb
#
# This uses the file size as a rough measurement of its expected runtime,
#   which is certainly not perfect, but a sufficient estimate.
module RSpec
  module Core
    class World
      SLICES = ENV.fetch('RSPEC_SLICES', 1).to_i
      CURRENT_SLICE = ENV.fetch('RSPEC_CURRENT_SLICE', 1).to_i

      if !method_defined?(:orig_ordered_example_groups)

        alias orig_ordered_example_groups ordered_example_groups

        # Override ordered_example_groups to only return top-level
        #   example groups of the current slice, based on the size of
        #   their containing file.
        def ordered_example_groups
          return orig_ordered_example_groups if SLICES == 1

          start_size = 0

          slice_size = total_size / SLICES
          current_slice_start_size = slice_size * (CURRENT_SLICE - 1)
          current_slice_end_size = current_slice_start_size + slice_size

          orig_ordered_example_groups.select do |group|
            (start_size >= current_slice_start_size && start_size < current_slice_end_size).tap do
              start_size += File.size(group.file_path)
            end
          end
        end

        # Get the total file size of all (unfiltered) example groups.
        def total_size
          example_groups.inject(0) do |sum, group|
            sum + File.size(group.file_path)
          end
        end

      end
    end
  end
end
