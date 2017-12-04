require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Model::Attributes::RemoteId, sequencer: :unit do

  it 'takes remote_id from id' do
    parameters = {
      resource: {
        id: '123abc',
      }
    }

    provided = process(parameters)

    expect(provided).to include(remote_id: '123abc')
  end

  it 'takes remote_id from attribute method result' do
    parameters = {
      resource: {
        other_attribute: '123abc',
      }
    }

    provided = process(parameters) do |instance|
      expect(instance).to receive(:attribute).and_return(:other_attribute)
    end

    expect(provided).to include(remote_id: '123abc')
  end

  it 'converts value to a String' do
    parameters = {
      resource: {
        id: 1337,
      }
    }

    provided = process(parameters)

    expect(provided).to include(remote_id: '1337')
  end

  it 'downcases the value to prevent case sensivity issues with the ORM' do
    parameters = {
      resource: {
        id: 'AbCdEfG',
      }
    }

    provided = process(parameters)

    expect(provided[:remote_id]).to eq(parameters[:resource][:id].downcase)
  end

  it 'duplicates the value to prevent attribute changes' do
    parameters = {
      resource: {
        id: 'this is',
      }
    }

    provided = process(parameters)

    expect(provided[:remote_id]).to eq(parameters[:resource][:id])

    parameters[:resource][:id] += ' a test'

    expect(provided[:remote_id]).not_to eq(parameters[:resource][:id])
  end
end
