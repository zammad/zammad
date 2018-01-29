require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::ObjectAttribute::SanitizedName, sequencer: :unit do

  it 'requires implementation of .unsanitized_name' do

    expect do
      process
    end.to raise_error(RuntimeError)
  end

  context 'sanitizes' do

    it 'whitespaces' do
      provided = process do |instance|
        expect(instance).to receive(:unsanitized_name).and_return('model name')
      end

      expect(provided[:sanitized_name]).to eq('model_name')
    end

    it 'dashes' do
      provided = process do |instance|
        expect(instance).to receive(:unsanitized_name).and_return('model-name')
      end

      expect(provided[:sanitized_name]).to eq('model_name')
    end

    it 'ids suffix' do
      provided = process do |instance|
        expect(instance).to receive(:unsanitized_name).and_return('Model Ids')
      end

      expect(provided[:sanitized_name]).to eq('model_nos')
    end

    it 'id suffix' do
      provided = process do |instance|
        expect(instance).to receive(:unsanitized_name).and_return('Model Id')
      end

      expect(provided[:sanitized_name]).to eq('model_no')
    end
  end
end
