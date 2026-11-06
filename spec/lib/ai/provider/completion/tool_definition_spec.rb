# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Provider::Completion::ToolDefinition do
  let(:input_schema) { { type: 'object', properties: { city: { type: 'string' } }, required: ['city'] } }

  describe '#initialize' do
    it 'keeps every field' do
      definition = described_class.new(name: 'get_weather', description: 'Current weather for a city.', input_schema:)

      expect(definition).to have_attributes(name: 'get_weather', description: 'Current weather for a city.', input_schema:)
    end

    %w[get_weather getWeather get-weather a].each do |name|
      it "accepts the name #{name.inspect}" do
        expect(described_class.new(name:, description: 'Weather.', input_schema:).name).to eq(name)
      end
    end

    it 'accepts a name of 64 characters' do
      expect { described_class.new(name: 'a' * 64, description: 'Weather.', input_schema:) }.not_to raise_error
    end

    [nil, '', 'get weather', 'get.weather', 'wetter_für_stadt', 'a' * 65, :get_weather].each do |name|
      it "rejects the name #{name.inspect}" do
        expect { described_class.new(name:, description: 'Weather.', input_schema:) }
          .to raise_error(ArgumentError, "invalid tool name: #{name.inspect}")
      end
    end

    [nil, '', ' '].each do |description|
      it "rejects the description #{description.inspect}" do
        expect { described_class.new(name: 'get_weather', description:, input_schema:) }
          .to raise_error(ArgumentError, 'tool get_weather requires a description')
      end
    end

    it 'accepts a schema with string keys' do
      expect { described_class.new(name: 'get_weather', description: 'Weather.', input_schema: { 'type' => 'object' }) }
        .not_to raise_error
    end

    [nil, 'object', { type: 'string' }, {}].each do |schema|
      it "rejects the schema #{schema.inspect}" do
        expect { described_class.new(name: 'get_weather', description: 'Weather.', input_schema: schema) }
          .to raise_error(ArgumentError, 'tool get_weather requires an input schema of type object')
      end
    end
  end

  describe '#to_h' do
    it 'returns every field' do
      definition = described_class.new(name: 'get_weather', description: 'Weather.', input_schema:)

      expect(definition.to_h).to eq(name: 'get_weather', description: 'Weather.', input_schema:)
    end
  end
end
