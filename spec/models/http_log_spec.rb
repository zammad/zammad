# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HttpLog do
  subject(:http_log) { build(:http_log) }

  describe 'callbacks' do
    # See https://github.com/zammad/zammad/issues/2100
    it 'converts request/response message data to UTF-8 before saving' do
      http_log.request[:content]  = 'foo'.force_encoding('ascii-8bit')
      http_log.response[:content] = 'bar'.force_encoding('ascii-8bit')

      expect { http_log.save }
        .to change { http_log.request[:content].encoding.name }.from('ASCII-8BIT').to('UTF-8')
        .and change { http_log.response[:content].encoding.name }.from('ASCII-8BIT').to('UTF-8')
    end
  end
end
