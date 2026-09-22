# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Covers a screen embedding App.HttpLog: the entry is listed, and its detail modal renders the
# request and response as lines. The backends record headers and body as one multi-line string, so
# the fixture does the same - every newline in it has to end up as a line break, never as a
# literal '\n' escape in the visible text. Facilities that store a structure instead of the raw
# payload (hash_content: true) get a second example for that shape.
RSpec.shared_examples 'HTTP log' do |facility:, path:, hash_content: false|
  let(:request_content) do
    <<~CONTENT.chomp
      Content-Type: application/json
      User-Agent: Zammad User Agent

      {"foo":"bar"}
    CONTENT
  end

  let(:response_content) do
    <<~CONTENT.chomp
      Content-Type: application/json

      {"result":"ok"}
    CONTENT
  end

  let(:log_request)  { { content: request_content } }
  let(:log_response) { { content: response_content, code: 200 } }

  let(:http_log) do
    create(:http_log,
           facility: facility,
           url:      'https://example.com/http-log-request',
           request:  log_request,
           response: log_response)
  end

  # Capybara collapses real line breaks into spaces, so the visible text alone cannot tell a
  # rendered line break from none. innerText keeps them, for <br> and block elements alike.
  def rendered_lines(row)
    find(:xpath, "//tr[td[normalize-space(text())='#{row}']]/td[2]//code").evaluate_script('this.innerText').lines.map(&:strip)
  end

  before do
    http_log

    if defined?(open_http_log)
      open_http_log
    else
      visit path
    end
  end

  it 'lists the entry and renders its content without escaped newlines' do
    within :active_content do
      find("tr.js-record[data-id='#{http_log.id}']").click
    end

    in_modal do
      expect(page).to have_text('HTTP Log')
        .and have_text('https://example.com/http-log-request')
        .and have_text('Content-Type: application/json')
        .and have_no_text('\\n')

      expect(rendered_lines('Request')).to include('Content-Type: application/json', 'User-Agent: Zammad User Agent')
      expect(rendered_lines('Response')).to include('Content-Type: application/json')
    end
  end

  if hash_content
    context 'with a structure as content' do
      let(:log_request) do
        {
          content: {
            'action'     => 'created',
            'attributes' => { 'login' => 'jdoe', 'email' => 'jdoe@example.com' },
          },
        }
      end
      let(:log_response) { { content: {} } }

      it 'renders the structure line by line' do
        within :active_content do
          find("tr.js-record[data-id='#{http_log.id}']").click
        end

        in_modal do
          expect(page).to have_text('HTTP Log')
            .and have_text('"action": "created"')
            .and have_no_text('\\n')

          expect(rendered_lines('Request')).to include('"login": "jdoe",', '"email": "jdoe@example.com"')
          expect(rendered_lines('Response')).to eq(['{}'])
        end
      end
    end
  end
end
