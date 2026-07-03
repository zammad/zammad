# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::KbSelfHostedVideoServers do
  let(:setting_name) { 'kb_self_hosted_video_servers' }

  context 'when given value is nil' do
    it 'does raise an error' do
      expect { Setting.set(setting_name, nil) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when given value is an empty array' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, []) }.not_to raise_error
    end
  end

  context 'when given value is an array of valid hostnames' do
    it 'does not raise an error' do
      servers = [
        { 'name' => 'a', 'host' => 'example.com' },
        { 'name' => 'b', 'host' => 'videos.example.com:8080' }
      ]

      expect { Setting.set(setting_name, servers) }.not_to raise_error
    end
  end

  context 'when given value is an array with an invalid hostname' do
    it 'does raise an error' do
      servers = [
        { 'name' => 'a', 'host' => 'example.com' },
        { 'name' => 'b', 'host' => 'invalid host name' }
      ]

      expect { Setting.set(setting_name, servers) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when given full url with path or query' do
    it 'does raise an error' do
      servers = [
        { 'name' => 'a', 'host' => 'example.com/path?query=value' },
        { 'name' => 'b', 'host' => 'videos.example.com:8080' }
      ]

      expect { Setting.set(setting_name, servers) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
