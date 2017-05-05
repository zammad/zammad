require 'rails_helper'

RSpec.describe Channel::Filter::FollowUpMerged do

  describe '#find_merge_follow_up_ticket' do

    it 'finds the follow up ticket for merged tickets' do
      ticket1 = create(:ticket)
      ticket2 = create(:ticket)
      ticket3 = create(:ticket)
      ticket4 = create(:ticket)
      ticket5 = create(:ticket)

      ticket1.merge_to( ticket_id: ticket2.id, user_id: 1 )
      ticket2.merge_to( ticket_id: ticket3.id, user_id: 1 )
      ticket3.merge_to( ticket_id: ticket4.id, user_id: 1 )
      ticket4.merge_to( ticket_id: ticket5.id, user_id: 1 )

      ticket = Channel::Filter::FollowUpMerged.find_merge_follow_up_ticket(ticket1)
      expect(ticket.id).to eq(ticket5.id)

      follow_up_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket1.subject_build('some new subject')}

blub follow up"
      ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, follow_up_raw)
      expect(ticket_p.id).to eq(ticket5.id)

      follow_up_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket2.subject_build('some new subject')}

blub follow up"
      ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, follow_up_raw)
      expect(ticket_p.id).to eq(ticket5.id)

      follow_up_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket3.subject_build('some new subject')}

blub follow up"
      ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, follow_up_raw)
      expect(ticket_p.id).to eq(ticket5.id)

      follow_up_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket4.subject_build('some new subject')}

blub follow up"
      ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, follow_up_raw)
      expect(ticket_p.id).to eq(ticket5.id)

      follow_up_raw = "From: me@example.com
To: customer@example.com
Subject: #{ticket5.subject_build('some new subject')}

blub follow up"
      ticket_p, article_p, user_p = Channel::EmailParser.new.process({}, follow_up_raw)
      expect(ticket_p.id).to eq(ticket5.id)
    end

  end

end
