# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::EmailParser, type: :model do
  describe '#parse' do
    # regression test for issue 2390 - Add a postmaster filter to not show emails with potential issue
    describe 'handling HTML links in message content' do
      context 'with under 5,000 links' do
        it 'parses message content as normal' do
          expect(described_class.new.parse(<<~RAW)[:body]).to start_with('<a href="https://zammad.com/"')
            From: nicole.braun@zammad.com
            Content-Type: text/html

            <html><body>
            #{Array.new(10) { '<a href="https://zammad.com/">Dummy Link</a>' }.join(' ')}
            </body></html>
          RAW
        end
      end

      context 'with 5,000+ links' do
        it 'replaces message content with error message' do
          expect(described_class.new.parse(<<~RAW)).to include('body' => Channel::EmailParser::EXCESSIVE_LINKS_MSG)
            From: nicole.braun@zammad.com
            Content-Type: text/html

            <html><body>
            #{Array.new(5001) { '<a href="https://zammad.com/">Dummy Link</a>' }.join(' ')}
            </body></html>
          RAW
        end
      end
    end

    describe 'handling Japanese email in ISO-2022-JP encoding' do
      let(:mail_file) { Rails.root.join('test/data/mail/mail091.box') }
      let(:raw_mail)  { File.read(mail_file) }
      let(:parsed)    { described_class.new.parse(raw_mail) }

      it { expect(parsed['body']).to eq '<div>このアドレスへのメルマガを解除してください。</div>' }
      it { expect(parsed['subject']).to eq 'メルマガ解除' }
    end
  end

  describe '#process' do
    let(:raw_mail) { File.read(mail_file) }

    before { Trigger.destroy_all } # triggers may cause additional articles to be created

    describe 'auto-creating new users' do
      context 'with one unrecognized email address' do
        it 'creates one new user' do
          expect { described_class.new.process({}, <<~RAW) }.to change(User, :count).by(1)
            From: #{Faker::Internet.unique.email}
          RAW
        end
      end

      context 'with a large number of unrecognized recipient addresses' do
        it 'never creates more than 40 users' do
          expect { described_class.new.process({}, <<~RAW) }.to change(User, :count).by(40)
            From: nicole.braun@zammad.org
            To: #{Array.new(20) { Faker::Internet.unique.email }.join(', ')}
            Cc: #{Array.new(21) { Faker::Internet.unique.email }.join(', ')}
          RAW
        end
      end
    end

    describe 'auto-updating existing users' do
      context 'with a previous email with no real name in the From: header' do
        let!(:customer) { described_class.new.process({}, previous_email).first.customer }

        let(:previous_email) { <<~RAW.chomp }
          From: customer@example.com
          To: myzammad@example.com
          Subject: test sender name update 1

          Some Text
        RAW

        context 'and a new email with a real name in the From: header' do
          let(:new_email) { <<~RAW.chomp }
            From: Max Smith <customer@example.com>
            To: myzammad@example.com
            Subject: test sender name update 2

            Some Text
          RAW

          it 'updates the customer’s #firstname and #lastname' do
            expect { described_class.new.process({}, new_email) }
              .to change { customer.reload.firstname }.from('').to('Max')
              .and change { customer.reload.lastname }.from('').to('Smith')
          end
        end
      end
    end

    describe 'creating new tickets' do
      context 'when subject contains no ticket reference' do
        let(:raw_mail) { <<~RAW.chomp }
          From: foo@bar.com
          To: baz@qux.net
          Subject: Foo

          Lorem ipsum dolor
        RAW

        it 'creates a ticket and article' do
          expect { described_class.new.process({}, raw_mail) }
            .to change(Ticket, :count).by(1)
            .and change(Ticket::Article, :count).by_at_least(1)
        end

        it 'sets #title to email subject' do
          described_class.new.process({}, raw_mail)

          expect(Ticket.last.title).to eq('Foo')
        end

        it 'sets #state to "new"' do
          described_class.new.process({}, raw_mail)

          expect(Ticket.last.state.name).to eq('new')
        end

        context 'when no channel is given but a group with the :to address exists' do
          let!(:email_address) { create(:email_address, email: 'baz@qux.net', channel: nil) }
          let!(:group) { create(:group, name: 'baz headquarter', email_address: email_address) }
          let!(:channel) do
            channel = create(:email_channel, group: group)
            email_address.update(channel: channel)
            channel
          end

          it 'sets the group based on the :to field' do
            described_class.new.process({}, raw_mail)
            expect(Ticket.last.group.id).to eq(group.id)
          end
        end

        context 'when from address matches an existing agent' do
          let!(:agent) { create(:agent, email: 'foo@bar.com') }

          it 'sets article.sender to "Agent"' do
            described_class.new.process({}, raw_mail)

            expect(Ticket::Article.last.sender.name).to eq('Agent')
          end

          it 'sets ticket.state to "new"' do
            described_class.new.process({}, raw_mail)

            expect(Ticket.last.state.name).to eq('new')
          end
        end

        context 'when from address matches an existing agent customer' do
          let!(:agent_customer) { create(:agent_and_customer, email: 'foo@bar.com') }
          let!(:ticket) { create(:ticket, customer: agent_customer) }
          let!(:raw_email) { <<~RAW.chomp }
            From: foo@bar.com
            To: myzammad@example.com
            Subject: [#{Setting.get('ticket_hook') + Setting.get('ticket_hook_divider') + ticket.number}] test

            Lorem ipsum dolor
          RAW

          it 'sets article.sender to "Customer"' do
            described_class.new.process({}, raw_email)

            expect(Ticket::Article.last.sender.name).to eq('Customer')
          end
        end

        context 'when from address matches an existing customer' do
          let!(:customer) { create(:customer, email: 'foo@bar.com') }

          it 'sets article.sender to "Customer"' do
            described_class.new.process({}, raw_mail)

            expect(Ticket.last.articles.first.sender.name).to eq('Customer')
          end

          it 'sets ticket.state to "new"' do
            described_class.new.process({}, raw_mail)

            expect(Ticket.last.state.name).to eq('new')
          end
        end

        context 'when from address is unrecognized' do
          it 'sets article.sender to "Customer"' do
            described_class.new.process({}, raw_mail)

            expect(Ticket.last.articles.first.sender.name).to eq('Customer')
          end
        end
      end

      context 'when email contains x-headers' do
        let(:raw_mail) { <<~RAW.chomp }
          From: foo@bar.com
          To: baz@qux.net
          Subject: Foo
          X-Zammad-Ticket-priority: 3 high

          Lorem ipsum dolor
        RAW

        context 'when channel is not trusted' do
          let(:channel) { create(:channel, options: { inbound: { trusted: false } }) }

          it 'does not change the priority of the ticket (no channel)' do
            described_class.new.process({}, raw_mail)

            expect(Ticket.last.priority.name).to eq('2 normal')
          end

          it 'does not change the priority of the ticket (untrusted)' do
            described_class.new.process(channel, raw_mail)

            expect(Ticket.last.priority.name).to eq('2 normal')
          end
        end

        context 'when channel is trusted' do
          let(:channel) { create(:channel, options: { inbound: { trusted: true } }) }

          it 'does not change the priority of the ticket' do
            described_class.new.process(channel, raw_mail)

            expect(Ticket.last.priority.name).to eq('3 high')
          end
        end
      end

      context 'Mentions:' do
        let(:agent) { create(:agent) }
        let(:raw_mail) { <<~RAW.chomp }
          From: foo@bar.com
          To: baz@qux.net
          Subject: Foo

          Lorem ipsum dolor <a data-mention-user-id=\"#{agent.id}\">agent</a>
        RAW

        it 'creates a ticket and article without mentions and no exception raised' do
          expect { described_class.new.process({}, raw_mail) }
            .to change(Ticket, :count).by(1)
            .and change(Ticket::Article, :count).by_at_least(1)
            .and not_change(Mention, :count)
        end
      end
    end

    describe 'associating emails to existing tickets' do
      let!(:ticket) { create(:ticket) }
      let(:ticket_ref) { Setting.get('ticket_hook') + Setting.get('ticket_hook_divider') + ticket.number }

      describe 'based on where a ticket reference appears in the message' do
        shared_context 'ticket reference in subject' do
          let(:raw_mail) { <<~RAW.chomp }
            From: me@example.com
            To: customer@example.com
            Subject: #{ticket_ref}

            Lorem ipsum dolor
          RAW
        end

        shared_context 'ticket reference in body' do
          let(:raw_mail) { <<~RAW.chomp }
            From: me@example.com
            To: customer@example.com
            Subject: no reference

            Lorem ipsum dolor #{ticket_ref}
          RAW
        end

        shared_context 'ticket reference in body (text/html)' do
          let(:raw_mail) { <<~RAW.chomp }
            From: me@example.com
            To: customer@example.com
            Subject: no reference
            Content-Transfer-Encoding: 7bit
            Content-Type: text/html;

            <b>Lorem ipsum dolor #{ticket_ref}</b>
          RAW
        end

        shared_context 'ticket reference in text/plain attachment' do
          let(:raw_mail) { <<~RAW.chomp }
            From: me@example.com
            Content-Type: multipart/mixed; boundary="Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2"
            Subject: no reference
            Date: Sun, 30 Aug 2015 23:20:54 +0200
            To: Martin Edenhofer <me@znuny.com>
            Mime-Version: 1.0 (Mac OS X Mail 8.2 \(2104\))
            X-Mailer: Apple Mail (2.2104)


            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
            Content-Transfer-Encoding: 7bit
            Content-Type: text/plain;
              charset=us-ascii

            no reference
            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
            Content-Disposition: attachment;
              filename=test1.txt
            Content-Type: text/plain;
              name="test.txt"
            Content-Transfer-Encoding: 7bit

            Some Text #{ticket_ref}

            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2--
          RAW
        end

        shared_context 'ticket reference in text/html (as content) attachment' do
          let(:raw_mail) { <<~RAW.chomp }
            From: me@example.com
            Content-Type: multipart/mixed; boundary="Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2"
            Subject: no reference
            Date: Sun, 30 Aug 2015 23:20:54 +0200
            To: Martin Edenhofer <me@znuny.com>
            Mime-Version: 1.0 (Mac OS X Mail 8.2 \(2104\))
            X-Mailer: Apple Mail (2.2104)


            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
            Content-Transfer-Encoding: 7bit
            Content-Type: text/plain;
              charset=us-ascii

            no reference
            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
            Content-Disposition: attachment;
              filename=test1.txt
            Content-Type: text/html;
              name="test.txt"
            Content-Transfer-Encoding: 7bit

            <div>Some Text #{ticket_ref}</div>

            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2--
          RAW
        end

        shared_context 'ticket reference in text/html (attribute) attachment' do
          let(:raw_mail) { <<~RAW.chomp }
            From: me@example.com
            Content-Type: multipart/mixed; boundary="Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2"
            Subject: no reference
            Date: Sun, 30 Aug 2015 23:20:54 +0200
            To: Martin Edenhofer <me@znuny.com>
            Mime-Version: 1.0 (Mac OS X Mail 8.2 \(2104\))
            X-Mailer: Apple Mail (2.2104)


            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
            Content-Transfer-Encoding: 7bit
            Content-Type: text/plain;
              charset=us-ascii

            no reference
            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
            Content-Disposition: attachment;
              filename=test1.txt
            Content-Type: text/html;
              name="test.txt"
            Content-Transfer-Encoding: 7bit

            <div>Some Text <b data-something="#{ticket_ref}">some text</b></div>

            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2--
          RAW
        end

        shared_context 'ticket reference in image/jpg attachment' do
          let(:raw_mail) { <<~RAW.chomp }
            From: me@example.com
            Content-Type: multipart/mixed; boundary="Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2"
            Subject: no reference
            Date: Sun, 30 Aug 2015 23:20:54 +0200
            To: Martin Edenhofer <me@znuny.com>
            Mime-Version: 1.0 (Mac OS X Mail 8.2 \(2104\))
            X-Mailer: Apple Mail (2.2104)


            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
            Content-Transfer-Encoding: 7bit
            Content-Type: text/plain;
              charset=us-ascii

            no reference
            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2
            Content-Disposition: attachment;
              filename=test1.jpg
            Content-Type: image/jpg;
              name="test.jpg"
            Content-Transfer-Encoding: 7bit

            Some Text #{ticket_ref}

            --Apple-Mail=_ED77AC8D-FB6F-40E5-8FBE-D41FF5E1BAF2--
          RAW
        end

        shared_context 'ticket reference in In-Reply-To header' do
          let(:raw_mail) { <<~RAW.chomp }
            From: me@example.com
            To: customer@example.com
            Subject: no reference
            In-Reply-To: #{article.message_id}

            Lorem ipsum dolor
          RAW

          let!(:article) { create(:ticket_article, ticket: ticket, message_id: '<20150830145601.30.608882@edenhofer.zammad.com>') }
        end

        shared_context 'ticket reference in References header' do
          let(:raw_mail) { <<~RAW.chomp }
            From: me@example.com
            To: customer@example.com
            Subject: no reference
            References: <DA918CD1-BE9A-4262-ACF6-5001E59291B6@znuny.com> #{article.message_id} <DA918CD1-BE9A-4262-ACF6-5001E59291XX@znuny.com>

            Lorem ipsum dolor
          RAW

          let!(:article) { create(:ticket_article, ticket: ticket, message_id: '<20150830145601.30.608882@edenhofer.zammad.com>') }
        end

        shared_examples 'adds message to ticket' do
          it 'adds message to ticket' do
            expect { described_class.new.process({}, raw_mail) }
              .to change { ticket.articles.length }.by(1)
          end
        end

        shared_examples 'creates a new ticket' do
          it 'creates a new ticket' do
            expect { described_class.new.process({}, raw_mail) }
              .to change(Ticket, :count).by(1)
              .and not_change { ticket.articles.length }
          end
        end

        context 'when not explicitly configured to search anywhere' do
          before { Setting.set('postmaster_follow_up_search_in', nil) }

          context 'when subject contains ticket reference' do
            include_context 'ticket reference in subject'
            include_examples 'adds message to ticket'

            context 'alongside other, invalid ticket references' do
              let(:raw_mail) { <<~RAW.chomp }
                From: me@example.com
                To: customer@example.com
                Subject: [#{Setting.get('ticket_hook') + Setting.get('ticket_hook_divider') + Ticket::Number.generate}] #{ticket_ref}

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end

            context 'and ticket is closed' do
              before { ticket.update(state: Ticket::State.find_by(name: 'closed')) }

              include_examples 'adds message to ticket'
            end

            context 'but ticket group’s #follow_up_possible attribute is "new_ticket"' do
              before { ticket.group.update(follow_up_possible: 'new_ticket') }

              context 'and ticket is open' do
                include_examples 'adds message to ticket'
              end

              context 'and ticket is closed' do
                before { ticket.update(state: Ticket::State.find_by(name: 'closed')) }

                include_examples 'creates a new ticket'
              end

              context 'and ticket is merged' do
                before { ticket.update(state: Ticket::State.find_by(name: 'merged')) }

                include_examples 'creates a new ticket'
              end

              context 'and ticket is removed' do
                before { ticket.update(state: Ticket::State.find_by(name: 'removed')) }

                include_examples 'creates a new ticket'
              end
            end

            context 'and "ticket_hook" setting is non-default value' do
              before { Setting.set('ticket_hook', 'VD-Ticket#') }

              include_examples 'adds message to ticket'
            end
          end

          context 'when body contains ticket reference' do
            include_context 'ticket reference in body'
            include_examples 'creates a new ticket'
          end

          context 'when text/plain attachment contains ticket reference' do
            include_context 'ticket reference in text/plain attachment'
            include_examples 'creates a new ticket'
          end

          context 'when text/html attachment (as content) contains ticket reference' do
            include_context 'ticket reference in text/html (as content) attachment'
            include_examples 'creates a new ticket'
          end

          context 'when text/html attachment (attribute) contains ticket reference' do
            include_context 'ticket reference in text/html (attribute) attachment'
            include_examples 'creates a new ticket'
          end

          context 'when image/jpg attachment contains ticket reference' do
            include_context 'ticket reference in image/jpg attachment'
            include_examples 'creates a new ticket'
          end

          context 'when In-Reply-To header contains article message-id' do
            include_context 'ticket reference in In-Reply-To header'
            include_examples 'creates a new ticket'

            context 'and subject matches article subject' do
              let(:raw_mail) { <<~RAW.chomp }
                From: customer@example.com
                To: me@example.com
                Subject: AW: RE: #{article.subject}
                In-Reply-To: #{article.message_id}

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end

            context 'and "ticket_hook_position" setting is "none"' do
              before { Setting.set('ticket_hook_position', 'none') }

              let(:raw_mail) { <<~RAW.chomp }
                From: customer@example.com
                To: me@example.com
                Subject: RE: Foo bar
                In-Reply-To: #{article.message_id}

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end
          end

          context 'when References header contains article message-id' do
            include_context 'ticket reference in References header'
            include_examples 'creates a new ticket'

            context 'and Auto-Submitted header reads "auto-replied"' do
              let(:raw_mail) { <<~RAW.chomp }
                From: me@example.com
                To: customer@example.com
                Subject: no reference
                References: #{article.message_id}
                Auto-Submitted: auto-replied

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end

            context 'and subject matches article subject' do
              let(:raw_mail) { <<~RAW.chomp }
                From: customer@example.com
                To: me@example.com
                Subject: AW: RE: #{article.subject}
                References: #{article.message_id}

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end

            context 'and "ticket_hook_position" setting is "none"' do
              before { Setting.set('ticket_hook_position', 'none') }

              let(:raw_mail) { <<~RAW.chomp }
                From: customer@example.com
                To: me@example.com
                Subject: RE: Foo bar
                References: #{article.message_id}

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end
          end
        end

        context 'when configured to search body' do
          before { Setting.set('postmaster_follow_up_search_in', 'body') }

          context 'when subject contains ticket reference' do
            include_context 'ticket reference in subject'
            include_examples 'adds message to ticket'
          end

          context 'when body contains ticket reference' do
            context 'in visible text' do
              include_context 'ticket reference in body'
              include_examples 'adds message to ticket'
            end

            context 'as part of a larger word' do
              let(:ticket_ref) { "Foo#{Setting.get('ticket_hook')}#{Setting.get('ticket_hook_divider')}#{ticket.number}bar" }

              include_context 'ticket reference in body'
              include_examples 'creates a new ticket'
            end

            context 'between html tags' do
              include_context 'ticket reference in body (text/html)'
              include_examples 'adds message to ticket'
            end

            context 'in html attributes' do
              let(:ticket_ref) { %(<table bgcolor="#{Setting.get('ticket_hook')}#{Setting.get('ticket_hook_divider')}#{ticket.number}"> </table>) }

              include_context 'ticket reference in body (text/html)'
              include_examples 'creates a new ticket'
            end
          end

          context 'when text/plain attachment contains ticket reference' do
            include_context 'ticket reference in text/plain attachment'
            include_examples 'creates a new ticket'
          end

          context 'when text/html attachment (as content) contains ticket reference' do
            include_context 'ticket reference in text/html (as content) attachment'
            include_examples 'creates a new ticket'
          end

          context 'when text/html attachment (attribute) contains ticket reference' do
            include_context 'ticket reference in text/html (attribute) attachment'
            include_examples 'creates a new ticket'
          end

          context 'when image/jpg attachment contains ticket reference' do
            include_context 'ticket reference in image/jpg attachment'
            include_examples 'creates a new ticket'
          end

          context 'when In-Reply-To header contains article message-id' do
            include_context 'ticket reference in In-Reply-To header'
            include_examples 'creates a new ticket'

            context 'and Auto-Submitted header reads "auto-replied"' do
              let(:raw_mail) { <<~RAW.chomp }
                From: me@example.com
                To: customer@example.com
                Subject: no reference
                References: #{article.message_id}
                Auto-Submitted: auto-replied

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end
          end

          context 'when References header contains article message-id' do
            include_context 'ticket reference in References header'
            include_examples 'creates a new ticket'
          end
        end

        context 'when configured to search attachments' do
          before { Setting.set('postmaster_follow_up_search_in', 'attachment') }

          context 'when subject contains ticket reference' do
            include_context 'ticket reference in subject'
            include_examples 'adds message to ticket'
          end

          context 'when body contains ticket reference' do
            include_context 'ticket reference in body'
            include_examples 'creates a new ticket'
          end

          context 'when text/plain attachment contains ticket reference' do
            include_context 'ticket reference in text/plain attachment'
            include_examples 'adds message to ticket'
          end

          context 'when text/html attachment (as content) contains ticket reference' do
            include_context 'ticket reference in text/html (as content) attachment'
            include_examples 'adds message to ticket'
          end

          context 'when text/html attachment (attribute) contains ticket reference' do
            include_context 'ticket reference in text/html (attribute) attachment'
            include_examples 'creates a new ticket'
          end

          context 'when image/jpg attachment contains ticket reference' do
            include_context 'ticket reference in image/jpg attachment'
            include_examples 'creates a new ticket'
          end

          context 'when In-Reply-To header contains article message-id' do
            include_context 'ticket reference in In-Reply-To header'
            include_examples 'creates a new ticket'
          end

          context 'when References header contains article message-id' do
            include_context 'ticket reference in References header'
            include_examples 'creates a new ticket'

            context 'and Auto-Submitted header reads "auto-replied"' do
              let(:raw_mail) { <<~RAW.chomp }
                From: me@example.com
                To: customer@example.com
                Subject: no reference
                References: #{article.message_id}
                Auto-Submitted: auto-replied

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end
          end
        end

        context 'when configured to search headers' do
          before { Setting.set('postmaster_follow_up_search_in', 'references') }

          context 'when subject contains ticket reference' do
            include_context 'ticket reference in subject'
            include_examples 'adds message to ticket'
          end

          context 'when body contains ticket reference' do
            include_context 'ticket reference in body'
            include_examples 'creates a new ticket'
          end

          context 'when text/plain attachment contains ticket reference' do
            include_context 'ticket reference in text/plain attachment'
            include_examples 'creates a new ticket'
          end

          context 'when text/html attachment (as content) contains ticket reference' do
            include_context 'ticket reference in text/html (as content) attachment'
            include_examples 'creates a new ticket'
          end

          context 'when text/html attachment (attribute) contains ticket reference' do
            include_context 'ticket reference in text/html (attribute) attachment'
            include_examples 'creates a new ticket'
          end

          context 'when image/jpg attachment contains ticket reference' do
            include_context 'ticket reference in image/jpg attachment'
            include_examples 'creates a new ticket'
          end

          context 'when In-Reply-To header contains article message-id' do
            include_context 'ticket reference in In-Reply-To header'
            include_examples 'adds message to ticket'
          end

          context 'when References header contains article message-id' do
            include_context 'ticket reference in References header'
            include_examples 'adds message to ticket'

            context 'that matches two separate tickets' do
              let!(:newer_ticket) { create(:ticket) }
              let!(:newer_article) { create(:ticket_article, ticket: newer_ticket, message_id: article.message_id) }

              it 'returns more recently created ticket' do
                expect(described_class.new.process({}, raw_mail).first).to eq(newer_ticket)
              end

              it 'adds message to more recently created ticket' do
                expect { described_class.new.process({}, raw_mail) }
                  .to change { newer_ticket.articles.count }.by(1)
                  .and not_change { ticket.articles.count }
              end
            end

            context 'and Auto-Submitted header reads "auto-replied"' do
              let(:raw_mail) { <<~RAW.chomp }
                From: me@example.com
                To: customer@example.com
                Subject: no reference
                References: #{article.message_id}
                Auto-Submitted: auto-replied

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end
          end
        end

        context 'when configured to search everything' do
          before { Setting.set('postmaster_follow_up_search_in', %w[body attachment references]) }

          context 'when subject contains ticket reference' do
            include_context 'ticket reference in subject'
            include_examples 'adds message to ticket'
          end

          context 'when body contains ticket reference' do
            include_context 'ticket reference in body'
            include_examples 'adds message to ticket'
          end

          context 'when text/plain attachment contains ticket reference' do
            include_context 'ticket reference in text/plain attachment'
            include_examples 'adds message to ticket'
          end

          context 'when text/html attachment (as content) contains ticket reference' do
            include_context 'ticket reference in text/html (as content) attachment'
            include_examples 'adds message to ticket'
          end

          context 'when text/html attachment (attribute) contains ticket reference' do
            include_context 'ticket reference in text/html (attribute) attachment'
            include_examples 'creates a new ticket'
          end

          context 'when image/jpg attachment contains ticket reference' do
            include_context 'ticket reference in image/jpg attachment'
            include_examples 'creates a new ticket'
          end

          context 'when In-Reply-To header contains article message-id' do
            include_context 'ticket reference in In-Reply-To header'
            include_examples 'adds message to ticket'
          end

          context 'when References header contains article message-id' do
            include_context 'ticket reference in References header'
            include_examples 'adds message to ticket'

            context 'and Auto-Submitted header reads "auto-replied"' do
              let(:raw_mail) { <<~RAW.chomp }
                From: me@example.com
                To: customer@example.com
                Subject: no reference
                References: #{article.message_id}
                Auto-Submitted: auto-replied

                Lorem ipsum dolor
              RAW

              include_examples 'adds message to ticket'
            end
          end
        end
      end

      context 'for a closed ticket' do
        let(:ticket) { create(:ticket, state_name: 'closed') }

        let(:raw_mail) { <<~RAW.chomp }
          From: me@example.com
          To: customer@example.com
          Subject: #{ticket_ref}

          Lorem ipsum dolor
        RAW

        it 'reopens it' do
          expect { described_class.new.process({}, raw_mail) }
            .to change { ticket.reload.state.name }.to('open')
        end
      end
    end

    describe 'assigning ticket.customer' do
      let(:agent) { create(:agent) }
      let(:customer) { create(:customer) }

      let(:raw_mail) { <<~RAW.chomp }
        From: #{agent.email}
        To: #{customer.email}
        Subject: Foo

        Lorem ipsum dolor
      RAW

      context 'when "postmaster_sender_is_agent_search_for_customer" setting is true (default)' do
        it 'sets ticket.customer to user with To: email' do
          expect { described_class.new.process({}, raw_mail) }
            .to change(Ticket, :count).by(1)

          expect(Ticket.last.customer).to eq(customer)
        end
      end

      context 'when "postmaster_sender_is_agent_search_for_customer" setting is false' do
        before { Setting.set('postmaster_sender_is_agent_search_for_customer', false) }

        it 'sets ticket.customer to user with To: email' do
          expect { described_class.new.process({}, raw_mail) }
            .to change(Ticket, :count).by(1)

          expect(Ticket.last.customer).to eq(agent)
        end
      end
    end

    describe 'formatting to/from addresses' do
      # see https://github.com/zammad/zammad/issues/2198
      context 'when sender address contains spaces (#2198)' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail071.box') }
        let(:sender_email) { 'powerquadrantsystem@example.com' }

        it 'removes them before creating a new user' do
          expect { described_class.new.process({}, raw_mail) }
            .to change { User.exists?(email: sender_email) }
        end

        it 'marks new user email as invalid' do
          described_class.new.process({}, raw_mail)

          expect(User.find_by(email: sender_email).preferences)
            .to include('mail_delivery_failed' => true)
            .and include('mail_delivery_failed_reason' => 'invalid email')
            .and include('mail_delivery_failed_data' => a_kind_of(ActiveSupport::TimeWithZone))
        end
      end

      # see https://github.com/zammad/zammad/issues/2254
      context 'when sender address contains > (#2254)' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail076.box') }
        let(:sender_email) { 'millionslotteryspaintransfer@example.com' }

        it 'removes them before creating a new user' do
          expect { described_class.new.process({}, raw_mail) }
            .to change { User.exists?(email: sender_email) }
        end

        it 'marks new user email as invalid' do
          described_class.new.process({}, raw_mail)

          expect(User.find_by(email: sender_email).preferences)
            .to include('mail_delivery_failed' => true)
            .and include('mail_delivery_failed_reason' => 'invalid email')
            .and include('mail_delivery_failed_data' => a_kind_of(ActiveSupport::TimeWithZone))
        end
      end
    end

    describe 'signature detection' do
      let(:raw_mail) { header + File.read(message_file) }

      let(:header) { <<~HEADER }
        From: Bob.Smith@music.com
        To: test@zammad.org
        Subject: test

      HEADER

      context 'for emails from an unrecognized email address' do
        let(:message_file) { Rails.root.join('test/data/email_signature_detection/client_a_1.txt') }

        it 'does not detect signatures' do
          described_class.new.process({}, raw_mail)

          expect { Scheduler.worker(true) }
            .to not_change { Ticket.last.customer.preferences[:signature_detection] }.from(nil)
            .and not_change { Ticket.last.articles.first.preferences[:signature_detection] }.from(nil)
        end
      end

      context 'for emails from a previously processed sender' do
        before do
          described_class.new.process({}, header + File.read(previous_message_file))
        end

        let(:previous_message_file) { Rails.root.join('test/data/email_signature_detection/client_a_1.txt') }

        let(:message_file) { Rails.root.join('test/data/email_signature_detection/client_a_2.txt') }

        it 'sets detected signature on user (in a background job)' do
          described_class.new.process({}, raw_mail)

          expect { Scheduler.worker(true) }
            .to change { Ticket.last.customer.preferences[:signature_detection] }
        end

        it 'sets line of detected signature on article (in a background job)' do
          described_class.new.process({}, raw_mail)

          expect { Scheduler.worker(true) }
            .to change { Ticket.last.articles.first.preferences[:signature_detection] }.to(20)
        end
      end
    end

    describe 'charset handling' do
      # see https://github.com/zammad/zammad/issues/2224
      context 'when header specifies Windows-1258 charset (#2224)' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail072.box') }

        it 'does not raise Encoding::ConverterNotFoundError' do
          expect { described_class.new.process({}, raw_mail) }
            .not_to raise_error
        end
      end

      context 'when attachment for follow up check contains invalid charsets (#2808)' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail085.box') }

        before { Setting.set('postmaster_follow_up_search_in', %w[attachment body]) }

        it 'does not raise Encoding::CompatibilityError:' do
          expect { described_class.new.process({}, raw_mail) }
            .not_to raise_error
        end
      end

    end

    describe 'attachment handling' do
      context 'with header "Content-Transfer-Encoding: x-uuencode"' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail078-content_transfer_encoding_x_uuencode.box') }
        let(:article) { described_class.new.process({}, raw_mail).second }

        it 'does not raise RuntimeError' do
          expect { described_class.new.process({}, raw_mail) }
            .not_to raise_error
        end

        it 'parses the content correctly' do
          expect(article.attachments.first.filename).to eq('PGP_Cmts_on_12-14-01_Pkg.txt')
          expect(article.attachments.first.content).to eq('Hello Zammad')
        end
      end

      # https://github.com/zammad/zammad/issues/3529
      context 'Attachments sent by Zammad not shown in Outlook' do
        subject(:mail) do
          Channel::EmailBuild.build(
            from:         'sender@example.com',
            to:           'recipient@example.com',
            body:         body,
            content_type: 'text/html',
            attachments:  Store.where(filename: 'super-seven.jpg')
          )
        end

        let(:mail_file) { Rails.root.join('test/data/mail/mail101.box') }

        before do
          described_class.new.process({}, raw_mail)
        end

        context 'when no reference in body' do
          let(:body) { 'no reference here' }

          it 'does not have content disposition inline' do
            expect(mail.to_s).to include('Content-Disposition: attachment').and not_include('Content-Disposition: inline')
          end
        end

        context 'when reference in body' do
          let(:body) { %(somebody with some text <img src="cid:#{Store.find_by(filename: 'super-seven.jpg').preferences['Content-ID']}">) }

          it 'does have content disposition inline' do
            expect(mail.to_s).to include('Content-Disposition: inline').and not_include('Content-Disposition: attachment')
          end

          context 'when encoded as ISO-8859-1' do
            let(:body) { super().encode('ISO-8859-1') }

            it 'does not raise exception' do
              expect { mail.to_s }.not_to raise_error
            end
          end
        end
      end
    end

    describe 'inline image handling' do
      # see https://github.com/zammad/zammad/issues/2486
      context 'when image is large but not resizable' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail079.box') }
        let(:attachment) { article.attachments.to_a.find { |i| i.filename == 'a.jpg' } }
        let(:article) { described_class.new.process({}, raw_mail).second }

        it "doesn't set resizable preference" do
          expect(attachment.filename).to eq('a.jpg')
          expect(attachment.preferences).not_to include('resizable' => true)
        end
      end
    end

    describe 'ServiceNow handling' do

      context 'new Ticket' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail089.box') }

        it 'creates an ExternalSync reference' do
          described_class.new.process({}, raw_mail)

          expect(ExternalSync.last).to have_attributes(
            source:    'ServiceNow-example@service-now.com',
            source_id: 'INC678439',
            object:    'Ticket',
            o_id:      Ticket.last.id,
          )
        end
      end

      context 'follow up' do

        let(:mail_file) { Rails.root.join('test/data/mail/mail090.box') }
        let(:ticket) { create(:ticket) }
        let!(:external_sync) do
          create(:external_sync,
                 source:    'ServiceNow-example@service-now.com',
                 source_id: 'INC678439',
                 object:    'Ticket',
                 o_id:      ticket.id,)
        end

        it 'adds Article to existing Ticket' do
          expect { described_class.new.process({}, raw_mail) }.to change { ticket.reload.articles.count }
        end

        context 'key insensitive sender address' do

          let(:raw_mail) { super().gsub('example@service-now.com', 'Example@Service-Now.com') }

          it 'adds Article to existing Ticket' do
            expect { described_class.new.process({}, raw_mail) }.to change { ticket.reload.articles.count }
          end
        end
      end
    end

    describe 'XSS protection' do
      let(:article) { described_class.new.process({}, raw_mail).second }

      let(:raw_mail) { <<~RAW.chomp }
        From: ME Bob <me@example.com>
        To: customer@example.com
        Subject: some subject
        Content-Type: #{content_type}
        MIME-Version: 1.0

        no HTML <script type="text/javascript">alert(\'XSS\')</script>
      RAW

      context 'for Content-Type: text/html' do
        let(:content_type) { 'text/html' }

        it 'removes injected <script> tags from body' do
          expect(article.body).to eq("no HTML alert('XSS')")
        end
      end

      context 'for Content-Type: text/plain' do
        let(:content_type) { 'text/plain' }

        it 'leaves body as-is' do
          expect(article.body).to eq(<<~SANITIZED.chomp)
            no HTML <script type="text/javascript">alert(\'XSS\')</script>
          SANITIZED
        end
      end
    end

    context 'for “delivery failed” notifications (a.k.a. bounce messages)' do
      let(:ticket) { article.ticket }
      let(:article) { create(:ticket_article, sender_name: 'Agent', message_id: message_id) }
      let(:message_id) { raw_mail[%r{(?<=^(References|Message-ID): )\S*}] }

      context 'with future retries (delayed)' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail078.box') }

        context 'on a closed ticket' do
          before { ticket.update(state: Ticket::State.find_by(name: 'closed')) }

          it 'sets #preferences on resulting ticket to { "send-auto-responses" => false, "is-auto-reponse" => true }' do
            article = described_class.new.process({}, raw_mail).second
            expect(article.preferences)
              .to include('send-auto-response' => false, 'is-auto-response' => true)
          end

          it 'returns a Mail object with an x-zammad-out-of-office header' do
            output_mail = described_class.new.process({}, raw_mail).last
            expect(output_mail).to include('x-zammad-out-of-office': true)
          end

          it 'finds the article referenced in the bounce message headers, then adds the bounce message to its ticket' do
            expect { described_class.new.process({}, raw_mail) }
              .to change { ticket.articles.count }.by(1)
          end

          it 'does not re-open the ticket' do
            expect { described_class.new.process({}, raw_mail) }
              .not_to change { ticket.reload.state.name }.from('closed')
          end
        end
      end

      context 'with no future retries (undeliverable): sample input 1' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail033-undelivered-mail-returned-to-sender.box') }

        context 'for original message sent by Agent' do
          it 'sets #preferences on resulting ticket to { "send-auto-responses" => false, "is-auto-reponse" => true }' do
            article = described_class.new.process({}, raw_mail).second
            expect(article.preferences)
              .to include('send-auto-response' => false, 'is-auto-response' => true)
          end

          it 'finds the article referenced in the bounce message headers, then adds the bounce message to its ticket' do
            expect { described_class.new.process({}, raw_mail) }
              .to change { ticket.articles.count }.by(1)
          end

          it 'does not alter the ticket state' do
            expect { described_class.new.process({}, raw_mail) }
              .not_to change { ticket.reload.state.name }.from('open')
          end
        end

        context 'for original message sent by Customer' do
          let(:article) { create(:ticket_article, sender_name: 'Customer', message_id: message_id) }

          it 'sets #preferences on resulting ticket to { "send-auto-responses" => false, "is-auto-reponse" => true }' do
            article = described_class.new.process({}, raw_mail).second
            expect(article.preferences)
              .to include('send-auto-response' => false, 'is-auto-response' => true)
          end

          it 'finds the article referenced in the bounce message headers, then adds the bounce message to its ticket' do
            expect { described_class.new.process({}, raw_mail) }
              .to change { ticket.articles.count }.by(1)
          end

          it 'does not alter the ticket state' do
            expect { described_class.new.process({}, raw_mail) }
              .not_to change { ticket.reload.state.name }.from('new')
          end
        end
      end

      context 'with no future retries (undeliverable): sample input 2' do
        let(:mail_file) { Rails.root.join('test/data/mail/mail055.box') }

        it 'finds the article referenced in the bounce message headers, then adds the bounce message to its ticket' do
          expect { described_class.new.process({}, raw_mail) }
            .to change { ticket.articles.count }.by(1)
        end

        it 'does not alter the ticket state' do
          expect { described_class.new.process({}, raw_mail) }
            .not_to change { ticket.reload.state.name }.from('open')
        end
      end
    end

    context 'for “out-of-office” notifications (a.k.a. auto-response messages)' do
      let(:raw_mail) { <<~RAW.chomp }
        From: me@example.com
        To: customer@example.com
        Subject: #{subject_line}

        Some Text
      RAW
      let(:subject_line) { 'Lorem ipsum dolor' }

      it 'applies the OutOfOfficeCheck filter to given message' do
        expect(Channel::Filter::OutOfOfficeCheck)
          .to receive(:run)
          .with(kind_of(Hash), hash_including(subject: subject_line), kind_of(Hash))

        described_class.new.process({}, raw_mail)
      end

      context 'on an existing, closed ticket' do
        let(:ticket) { create(:ticket, state_name: 'closed') }
        let(:subject_line) { ticket.subject_build('Lorem ipsum dolor') }

        context 'when OutOfOfficeCheck filter applies x-zammad-out-of-office: false' do
          before do
            allow(Channel::Filter::OutOfOfficeCheck)
              .to receive(:run) { |_, mail_hash| mail_hash[:'x-zammad-out-of-office'] = false }
          end

          it 're-opens a closed ticket' do
            expect { described_class.new.process({}, raw_mail) }
              .to not_change(Ticket, :count)
              .and change { ticket.reload.state.name }.to('open')
          end
        end

        context 'when OutOfOfficeCheck filter applies x-zammad-out-of-office: true' do
          before do
            allow(Channel::Filter::OutOfOfficeCheck)
              .to receive(:run) { |_, mail_hash| mail_hash[:'x-zammad-out-of-office'] = true }
          end

          it 'does not re-open a closed ticket' do
            expect { described_class.new.process({}, raw_mail) }
              .to not_change(Ticket, :count)
              .and not_change { ticket.reload.state.name }
          end
        end
      end
    end

    describe 'suppressing normal Ticket::Article callbacks' do
      context 'from sender: "Agent"' do
        let(:agent) { create(:agent) }

        it 'does not dispatch an email on article creation' do
          expect(TicketArticleCommunicateEmailJob).not_to receive(:perform_later)

          described_class.new.process({}, <<~RAW.chomp)
            From: #{agent.email}
            To: customer@example.com
            Subject: some subject

            Some Text
          RAW
        end
      end
    end
  end

  describe '#compose_postmaster_reply' do
    let(:raw_incoming_mail) { File.read(Rails.root.join('test/data/mail/mail010.box')) }

    shared_examples 'postmaster reply' do
      it 'composes postmaster reply' do
        reply = described_class.new.send(:compose_postmaster_reply, raw_incoming_mail, locale)
        expect(reply[:to]).to eq('smith@example.com')
        expect(reply[:content_type]).to eq('text/plain')
        expect(reply[:subject]).to eq(expected_subject)
        expect(reply[:body]).to eq(expected_body)
      end
    end

    context 'for English locale (en)' do
      include_examples 'postmaster reply' do
        let(:locale) { 'en' }
        let(:expected_subject) { '[undeliverable] Message too large' }
        let(:expected_body) do
          body = <<~BODY
            Dear Smith Sepp,

            Unfortunately your email titled \"Gruß aus Oberalteich\" could not be delivered to one or more recipients.

            Your message was 0.01 MB but we only accept messages up to 10 MB.

            Please reduce the message size and try again. Thank you for your understanding.

            Regretfully,

            Postmaster of zammad.example.com
          BODY
          body.gsub(%r{\n}, "\r\n")
        end
      end
    end

    context 'for German locale (de)' do
      include_examples 'postmaster reply' do
        let(:locale) { 'de' }
        let(:expected_subject) { '[Unzustellbar] Nachricht zu groß' }
        let(:expected_body) do
          body = <<~BODY
            Hallo Smith Sepp,

            Ihre E-Mail mit dem Betreff \"Gruß aus Oberalteich\" konnte nicht an einen oder mehrere Empfänger zugestellt werden.

            Die Nachricht hatte eine Größe von 0.01 MB, wir akzeptieren jedoch nur E-Mails mit einer Größe von bis zu 10 MB.

            Bitte reduzieren Sie die Größe Ihrer Nachricht und versuchen Sie es erneut. Vielen Dank für Ihr Verständnis.

            Mit freundlichen Grüßen

            Postmaster von zammad.example.com
          BODY
          body.gsub(%r{\n}, "\r\n")
        end
      end
    end
  end

  describe '#mail_to_group' do

    context 'when EmailAddress exists' do

      context 'when gives address matches exactly' do

        let(:group) { create(:group) }
        let(:channel) { create(:email_channel, group: group) }
        let!(:email_address) { create(:email_address, channel: channel) }

        it 'returns the Channel Group' do
          expect(described_class.mail_to_group(email_address.email)).to eq(group)
        end
      end

      context 'when gives address matches key insensitive' do

        let(:group) { create(:group) }
        let(:channel) { create(:email_channel, group: group) }
        let(:address) { 'KeyInsensitive@example.COM' }
        let!(:email_address) { create(:email_address, email: address, channel: channel) }

        it 'returns the Channel Group' do
          expect(described_class.mail_to_group(address)).to eq(group)
        end
      end

      context 'when no Channel is assigned' do

        let!(:email_address) { create(:email_address, channel: nil) }

        it 'returns nil' do
          expect(described_class.mail_to_group(email_address.email)).to be_nil
        end
      end

      context 'when Channel has no Group assigned' do

        let(:channel) { create(:email_channel, group: nil) }
        let!(:email_address) { create(:email_address, channel: channel) }

        it 'returns nil' do
          expect(described_class.mail_to_group(email_address.email)).to be_nil
        end
      end
    end

    context 'when given address is not parse-able' do

      let(:address) { 'this_is_not_a_valid_email_address' }

      it 'returns nil' do
        expect(described_class.mail_to_group(address)).to be_nil
      end
    end
  end
end
