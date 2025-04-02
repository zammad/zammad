# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Git Integration Base' do |issue_type:|
  describe '#fix_urls_for_ticket' do
    let(:bad_issue_url)    { 'https://git.example.com/owner/repo/issues/1' }
    let(:url_replacements) { { bad_issue_url => 'https://git.example.com/owner/repo/issues/2' } }

    it 'does update the ticket if an issue link has to be replaced' do # rubocop:disable RSpec/MultipleExpectations
      ticket = create(:ticket, group: Group.first, preferences: {
                        issue_type => {
                          issue_links: [bad_issue_url]
                        }
                      })
      expect(ticket.reload.preferences[issue_type][:issue_links]).to eq([bad_issue_url])

      instance.fix_urls_for_ticket(ticket, url_replacements)
      expect(ticket.reload.preferences[issue_type][:issue_links]).to eq([url_replacements[bad_issue_url]])
    end
  end
end
