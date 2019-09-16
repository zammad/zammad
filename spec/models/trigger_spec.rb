require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Trigger, type: :model do
  subject(:trigger) { create(:trigger, condition: condition, perform: perform) }

  it_behaves_like 'ApplicationModel', can_assets: { selectors: %i[condition perform] }

  describe 'Send-email triggers' do
    before do
      described_class.destroy_all  # Default DB state includes three sample triggers
      trigger              # create subject trigger
    end

    let(:perform) do
      {
        'notification.email' => {
          'recipient' => 'ticket_customer',
          'subject'   => 'foo',
          'body'      => 'some body with &gt;snip&lt;#{article.body_as_html}&gt;/snip&lt;', # rubocop:disable Lint/InterpolationCheck
        }
      }
    end

    context 'for condition "ticket created"' do
      let(:condition) do
        { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } }
      end

      context 'when ticket is created directly' do
        let!(:ticket) { create(:ticket) }

        it 'fires (without altering ticket state)' do
          expect { Observer::Transaction.commit }
            .to change(Ticket::Article, :count).by(1)
            .and not_change { ticket.reload.state.name }.from('new')
        end
      end

      context 'when ticket is created via Channel::EmailParser.process' do
        before { create(:email_address, groups: [Group.first]) }

        let(:raw_email) { File.read(Rails.root.join('test', 'data', 'mail', 'mail001.box')) }

        it 'fires (without altering ticket state)' do
          expect { Channel::EmailParser.new.process({}, raw_email) }
            .to change(Ticket, :count).by(1)
            .and change { Ticket::Article.count }.by(2)

          expect(Ticket.last.state.name).to eq('new')
        end
      end

      context 'when ticket is created via Channel::EmailParser.process with inline image' do
        before { create(:email_address, groups: [Group.first]) }

        let(:raw_email) { File.read(Rails.root.join('test', 'data', 'mail', 'mail010.box')) }

        it 'fires (without altering ticket state)' do
          expect { Channel::EmailParser.new.process({}, raw_email) }
            .to change(Ticket, :count).by(1)
            .and change { Ticket::Article.count }.by(2)

          expect(Ticket.last.state.name).to eq('new')

          article = Ticket::Article.last
          expect(article.type.name).to eq('email')
          expect(article.sender.name).to eq('System')
          expect(article.attachments.count).to eq(1)
          expect(article.attachments[0].filename).to eq('image001.jpg')
          expect(article.attachments[0].preferences['Content-ID']).to eq('image001.jpg@01CDB132.D8A510F0')

          expect(article.body).to eq(<<~RAW.chomp
            some body with &gt;snip&lt;<div>
            <p>Herzliche Grüße aus Oberalteich sendet Herrn Smith</p>
            <p> </p>
            <p>Sepp Smith - Dipl.Ing. agr. (FH)</p>
            <p>Geschäftsführer der example Straubing-Bogen</p>
            <p>Klosterhof 1 | 94327 Bogen-Oberalteich</p>
            <p>Tel: 09422-505601 | Fax: 09422-505620</p>
            <p>Internet: <a href="http://example-straubing-bogen.de/" rel="nofollow noreferrer noopener" target="_blank">http://example-straubing-bogen.de</a></p>
            <p>Facebook: <a href="http://facebook.de/examplesrbog" rel="nofollow noreferrer noopener" target="_blank">http://facebook.de/examplesrbog</a></p>
            <p><b><img border="0" src="cid:image001.jpg@01CDB132.D8A510F0" alt="Beschreibung: Beschreibung: efqmLogo" style="width:60px;height:19px;"></b><b> - European Foundation für Quality Management</b></p>
            <p> </p>
            </div>&gt;/snip&lt;
          RAW
                                    )
        end
      end
    end

    context 'for condition "ticket updated"' do
      let(:condition) do
        { 'ticket.action' => { 'operator' => 'is', 'value' => 'update' } }
      end

      let!(:ticket) { create(:ticket).tap { Observer::Transaction.commit } }

      context 'when new article is created directly' do
        context 'with empty #preferences hash' do
          let!(:article) { create(:ticket_article, ticket: ticket)  }

          it 'fires (without altering ticket state)' do
            expect { Observer::Transaction.commit }
              .to change { ticket.reload.articles.count }.by(1)
              .and not_change { ticket.reload.state.name }.from('new')
          end
        end

        context 'with #preferences { "send-auto-response" => false }' do
          let!(:article) do
            create(:ticket_article,
                   ticket:      ticket,
                   preferences: { 'send-auto-response' => false })
          end

          it 'does not fire' do
            expect { Observer::Transaction.commit }
              .not_to change { ticket.reload.articles.count }
          end
        end
      end

      context 'when new article is created via Channel::EmailParser.process' do
        context 'with a regular message' do
          let!(:article) do
            create(:ticket_article,
                   ticket:     ticket,
                   message_id: raw_email[/(?<=^References: )\S*/],
                   subject:    raw_email[/(?<=^Subject: Re: ).*$/])
          end

          let(:raw_email) { File.read(Rails.root.join('test', 'data', 'mail', 'mail005.box')) }

          it 'fires (without altering ticket state)' do
            expect { Channel::EmailParser.new.process({}, raw_email) }
              .to not_change { Ticket.count }
              .and change { ticket.reload.articles.count }.by(2)
              .and not_change { ticket.reload.state.name }.from('new')
          end
        end

        context 'with delivery-failed "bounce message"' do
          let!(:article) do
            create(:ticket_article,
                   ticket:     ticket,
                   message_id: raw_email[/(?<=^Message-ID: )\S*/])
          end

          let(:raw_email) { File.read(Rails.root.join('test', 'data', 'mail', 'mail055.box')) }

          it 'does not fire' do
            expect { Channel::EmailParser.new.process({}, raw_email) }
              .to change { ticket.reload.articles.count }.by(1)
          end
        end
      end
    end
  end
end
