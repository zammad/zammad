# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HttpLog do
  let(:subject) { build(:http_log) }

  describe 'callbacks' do
    # See https://github.com/zammad/zammad/issues/2100
    it 'converts request/response message data to UTF-8 before saving' do
      subject.request[:content]  = 'foo'.force_encoding('ascii-8bit')
      subject.response[:content] = 'bar'.force_encoding('ascii-8bit')

      expect { subject.save }
        .to change { subject.request[:content].encoding.name }.from('ASCII-8BIT').to('UTF-8')
        .and change { subject.response[:content].encoding.name }.from('ASCII-8BIT').to('UTF-8')
    end
  end
end
