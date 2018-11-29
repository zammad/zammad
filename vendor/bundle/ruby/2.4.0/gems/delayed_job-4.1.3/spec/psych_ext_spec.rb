require 'helper'

describe 'Psych::Visitors::ToRuby', :if => defined?(Psych::Visitors::ToRuby) do
  context BigDecimal do
    it 'deserializes correctly' do
      deserialized = YAML.load("--- !ruby/object:BigDecimal 18:0.1337E2\n...\n")

      expect(deserialized).to be_an_instance_of(BigDecimal)
      expect(deserialized).to eq(BigDecimal('13.37'))
    end
  end
end
