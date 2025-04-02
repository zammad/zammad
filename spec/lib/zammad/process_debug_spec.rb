# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::ProcessDebug, :aggregate_failures do
  describe '.dump_thread_status' do
    it 'prints the thread info and stack trace' do
      output = ''
      allow(described_class).to receive(:puts) do |message|
        output += [message].flatten.join("\n")
      end
      described_class.dump_thread_status
      expect(output).to include("PID: #{Process.pid} Thread:")
      expect(output).to include('block in dump_thread_status')
    end
  end
end
