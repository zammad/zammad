# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rubocop/rspec/support'

# https://github.com/rubocop/rubocop/tree/91e72f8bb4a5a646845e7915052f912d60a3d280/lib/rubocop/rspec/shared_contexts.rb:52
RSpec.shared_context 'when checking custom RuboCop cops' do

  include RuboCop::RSpec::ExpectOffense

  let(:cop_options) { {} }
  let(:cop_config)  { {} }

  let(:cur_cop_config) do
    RuboCop::ConfigLoader
      .default_configuration.for_cop(described_class)
      .merge({
               'Enabled'     => true, # in case it is 'pending'
               'AutoCorrect' => true # in case defaults set it to false
             })
      .merge(cop_config)
  end

  let(:config) { RuboCop::Config.new({ described_class.cop_name => cur_cop_config }, "#{Rails.configuration.root}/.rubocop.yml") }
  let(:cop) { described_class.new(config, cop_options) }
end

RSpec.configure do |config|
  config.include_context 'when checking custom RuboCop cops', type: :rubocop
end
