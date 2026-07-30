# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'fileutils'
require 'yaml'

# Add basic example group slicing functionality to RSpec.
#
# To load it, use: rspec --require ./spec/rspec_extensions.rb
#
# Spec files are distributed over the slices based on their measured runtime from
#   .gitlab/ci/timings/rspec.yml. Files without a measurement are estimated based on
#   their file size, so that new spec files are taken into account as well.
module RSpec
  module Core
    class World
      SLICES = ENV.fetch('CI_NODE_TOTAL', 1).to_i
      CURRENT_SLICE = ENV.fetch('CI_NODE_INDEX', 1).to_i
      TIMINGS_FILE = ENV.fetch('CI_TEST_TIMINGS_FILE', '.gitlab/ci/timings/rspec.yml')

      if !method_defined?(:orig_ordered_example_groups)

        alias orig_ordered_example_groups ordered_example_groups

        # Override ordered_example_groups to only return top-level
        #   example groups of the current slice.
        def ordered_example_groups
          return orig_ordered_example_groups if SLICES == 1

          orig_ordered_example_groups.select { |group| slice_files.include?(normalize_path(group.file_path)) }
        end

        # Spec files assigned to the current slice.
        def slice_files
          @slice_files ||= begin
            totals  = Array.new(SLICES, 0.0)
            buckets = Array.new(SLICES) { Set.new }

            # Longest-processing-time-first: assign the next biggest file to the slice
            #   with the least work assigned so far.
            file_weights.sort_by { |file, weight| [-weight, file] }.each do |file, weight|
              index = (0...SLICES).min_by { |slice| [totals[slice], slice] }

              totals[index] += weight
              buckets[index] << file
            end

            buckets[CURRENT_SLICE - 1]
          end
        end

        # Expected runtime in seconds of each spec file of the current run.
        def file_weights
          spec_files.index_with { |file| timings[file] || estimated_seconds(file) }
        end

        def spec_files
          @spec_files ||= orig_ordered_example_groups.map { |group| normalize_path(group.file_path) }.uniq
        end

        def timings
          @timings ||= File.exist?(TIMINGS_FILE) ? YAML.load_file(TIMINGS_FILE) : {}
        end

        # Estimate the runtime of spec files without a measurement, based on the average
        #   runtime per byte of the measured spec files of the current run.
        def estimated_seconds(file)
          File.size(file) * seconds_per_byte
        end

        def seconds_per_byte
          return @seconds_per_byte if @seconds_per_byte

          measured = spec_files.select { |file| timings.key?(file) }

          @seconds_per_byte = if measured.empty?
                                1.0
                              else
                                measured.sum { |file| timings[file] } / measured.sum { |file| File.size(file) }.to_f
                              end
        end

        def normalize_path(file)
          file.delete_prefix('./')
        end

      end
    end
  end

  # Records the runtime of each spec file, so that .gitlab/ci/timings/rspec.yml can be
  #   refreshed from the artifacts of a CI pipeline.
  class FileTimingsFormatter
    Core::Formatters.register self, :example_finished, :stop

    def initialize(_output)
      @timings = Hash.new(0.0)
    end

    def example_finished(notification)
      example = notification.example

      # Attribute examples to the file of their top level example group, so that the
      #   runtime of shared examples counts towards the file which includes them — only
      #   top level files can be distributed over the slices.
      file = example.example_group.parent_groups.last.metadata[:file_path].delete_prefix('./')

      @timings[file] += example.execution_result.run_time.to_f
    end

    def stop(_notification)
      path = ENV.fetch('CI_TEST_TIMINGS_PATH')

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, @timings.transform_values { |seconds| seconds.round(1) }.to_yaml)
    end
  end
end

if !ENV['CI_TEST_TIMINGS_PATH'].to_s.empty?
  RSpec.configure { |config| config.add_formatter(RSpec::FileTimingsFormatter) }
end
