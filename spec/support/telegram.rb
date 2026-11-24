# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_context 'with Telegram bot info' do
  def stub_telegram_get_me(token, id:, username:, first_name:)
    result = {
      id:         id,
      is_bot:     true,
      first_name: first_name,
      username:   username,
    }

    stub_request(:post, "https://api.telegram.org/bot#{token}/getMe")
      .to_return_json(body: { ok: true, result: result })
  end
end
