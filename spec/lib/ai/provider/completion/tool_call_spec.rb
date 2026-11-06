# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Provider::Completion::ToolCall do
  def tool_call(arguments)
    described_class.new(id: 'call_1', name: 'get_weather', arguments:)
  end

  describe '#initialize' do
    it 'keeps an object as the arguments', :aggregate_failures do
      call = tool_call({ 'city' => 'Vienna' })

      expect(call).to have_attributes(id: 'call_1', name: 'get_weather', arguments: { 'city' => 'Vienna' }, raw_arguments: nil)
      expect(call).not_to be_invalid
    end

    it 'reads the arguments from the JSON text the model wrote' do
      expect(tool_call('{"city": "Vienna"}').arguments).to eq('city' => 'Vienna')
    end

    [nil, '', ' '].each do |arguments|
      it "takes #{arguments.inspect} for no arguments" do
        expect(tool_call(arguments)).to have_attributes(arguments: {}, invalid?: false)
      end
    end

    {
      'broken JSON'         => '{"city": "Vie',
      'JSON that is a list' => '["Vienna"]',
      'JSON that is a text' => '"Vienna"',
    }.each do |label, arguments|
      it "marks #{label} as invalid and keeps it as sent" do
        expect(tool_call(arguments)).to have_attributes(invalid?: true, arguments: nil, raw_arguments: arguments)
      end
    end

    it 'marks arguments that are neither an object nor a text as invalid' do
      expect(tool_call(['Vienna'])).to have_attributes(invalid?: true, raw_arguments: '["Vienna"]')
    end

    [nil, ''].each do |id|
      it "rejects the id #{id.inspect}" do
        expect { described_class.new(id:, name: 'get_weather', arguments: {}) }
          .to raise_error(ArgumentError, 'tool call requires an id')
      end
    end
  end

  describe '#to_h' do
    it 'returns the id, the name and the arguments' do
      expect(tool_call({ 'city' => 'Vienna' }).to_h).to eq(id: 'call_1', name: 'get_weather', arguments: { 'city' => 'Vienna' })
    end

    it 'returns the arguments as sent for an invalid call' do
      expect(tool_call('{"city": "Vie').to_h).to eq(id: 'call_1', name: 'get_weather', raw_arguments: '{"city": "Vie')
    end
  end
end
