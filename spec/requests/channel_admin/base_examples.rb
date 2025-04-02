# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'base channel management' do |factory:, path:|
  describe "GET /api/v1/channels_admin/#{path}" do
    let(:channel) { create(factory) }

    before { channel }

    it 'lists channels' do
      get "/api/v1/channels/admin/#{path}", as: :json

      expect(json_response).to include(
        'channel_ids' => [channel.id],
        'assets'      => be_present
      )
    end
  end

  describe "GET /api/v1/channels_admin/#{path}/ID/enable" do
    let(:channel) { create(factory, active: false) }

    before { channel }

    it 'enables channel' do
      expect { post "/api/v1/channels/admin/#{path}/#{channel.id}/enable", as: :json }
        .to change { channel.reload.active }
        .to true
    end
  end

  describe "GET /api/v1/channels_admin/#{path}/ID/disable" do
    let(:channel) { create(factory, active: true) }

    before { channel }

    it 'disables channel' do
      expect { post "/api/v1/channels/admin/#{path}/#{channel.id}/disable", as: :json }
        .to change { channel.reload.active }
        .to false
    end
  end

  describe "GET /api/v1/channels_admin/#{path}/ID/destroy" do
    let(:channel) { create(factory, active: true) }

    before { channel }

    it 'deletes channel' do
      expect { delete "/api/v1/channels/admin/#{path}/#{channel.id}", as: :json }
        .to change { Channel.exists? channel.id }
        .to false
    end
  end
end
