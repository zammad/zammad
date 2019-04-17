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
  end

  describe '#process' do
    let(:raw_mail)  { File.read(mail_file) }

    describe 'auto-creating new users' do
      context 'with one unrecognized email address' do
        it 'creates one new user' do
          expect { Channel::EmailParser.new.process({}, <<~RAW) }.to change { User.count }.by(1)
            From: #{Faker::Internet.unique.email}
          RAW
        end
      end

      context 'with a large number of unrecognized recipient addresses' do
        it 'never creates more than 40 users' do
          expect { Channel::EmailParser.new.process({}, <<~RAW) }.to change { User.count }.by(40)
            From: nicole.braun@zammad.org
            To: #{Array.new(20) { Faker::Internet.unique.email }.join(', ')}
            Cc: #{Array.new(21) { Faker::Internet.unique.email }.join(', ')}
          RAW
        end
      end
    end

    describe 'auto-updating existing users' do
      context 'with a previous email with no real name in the From: header' do
        let!(:customer) { Channel::EmailParser.new.process({}, previous_email).first.customer }

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
            expect { Channel::EmailParser.new.process({}, new_email) }
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
          expect { Channel::EmailParser.new.process({}, raw_mail) }
            .to change { Ticket.count }.by(1)
            .and change { Ticket::Article.count }.by_at_least(1)  # triggers may cause additional articles to be created
        end

        it 'sets #title to email subject' do
          Channel::EmailParser.new.process({}, raw_mail)

          expect(Ticket.last.title).to eq('Foo')
        end

        it 'sets #state to "new"' do
          Channel::EmailParser.new.process({}, raw_mail)

          expect(Ticket.last.state.name).to eq('new')
        end

        context 'when from address matches an existing agent' do
          let!(:agent) { create(:agent_user, email: 'foo@bar.com') }

          it 'sets article.sender to "Agent"' do
            Channel::EmailParser.new.process({}, raw_mail)

            expect(Ticket::Article.last.sender.name).to eq('Agent')
          end
        end

        context 'when from address matches an existing customer' do
          let!(:customer) { create(:customer_user, email: 'foo@bar.com') }

          it 'sets article.sender to "Customer"' do
            Channel::EmailParser.new.process({}, raw_mail)

            expect(Ticket.last.articles.first.sender.name).to eq('Customer')
          end
        end

        context 'when from address is unrecognized' do
          it 'sets article.sender to "Customer"' do
            Channel::EmailParser.new.process({}, raw_mail)

            expect(Ticket.last.articles.first.sender.name).to eq('Customer')
          end
        end
      end
    end

    describe 'associating emails to existing tickets' do
      let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail001.box') }
      let(:ticket_ref) { Setting.get('ticket_hook') + Setting.get('ticket_hook_divider') + ticket.number }
      let(:ticket) { create(:ticket) }

      context 'when email subject contains ticket reference' do
        let(:raw_mail) { File.read(mail_file).sub(/(?<=^Subject: ).*$/, ticket_ref) }

        it 'adds message to ticket' do
          expect { described_class.new.process({}, raw_mail) }
            .to change { ticket.articles.length }
        end

        context 'and ticket is closed' do
          before { ticket.update(state: Ticket::State.find_by(name: 'closed')) }

          it 'adds message to ticket' do
            expect { described_class.new.process({}, raw_mail) }
              .to change { ticket.articles.length }
          end
        end

        context 'but ticket group’s #follow_up_possible attribute is "new_ticket"' do
          before { ticket.group.update(follow_up_possible: 'new_ticket') }

          context 'and ticket is open' do
            it 'still adds message to ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .to change { ticket.articles.length }
            end
          end

          context 'and ticket is closed' do
            before { ticket.update(state: Ticket::State.find_by(name: 'closed')) }

            it 'creates a new ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .to change { Ticket.count }.by(1)
                .and not_change { ticket.articles.length }
            end
          end

          context 'and ticket is merged' do
            before { ticket.update(state: Ticket::State.find_by(name: 'merged')) }

            it 'creates a new ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .to change { Ticket.count }.by(1)
                .and not_change { ticket.articles.length }
            end
          end

          context 'and ticket is removed' do
            before { ticket.update(state: Ticket::State.find_by(name: 'removed')) }

            it 'creates a new ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .to change { Ticket.count }.by(1)
                .and not_change { ticket.articles.length }
            end
          end
        end
      end

      context 'when configured to search body' do
        before { Setting.set('postmaster_follow_up_search_in', 'body') }

        context 'when body contains ticket reference' do
          context 'in visible text' do
            let(:raw_mail) { File.read(mail_file).sub(/Hallo =\nMartin,(?=<o:p>)/, ticket_ref) }

            it 'adds message to ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .to change { ticket.articles.length }
            end
          end

          context 'as part of a larger word' do
            let(:raw_mail) { File.read(mail_file).sub(/(?<=Hallo) =\n(?=Martin,<o:p>)/, ticket_ref) }

            it 'creates a separate ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .not_to change { ticket.articles.length }
            end
          end

          context 'in html attributes' do
            let(:raw_mail) { File.read(mail_file).sub(%r{<a href.*?/a>}m, %(<table bgcolor="#{ticket_ref}"> </table>)) }

            it 'creates a separate ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .not_to change { ticket.articles.length }
            end
          end
        end
      end
    end

    describe 'assigning ticket.customer' do
      let(:agent) { create(:agent_user) }
      let(:customer) { create(:customer_user) }

      let(:raw_mail) { <<~RAW.chomp }
        From: #{agent.email}
        To: #{customer.email}
        Subject: Foo

        Lorem ipsum dolor
      RAW

      context 'when "postmaster_sender_is_agent_search_for_customer" setting is true (default)' do
        it 'sets ticket.customer to user with To: email' do
          expect { Channel::EmailParser.new.process({}, raw_mail) }
            .to change { Ticket.count }.by(1)

          expect(Ticket.last.customer).to eq(customer)
        end
      end

      context 'when "postmaster_sender_is_agent_search_for_customer" setting is false' do
        before { Setting.set('postmaster_sender_is_agent_search_for_customer', false) }

        it 'sets ticket.customer to user with To: email' do
          expect { Channel::EmailParser.new.process({}, raw_mail) }
            .to change { Ticket.count }.by(1)

          expect(Ticket.last.customer).to eq(agent)
        end
      end
    end

    describe 'formatting to/from addresses' do
      # see https://github.com/zammad/zammad/issues/2198
      context 'when sender address contains spaces (#2198)' do
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail071.box') }
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
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail076.box') }
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
        let(:message_file) { Rails.root.join('test', 'data', 'email_signature_detection', 'client_a_1.txt') }

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

        let(:previous_message_file) { Rails.root.join('test', 'data', 'email_signature_detection', 'client_a_1.txt') }

        let(:message_file) { Rails.root.join('test', 'data', 'email_signature_detection', 'client_a_2.txt') }

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
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail072.box') }

        it 'does not raise Encoding::ConverterNotFoundError' do
          expect { described_class.new.process({}, raw_mail) }
            .not_to raise_error
        end
      end
    end

    describe 'attachment handling' do
      context 'with header "Content-Transfer-Encoding: x-uuencode"' do
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail078-content_transfer_encoding_x_uuencode.box') }
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
    end

    describe 'inline image handling' do
      # see https://github.com/zammad/zammad/issues/2486
      context 'when image is large but not resizable' do
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail079.box') }
        let(:attachment) { article.attachments.to_a.find { |i| i.filename == 'a.jpg' } }
        let(:article) { described_class.new.process({}, raw_mail).second }

        it "doesn't set resizable preference" do
          expect(attachment.filename).to eq('a.jpg')
          expect(attachment.preferences).not_to include('resizable' => true)
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
      let(:message_id) { raw_mail[/(?<=^(References|Message-ID): )\S*/] }

      context 'with future retries (delayed)' do
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail078.box') }

        context 'on a closed ticket' do
          before { ticket.update(state: Ticket::State.find_by(name: 'closed')) }

          it 'sets #preferences on resulting ticket to { "send-auto-responses" => false, "is-auto-reponse" => true }' do
            article = Channel::EmailParser.new.process({}, raw_mail).second
            expect(article.preferences)
              .to include('send-auto-response' => false, 'is-auto-response' => true)
          end

          it 'returns a Mail object with an x-zammad-out-of-office header' do
            output_mail = Channel::EmailParser.new.process({}, raw_mail).last
            expect(output_mail).to include('x-zammad-out-of-office': true)
          end

          it 'finds the article referenced in the bounce message headers, then adds the bounce message to its ticket' do
            expect { Channel::EmailParser.new.process({}, raw_mail) }
              .to change { ticket.articles.count }.by(1)
          end

          it 'does not re-open the ticket' do
            expect { Channel::EmailParser.new.process({}, raw_mail) }
              .not_to change { ticket.reload.state.name }.from('closed')
          end
        end
      end

      context 'with no future retries (undeliverable): sample input 1' do
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail033-undelivered-mail-returned-to-sender.box') }

        context 'for original message sent by Agent' do
          it 'sets #preferences on resulting ticket to { "send-auto-responses" => false, "is-auto-reponse" => true }' do
            article = Channel::EmailParser.new.process({}, raw_mail).second
            expect(article.preferences)
              .to include('send-auto-response' => false, 'is-auto-response' => true)
          end

          it 'finds the article referenced in the bounce message headers, then adds the bounce message to its ticket' do
            expect { Channel::EmailParser.new.process({}, raw_mail) }
              .to change { ticket.articles.count }.by(1)
          end

          it 'does not alter the ticket state' do
            expect { Channel::EmailParser.new.process({}, raw_mail) }
              .not_to change { ticket.reload.state.name }.from('open')
          end
        end

        context 'for original message sent by Customer' do
          let(:article) { create(:ticket_article, sender_name: 'Customer', message_id: message_id) }

          it 'sets #preferences on resulting ticket to { "send-auto-responses" => false, "is-auto-reponse" => true }' do
            article = Channel::EmailParser.new.process({}, raw_mail).second
            expect(article.preferences)
              .to include('send-auto-response' => false, 'is-auto-response' => true)
          end

          it 'finds the article referenced in the bounce message headers, then adds the bounce message to its ticket' do
            expect { Channel::EmailParser.new.process({}, raw_mail) }
              .to change { ticket.articles.count }.by(1)
          end

          it 'does not alter the ticket state' do
            expect { Channel::EmailParser.new.process({}, raw_mail) }
              .not_to change { ticket.reload.state.name }.from('new')
          end
        end
      end

      context 'with no future retries (undeliverable): sample input 2' do
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail055.box') }

        it 'finds the article referenced in the bounce message headers, then adds the bounce message to its ticket' do
          expect { Channel::EmailParser.new.process({}, raw_mail) }
            .to change { ticket.articles.count }.by(1)
        end

        it 'does not alter the ticket state' do
          expect { Channel::EmailParser.new.process({}, raw_mail) }
            .not_to change { ticket.reload.state.name }.from('open')
        end
      end
    end
  end
end
