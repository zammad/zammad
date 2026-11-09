# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::ZammadSchema do

  describe 'complexity of the frontend operations' do

    # The same corpus the frontend code generator ships, see `.graphql_code_generator.js`.
    let(:document_paths) do
      Rails.root
        .glob('app/frontend/{apps,shared}/**/*.graphql')
        .reject { |path| path.to_s.include?('.extensions/') }
        .sort
    end

    let(:documents) { document_paths.index_with { |path| GraphQL.parse_file(path) } }

    # The frontend resolves fragments by name from one global pool, so all definitions form one document.
    let(:document) do
      GraphQL::Language::Nodes::Document.new(definitions: documents.values.flat_map(&:definitions))
    end

    let(:operations) do
      documents.flat_map do |path, parsed_document|
        parsed_document
          .definitions
          .grep(GraphQL::Language::Nodes::OperationDefinition)
          .map { |operation| [operation, path.relative_path_from(Rails.root)] }
      end
    end

    let(:directive_flags) { collect_directive_flags(document, { 'include' => Set.new, 'skip' => Set.new }) }

    let(:complexities) do
      operations.to_h do |operation, path|
        query = GraphQL::Query.new(
          described_class,
          document:       document,
          operation_name: operation.name,
          variables:      variables_for(operation),
        )

        complexity, = GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::QueryComplexity])

        ["#{operation.operation_type} #{operation.name} (#{path})", complexity]
      end
    end

    let(:exceeding_operations) do
      complexities
        .reject { |_operation, complexity| complexity.is_a?(Integer) && complexity.positive? && complexity <= described_class.max_complexity }
        .map { |operation, complexity| "#{operation} scores #{complexity}" }
    end

    def collect_directive_flags(node, flags)
      if node.is_a?(GraphQL::Language::Nodes::Directive) && flags.key?(node.name)
        condition = node.arguments.find { |argument| argument.name == 'if' }&.value
        flags[node.name] << condition.name if condition.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
      end

      node.children.each { |child| collect_directive_flags(child, flags) }

      flags
    end

    # Switch the optional parts of an operation on, so that the worst realistic selection is measured.
    def variables_for(operation)
      operation.variables.each_with_object({}) do |variable, variables|
        variables[variable.name] = false if directive_flags['skip'].include?(variable.name)
        variables[variable.name] = true if directive_flags['include'].include?(variable.name)
      end
    end

    it 'finds operations in the frontend documents' do
      expect(operations).not_to be_empty
    end

    it 'scores every operation below the maximum complexity' do
      expect(exceeding_operations).to be_empty, "Not scored below the maximum complexity of #{described_class.max_complexity}:\n#{exceeding_operations.join("\n")}"
    end
  end
end
