require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::ObjectAttribute::SanitizedName, sequencer: :unit do

  it 'requires implementation of .unsanitized_name' do

    expect do
      process
    end.to raise_error(RuntimeError)
  end

  context 'sanitizes' do

    it 'replaces whitespaces' do
      provided = process do |instance|
        expect(instance).to receive(:unsanitized_name).and_return('model name')
      end

      expect(provided[:sanitized_name]).to eq('model_name')
    end

    it 'replaces dashes' do
      provided = process do |instance|
        expect(instance).to receive(:unsanitized_name).and_return('model-name')
      end

      expect(provided[:sanitized_name]).to eq('model_name')
    end

    it 'replaces ids suffix' do
      provided = process do |instance|
        expect(instance).to receive(:unsanitized_name).and_return('Model Ids')
      end

      expect(provided[:sanitized_name]).to eq('model_nos')
    end

    it 'replaces id suffix' do
      provided = process do |instance|
        expect(instance).to receive(:unsanitized_name).and_return('Model Id')
      end

      expect(provided[:sanitized_name]).to eq('model_no')
    end

    it 'replaces non-ASCII characters' do
      provided = process do |instance|
        expect(instance).to receive(:unsanitized_name).and_return('Ærøskøbing Ät Mödél')
      end

      expect(provided[:sanitized_name]).to eq('a_eroskobing_at_model')
    end
  end
end
