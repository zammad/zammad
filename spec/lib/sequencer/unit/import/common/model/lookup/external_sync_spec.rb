require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Model::Lookup::ExternalSync, sequencer: :unit do

  it 'finds model_class instance by remote_id' do
    user                 = create(:user)
    external_sync_source = 'test'
    remote_id            = '1337'

    ExternalSync.create(
      source:    external_sync_source,
      source_id: ExternalSync.sanitized_source_id(remote_id),
      o_id:      user.id,
      object:    user.class,
    )

    provided = process(
      remote_id:            remote_id,
      model_class:          user.class,
      external_sync_source: external_sync_source,
    )

    expect(provided[:instance]).to eq(user)
  end

  context 'obsolete plain remote_id' do

    let(:user) { create(:user) }
    let(:external_sync_source) { 'test' }
    let(:remote_id) { 'AbCdEfG' }

    it 'finds model_class instance' do
      ExternalSync.create(
        source:    external_sync_source,
        source_id: remote_id,
        o_id:      user.id,
        object:    user.class,
      )

      provided = process(
        remote_id:            remote_id,
        model_class:          user.class,
        external_sync_source: external_sync_source,
      )

      expect(provided[:instance]).to eq(user)
    end

    it 'corrects external sync entry' do
      entry = ExternalSync.create(
        source:    external_sync_source,
        source_id: remote_id,
        o_id:      user.id,
        object:    user.class,
      )

      process(
        remote_id:            remote_id,
        model_class:          user.class,
        external_sync_source: external_sync_source,
      )

      entry.reload

      expect(entry.source_id).to eq(ExternalSync.sanitized_source_id(remote_id))
    end

    it 'operates case agnostic' do
      entry = ExternalSync.create(
        source:    external_sync_source,
        source_id: remote_id.downcase,
        o_id:      user.id,
        object:    user.class,
      )

      provided = process(
        remote_id:            remote_id,
        model_class:          user.class,
        external_sync_source: external_sync_source,
      )

      expect(provided[:instance]).to eq(user)

      entry.reload

      expect(entry.source_id).to eq(ExternalSync.sanitized_source_id(remote_id))
    end
  end
end
