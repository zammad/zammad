require 'rails_helper'

RSpec.describe Issue2019FixDoubleDomainLinksInTriggerEmails, type: :db_migration do
  subject { create(:trigger, perform: { 'notification.email' => { 'body' => faulty_link, 'recipient' => 'customer', 'subject' => 'some subject' } }) }

  let(:faulty_link) do
    '<a href="https://example.com/#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">' \
      'View ticket' \
    '</a>'
  end

  let(:fixed_link) do
    '<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">' \
      'View ticket' \
    '</a>'
  end

  it "removes duplicate domains from Trigger records' notification.email bodies" do
    expect { migrate }.to change { subject.reload.perform['notification.email']['body'] }
      .from(faulty_link).to(fixed_link)
  end
end
