# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/touches_perform_references_examples'

RSpec.describe Trigger, type: :model do
  subject(:trigger) { create(:trigger, condition: condition, perform: perform, activator: activator, execution_condition_mode: execution_condition_mode) }

  let(:activator)                { 'action' }
  let(:execution_condition_mode) { 'selective' }
  let(:condition) do
    { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } }
  end
  let(:perform) do
    { 'ticket.title'=>{ 'value'=>'triggered' } }
  end

  it_behaves_like 'ApplicationModel', can_assets: { selectors: %i[condition perform] }
  it_behaves_like 'HasXssSanitizedNote', model_factory: :trigger
  it_behaves_like 'TouchesPerformReferences'

  describe 'validation' do
    it 'uses Validations::VerifyPerformRulesValidator' do
      expect(described_class).to have_validator(Validations::VerifyPerformRulesValidator).on(:perform)
    end

    it { is_expected.to validate_presence_of(:activator) }
    it { is_expected.to validate_presence_of(:execution_condition_mode) }
    it { is_expected.to validate_inclusion_of(:activator).in_array(%w[action time]) }
    it { is_expected.to validate_inclusion_of(:execution_condition_mode).in_array(%w[selective always]) }
  end

  describe 'Send-email triggers' do
    before do
      described_class.destroy_all # Default DB state includes three sample triggers
      trigger # create subject trigger
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

    shared_examples 'include ticket attachment' do
      context 'notification.email include_attachments' do
        let(:perform) do
          {
            'notification.email' => {
              'recipient' => 'ticket_customer',
              'subject'   => 'Example subject',
              'body'      => 'Example body',
            }
          }.deep_merge(additional_options).deep_stringify_keys
        end

        let(:ticket) { create(:ticket) }

        shared_examples 'add a new article' do
          it 'adds a new article' do
            expect { TransactionDispatcher.commit }
              .to change(ticket.articles, :count).by(1)
          end
        end

        shared_examples 'add attachment to new article' do
          include_examples 'add a new article'

          it 'adds attachment to the new article' do
            ticket && trigger

            TransactionDispatcher.commit
            article = ticket.articles.last

            expect(article.type.name).to eq('email')
            expect(article.sender.name).to eq('System')
            expect(article.attachments.count).to eq(1)
            expect(article.attachments[0].filename).to eq('some_file.pdf')
            expect(article.attachments[0].preferences['Content-ID']).to eq('image/pdf@01CAB192.K8H512Y9')
          end
        end

        shared_examples 'does not add attachment to new article' do
          include_examples 'add a new article'

          it 'does not add attachment to the new article' do
            ticket && trigger

            TransactionDispatcher.commit
            article = ticket.articles.last

            expect(article.type.name).to eq('email')
            expect(article.sender.name).to eq('System')
            expect(article.attachments.count).to eq(0)
          end
        end

        context 'with include attachment present' do
          let(:additional_options) do
            {
              'notification.email' => {
                include_attachments: 'true'
              }
            }
          end

          context 'when ticket has an attachment' do

            before do
              UserInfo.current_user_id = 1
              ticket_article = create(:ticket_article, ticket: ticket)

              create(:store,
                     object:      'Ticket::Article',
                     o_id:        ticket_article.id,
                     data:        'dGVzdCAxMjM=',
                     filename:    'some_file.pdf',
                     preferences: {
                       'Content-Type': 'image/pdf',
                       'Content-ID':   'image/pdf@01CAB192.K8H512Y9',
                     })
            end

            include_examples 'add attachment to new article'
          end

          context 'when ticket does not have an attachment' do

            include_examples 'does not add attachment to new article'
          end
        end

        context 'with include attachment not present' do
          let(:additional_options) do
            {
              'notification.email' => {
                include_attachments: 'false'
              }
            }
          end

          context 'when ticket has an attachment' do

            before do
              UserInfo.current_user_id = 1
              ticket_article = create(:ticket_article, ticket: ticket)

              create(:store,
                     object:      'Ticket::Article',
                     o_id:        ticket_article.id,
                     data:        'dGVzdCAxMjM=',
                     filename:    'some_file.pdf',
                     preferences: {
                       'Content-Type': 'image/pdf',
                       'Content-ID':   'image/pdf@01CAB192.K8H512Y9',
                     })
            end

            include_examples 'does not add attachment to new article'
          end

          context 'when ticket does not have an attachment' do

            include_examples 'does not add attachment to new article'
          end
        end
      end
    end

    context 'for condition "ticket created"' do
      let(:condition) do
        { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } }
      end

      context 'when ticket is created directly' do
        let!(:ticket) { create(:ticket) }

        it 'fires (without altering ticket state)' do
          expect { TransactionDispatcher.commit }
            .to change(Ticket::Article, :count).by(1)
            .and not_change { ticket.reload.state.name }.from('new')
        end
      end

      context 'when ticket has tags' do
        let(:tag1) { create(:'tag/item', name: 't1') }
        let(:tag2) { create(:'tag/item', name: 't2') }
        let(:tag3) { create(:'tag/item', name: 't3') }
        let!(:ticket) do
          ticket = create(:ticket)
          create(:tag, o: ticket, tag_item: tag1)
          create(:tag, o: ticket, tag_item: tag2)
          create(:tag, o: ticket, tag_item: tag3)
          ticket
        end

        let(:perform) do
          {
            'notification.email' => {
              'recipient' => 'ticket_customer',
              'subject'   => 'foo',
              'body'      => 'some body with #{ticket.tags}', # rubocop:disable Lint/InterpolationCheck
            }
          }
        end

        it 'fires body with replaced tags' do
          TransactionDispatcher.commit
          expect(Ticket::Article.last.body).to eq('some body with t1, t2, t3')
        end
      end

      context 'when ticket is created via Channel::EmailParser.process' do
        before { create(:email_address, groups: [Group.first]) }

        let(:raw_email) { Rails.root.join('test/data/mail/mail001.box').read }

        it 'fires (without altering ticket state)' do
          expect { Channel::EmailParser.new.process({}, raw_email) }
            .to change(Ticket, :count).by(1)
            .and change(Ticket::Article, :count).by(2)

          expect(Ticket.last.state.name).to eq('new')
        end
      end

      context 'when ticket is created via Channel::EmailParser.process with inline image' do
        before { create(:email_address, groups: [Group.first]) }

        let(:raw_email) { Rails.root.join('test/data/mail/mail010.box').read }

        it 'fires (without altering ticket state)' do
          expect { Channel::EmailParser.new.process({}, raw_email) }
            .to change(Ticket, :count).by(1)
            .and change(Ticket::Article, :count).by(2)

          expect(Ticket.last.state.name).to eq('new')

          article = Ticket::Article.last
          expect(article.type.name).to eq('email')
          expect(article.sender.name).to eq('System')
          expect(article.attachments.count).to eq(1)
          expect(article.attachments[0].filename).to eq('image001.jpg')
          expect(article.attachments[0].preferences['Content-ID']).to eq('image001.jpg@01CDB132.D8A510F0')

          expect(article.body).to eq(<<~RAW.chomp
            some body with &gt;snip&lt;<div><p>Herzliche Grüße aus Oberalteich sendet Herrn Smith</p><p>&nbsp;</p><p>Sepp Smith - Dipl.Ing. agr. (FH)</p><p>Geschäftsführer der example Straubing-Bogen</p><p>Klosterhof 1 | 94327 Bogen-Oberalteich</p><p>Tel: 09422-505601 | Fax: 09422-505620</p><p><span>Internet: <a href="http://example-straubing-bogen.de/" rel="nofollow noreferrer noopener" target="_blank"><span style="color:blue;">http://example-straubing-bogen.de</span></a></span></p><p><span lang="EN-US">Facebook: </span><a href="http://facebook.de/examplesrbog" rel="nofollow noreferrer noopener" target="_blank"><span lang="EN-US" style="color:blue;">http://facebook.de/examplesrbog</span></a><span lang="EN-US"></span></p><p><b><span style="color:navy;"><img border="0" src="cid:image001.jpg@01CDB132.D8A510F0" alt="Beschreibung: Beschreibung: efqmLogo" style="width:60px;height:19px;"></span></b><b><span lang="EN-US" style="color:navy;"> - European Foundation für Quality Management</span></b><span lang="EN-US"></span></p><p><span lang="EN-US"> </span></p></div>&gt;/snip&lt;
          RAW
                                    )
        end
      end

      context 'notification.email recipient' do
        let!(:ticket) { create(:ticket) }
        let!(:recipient1) { create(:user, email: 'test1@zammad-test.com') }
        let!(:recipient2) { create(:user, email: 'test2@zammad-test.com') }
        let!(:recipient3) { create(:user, email: 'test3@zammad-test.com') }

        let(:perform) do
          {
            'notification.email' => {
              'recipient' => recipient,
              'subject'   => 'Hello',
              'body'      => 'World!'
            }
          }
        end

        before { TransactionDispatcher.commit }

        context 'mix of recipient group keyword and single recipient users' do
          let(:recipient) { [ 'ticket_customer', "userid_#{recipient1.id}", "userid_#{recipient2.id}", "userid_#{recipient3.id}" ] }

          it 'contains all recipients' do
            expect(ticket.articles.last.to).to eq("#{ticket.customer.email}, #{recipient1.email}, #{recipient2.email}, #{recipient3.email}")
          end

          context 'duplicate recipient' do
            let(:recipient) { [ 'ticket_customer', "userid_#{ticket.customer.id}" ] }

            it 'contains only one recipient' do
              expect(ticket.articles.last.to).to eq(ticket.customer.email.to_s)
            end
          end
        end

        context 'list of single users only' do
          let(:recipient) { [ "userid_#{recipient1.id}", "userid_#{recipient2.id}", "userid_#{recipient3.id}" ] }

          it 'contains all recipients' do
            expect(ticket.articles.last.to).to eq("#{recipient1.email}, #{recipient2.email}, #{recipient3.email}")
          end

          context 'assets' do
            it 'resolves Users from recipient list' do
              expect(trigger.assets({})[:User].keys).to include(recipient1.id, recipient2.id, recipient3.id)
            end

            context 'single entry' do

              let(:recipient) { "userid_#{recipient1.id}" }

              it 'resolves User from recipient list' do
                expect(trigger.assets({})[:User].keys).to include(recipient1.id)
              end
            end
          end
        end

        context 'recipient group keyword only' do
          let(:recipient) { 'ticket_customer' }

          it 'contains matching recipient' do
            expect(ticket.articles.last.to).to eq(ticket.customer.email.to_s)
          end
        end
      end

      context 'active S/MIME integration' do
        before do
          Setting.set('smime_integration', true)

          create(:smime_certificate, :with_private, fixture: system_email_address)
          create(:smime_certificate, fixture: customer_email_address)
        end

        let(:system_email_address)   { 'smime1@example.com' }
        let(:customer_email_address) { 'smime2@example.com' }

        let(:email_address) { create(:email_address, email: system_email_address) }

        let(:group)    { create(:group, email_address: email_address) }
        let(:customer) { create(:customer, email: customer_email_address) }

        let(:security_preferences) { Ticket::Article.last.preferences[:security] }

        let(:perform) do
          {
            'notification.email' => {
              'recipient' => 'ticket_customer',
              'subject'   => 'Subject dummy.',
              'body'      => 'Body dummy.',
            }.merge(security_configuration)
          }
        end

        let!(:ticket) { create(:ticket, group: group, customer: customer) }

        context 'sending articles' do

          before do
            TransactionDispatcher.commit
          end

          context 'expired certificate' do

            let(:system_email_address) { 'expiredsmime1@example.com' }

            let(:security_configuration) do
              {
                'sign'       => 'always',
                'encryption' => 'always',
              }
            end

            it 'creates unsigned article' do
              expect(security_preferences[:sign][:success]).to be false
              expect(security_preferences[:encryption][:success]).to be true
            end
          end

          context 'sign and encryption not set' do

            let(:security_configuration) { {} }

            it 'does not sign or encrypt' do
              expect(security_preferences[:sign][:success]).to be false
              expect(security_preferences[:encryption][:success]).to be false
            end
          end

          context 'sign and encryption disabled' do
            let(:security_configuration) do
              {
                'sign'       => 'no',
                'encryption' => 'no',
              }
            end

            it 'does not sign or encrypt' do
              expect(security_preferences[:sign][:success]).to be false
              expect(security_preferences[:encryption][:success]).to be false
            end
          end

          context 'sign is enabled' do
            let(:security_configuration) do
              {
                'sign'       => 'always',
                'encryption' => 'no',
              }
            end

            it 'signs' do
              expect(security_preferences[:sign][:success]).to be true
              expect(security_preferences[:encryption][:success]).to be false
            end
          end

          context 'encryption enabled' do

            let(:security_configuration) do
              {
                'sign'       => 'no',
                'encryption' => 'always',
              }
            end

            it 'encrypts' do
              expect(security_preferences[:sign][:success]).to be false
              expect(security_preferences[:encryption][:success]).to be true
            end
          end

          context 'sign and encryption enabled' do

            let(:security_configuration) do
              {
                'sign'       => 'always',
                'encryption' => 'always',
              }
            end

            it 'signs and encrypts' do
              expect(security_preferences[:sign][:success]).to be true
              expect(security_preferences[:encryption][:success]).to be true
            end
          end
        end

        context 'discard' do

          context 'sign' do

            let(:security_configuration) do
              {
                'sign' => 'discard',
              }
            end

            context 'group without certificate' do
              let(:group) { create(:group) }

              it 'does not fire' do
                expect { TransactionDispatcher.commit }
                  .not_to change(Ticket::Article, :count)
              end
            end
          end

          context 'encryption' do

            let(:security_configuration) do
              {
                'encryption' => 'discard',
              }
            end

            context 'customer without certificate' do
              let(:customer) { create(:customer) }

              it 'does not fire' do
                expect { TransactionDispatcher.commit }
                  .not_to change(Ticket::Article, :count)
              end
            end
          end

          context 'mixed' do

            context 'sign' do

              let(:security_configuration) do
                {
                  'encryption' => 'always',
                  'sign'       => 'discard',
                }
              end

              context 'group without certificate' do
                let(:group) { create(:group) }

                it 'does not fire' do
                  expect { TransactionDispatcher.commit }
                    .not_to change(Ticket::Article, :count)
                end
              end
            end

            context 'encryption' do

              let(:security_configuration) do
                {
                  'encryption' => 'discard',
                  'sign'       => 'always',
                }
              end

              context 'customer without certificate' do
                let(:customer) { create(:customer) }

                it 'does not fire' do
                  expect { TransactionDispatcher.commit }
                    .not_to change(Ticket::Article, :count)
                end
              end
            end
          end
        end
      end

      context 'active PGP integration' do
        before do
          Setting.set('pgp_integration', true)

          create(:pgp_key, :with_private, fixture: system_email_address)
          create(:pgp_key, fixture: customer_email_address)
        end

        let(:system_email_address)   { 'pgp1@example.com' }
        let(:customer_email_address) { 'pgp2@example.com' }

        let(:email_address) { create(:email_address, email: system_email_address) }

        let(:group)    { create(:group, email_address: email_address) }
        let(:customer) { create(:customer, email: customer_email_address) }

        let(:security_preferences) { Ticket::Article.last.preferences[:security] }

        let(:perform) do
          {
            'notification.email' => {
              'recipient' => 'ticket_customer',
              'subject'   => 'Subject dummy.',
              'body'      => 'Body dummy.',
            }.merge(security_configuration)
          }
        end

        let!(:ticket) { create(:ticket, group: group, customer: customer) }

        context 'sending articles' do

          before do
            TransactionDispatcher.commit
          end

          context 'expired pgp key' do

            let(:system_email_address) { 'expiredpgp1@example.com' }

            let(:security_configuration) do
              {
                'sign'       => 'always',
                'encryption' => 'always',
              }
            end

            it 'creates unsigned article' do
              expect(security_preferences[:sign][:success]).to be false
              expect(security_preferences[:encryption][:success]).to be true
            end
          end

          context 'sign and encryption not set' do

            let(:security_configuration) { {} }

            it 'does not sign or encrypt' do
              expect(security_preferences[:sign][:success]).to be false
              expect(security_preferences[:encryption][:success]).to be false
            end
          end

          context 'sign and encryption disabled' do
            let(:security_configuration) do
              {
                'sign'       => 'no',
                'encryption' => 'no',
              }
            end

            it 'does not sign or encrypt' do
              expect(security_preferences[:sign][:success]).to be false
              expect(security_preferences[:encryption][:success]).to be false
            end
          end

          context 'sign is enabled' do
            let(:security_configuration) do
              {
                'sign'       => 'always',
                'encryption' => 'no',
              }
            end

            it 'signs' do
              expect(security_preferences[:sign][:success]).to be true
              expect(security_preferences[:encryption][:success]).to be false
            end
          end

          context 'encryption enabled' do

            let(:security_configuration) do
              {
                'sign'       => 'no',
                'encryption' => 'always',
              }
            end

            it 'encrypts' do
              expect(security_preferences[:sign][:success]).to be false
              expect(security_preferences[:encryption][:success]).to be true
            end
          end

          context 'sign and encryption enabled' do

            let(:security_configuration) do
              {
                'sign'       => 'always',
                'encryption' => 'always',
              }
            end

            it 'signs and encrypts' do
              expect(security_preferences[:sign][:success]).to be true
              expect(security_preferences[:encryption][:success]).to be true
            end
          end
        end

        context 'discard' do

          context 'sign' do

            let(:security_configuration) do
              {
                'sign' => 'discard',
              }
            end

            context 'group without pgp key' do
              let(:group) { create(:group) }

              it 'does not fire' do
                expect { TransactionDispatcher.commit }
                  .not_to change(Ticket::Article, :count)
              end
            end
          end

          context 'encryption' do

            let(:security_configuration) do
              {
                'encryption' => 'discard',
              }
            end

            context 'customer without pgp key' do
              let(:customer) { create(:customer) }

              it 'does not fire' do
                expect { TransactionDispatcher.commit }
                  .not_to change(Ticket::Article, :count)
              end
            end
          end

          context 'mixed' do

            context 'sign' do

              let(:security_configuration) do
                {
                  'encryption' => 'always',
                  'sign'       => 'discard',
                }
              end

              context 'group without pgp key' do
                let(:group) { create(:group) }

                it 'does not fire' do
                  expect { TransactionDispatcher.commit }
                    .not_to change(Ticket::Article, :count)
                end
              end
            end

            context 'encryption' do

              let(:security_configuration) do
                {
                  'encryption' => 'discard',
                  'sign'       => 'always',
                }
              end

              context 'customer without pgp key' do
                let(:customer) { create(:customer) }

                it 'does not fire' do
                  expect { TransactionDispatcher.commit }
                    .not_to change(Ticket::Article, :count)
                end
              end
            end
          end
        end
      end

      include_examples 'include ticket attachment'
    end

    context 'for condition "ticket updated"' do
      let(:condition) do
        { 'ticket.action' => { 'operator' => 'is', 'value' => 'update' } }
      end

      let!(:ticket) { create(:ticket).tap { TransactionDispatcher.commit } }

      context 'when new article is created directly' do
        context 'with empty #preferences hash' do
          let!(:article) { create(:ticket_article, ticket: ticket) }

          it 'fires (without altering ticket state)' do
            expect { TransactionDispatcher.commit }
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
            expect { TransactionDispatcher.commit }
              .not_to change { ticket.reload.articles.count }
          end
        end
      end

      context 'when new article is created via Channel::EmailParser.process' do
        context 'with a regular message' do
          let!(:article) do
            create(:ticket_article,
                   ticket:     ticket,
                   message_id: raw_email[%r{(?<=^References: )\S*}],
                   subject:    raw_email[%r{(?<=^Subject: Re: ).*$}])
          end

          let(:raw_email) { Rails.root.join('test/data/mail/mail005.box').read }

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
                   message_id: raw_email[%r{(?<=^Message-ID: )\S*}])
          end

          let(:raw_email) { Rails.root.join('test/data/mail/mail055.box').read }

          it 'does not fire' do
            expect { Channel::EmailParser.new.process({}, raw_email) }
              .to change { ticket.reload.articles.count }.by(1)
          end
        end
      end

      # https://github.com/zammad/zammad/issues/3991
      context 'when article contains a mention' do
        let!(:article) do
          create(:ticket_article,
                 ticket: ticket,
                 body:   '<a href="http:/#user/profile/1" data-mention-user-id="1" rel="nofollow noreferrer noopener" target="_blank" title="http:/#user/profile/1">Test Admin Agent</a> test<br>')
        end

        it 'fires correctly' do
          expect { TransactionDispatcher.commit }
            .to change { ticket.reload.articles.count }.by(1)
        end
      end
    end

    context 'with condition execution_time.calendar_id' do
      let(:calendar) { create(:calendar) }
      let(:perform) do
        { 'ticket.title'=>{ 'value'=>'triggered' } }
      end
      let!(:ticket) { create(:ticket, title: 'Test Ticket') }

      context 'is in working time' do
        let(:condition) do
          { 'ticket.state_id' => { 'operator' => 'is', 'value' => Ticket::State.pluck(:id) }, 'execution_time.calendar_id' => { 'operator' => 'is in working time', 'value' => calendar.id } }
        end

        it 'does trigger only in working time' do
          travel_to Time.zone.parse('2020-02-12T12:00:00Z0')
          expect { TransactionDispatcher.commit }.to change { ticket.reload.title }.to('triggered')
        end

        it 'does not trigger out of working time' do
          travel_to Time.zone.parse('2020-02-12T02:00:00Z0')
          TransactionDispatcher.commit
          expect(ticket.reload.title).to eq('Test Ticket')
        end
      end

      context 'is not in working time' do
        let(:condition) do
          { 'execution_time.calendar_id' => { 'operator' => 'is not in working time', 'value' => calendar.id } }
        end

        it 'does not trigger in working time' do
          travel_to Time.zone.parse('2020-02-12T12:00:00Z0')
          TransactionDispatcher.commit
          expect(ticket.reload.title).to eq('Test Ticket')
        end

        it 'does trigger out of working time' do
          travel_to Time.zone.parse('2020-02-12T02:00:00Z0')
          expect { TransactionDispatcher.commit }.to change { ticket.reload.title }.to('triggered')
        end
      end
    end

    context 'with article last sender equals system address' do
      let!(:ticket) { create(:ticket) }
      let(:perform) do
        {
          'notification.email' => {
            'recipient' => 'article_last_sender',
            'subject'   => 'foo last sender',
            'body'      => 'some body with &gt;snip&lt;#{article.body_as_html}&gt;/snip&lt;', # rubocop:disable Lint/InterpolationCheck
          }
        }
      end
      let(:condition) do
        { 'ticket.state_id' => { 'operator' => 'is', 'value' => Ticket::State.pluck(:id) } }
      end
      let!(:system_address) do
        create(:email_address)
      end

      context 'article with from equal to the a system address' do
        let!(:article) do
          create(:ticket_article,
                 ticket: ticket,
                 from:   system_address.email,)
        end

        it 'does not trigger because of the last article is created my system address' do
          expect { TransactionDispatcher.commit }.not_to change { ticket.reload.articles.count }
          expect(Ticket::Article.where(ticket: ticket).last.subject).not_to eq('foo last sender')
          expect(Ticket::Article.where(ticket: ticket).last.to).not_to eq(system_address.email)
        end
      end

      context 'article with reply_to equal to the a system address' do
        let!(:article) do
          create(:ticket_article,
                 ticket:   ticket,
                 from:     system_address.email,
                 reply_to: system_address.email,)
        end

        it 'does not trigger because of the last article is created my system address' do
          expect { TransactionDispatcher.commit }.not_to change { ticket.reload.articles.count }
          expect(Ticket::Article.where(ticket: ticket).last.subject).not_to eq('foo last sender')
          expect(Ticket::Article.where(ticket: ticket).last.to).not_to eq(system_address.email)
        end
      end

      include_examples 'include ticket attachment'
    end
  end

  context 'with pre condition current_user.id' do
    let(:perform) do
      { 'ticket.title'=>{ 'value'=>'triggered' } }
    end

    let(:user) do
      user = create(:agent)
      user.roles.first.groups << group
      user
    end

    let(:group) { Group.first }

    let(:ticket) do
      create(:ticket,
             title: 'Test Ticket', group: group,
             owner_id: user.id, created_by_id: user.id, updated_by_id: user.id)
    end

    shared_examples 'successful trigger' do |attribute:|
      let(:attribute) { attribute }

      let(:condition) do
        { attribute => { operator: 'is', pre_condition: 'current_user.id', value: '', value_completion: '' } }
      end

      it "for #{attribute}" do
        ticket && trigger
        expect { TransactionDispatcher.commit }.to change { ticket.reload.title }.to('triggered')
      end
    end

    it_behaves_like 'successful trigger', attribute: 'ticket.updated_by_id'
    it_behaves_like 'successful trigger', attribute: 'ticket.owner_id'
  end

  describe 'Multi-trigger interactions:' do
    let(:ticket) { create(:ticket) }

    context 'cascading (i.e., trigger A satisfies trigger B satisfies trigger C)' do
      subject!(:triggers) do
        [
          create(:trigger, condition: initial_state, perform: first_change, name: 'A'),
          create(:trigger, condition: first_change, perform: second_change, name: 'B'),
          create(:trigger, condition: second_change, perform: third_change, name: 'C')
        ]
      end

      context 'in a chain' do
        let(:initial_state) do
          {
            'ticket.state_id' => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'new').id.to_s,
            }
          }
        end

        let(:first_change) do
          {
            'ticket.state_id' => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'open').id.to_s,
            }
          }
        end

        let(:second_change) do
          {
            'ticket.state_id' => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'closed').id.to_s,
            }
          }
        end

        let(:third_change) do
          {
            'ticket.state_id' => {
              'operator' => 'is',
              'value'    => Ticket::State.lookup(name: 'merged').id.to_s,
            }
          }
        end

        context 'in alphabetical order (by name)' do
          it 'fires all triggers in sequence' do
            expect { TransactionDispatcher.commit }
              .to change { ticket.reload.state.name }.to('merged')
          end
        end

        context 'out of alphabetical order (by name)' do
          before do
            triggers.first.update(name: 'E')
            triggers.second.update(name: 'F')
            triggers.third.update(name: 'D')
          end

          context 'with Setting ticket_trigger_recursive: true' do
            before { Setting.set('ticket_trigger_recursive', true) }

            it 'evaluates triggers in sequence, then loops back to the start and re-evalutes skipped triggers' do
              expect { TransactionDispatcher.commit }
                .to change { ticket.reload.state.name }.to('merged')
            end
          end

          context 'with Setting ticket_trigger_recursive: false' do
            before { Setting.set('ticket_trigger_recursive', false) }

            it 'evaluates triggers in sequence, firing only the ones that match' do
              expect { TransactionDispatcher.commit }
                .to change { ticket.reload.state.name }.to('closed')
            end
          end
        end
      end

      context 'in circular reference (i.e., trigger A satisfies trigger B satisfies trigger C satisfies trigger A...)' do
        let(:initial_state) do
          {
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            }
          }
        end

        let(:first_change) do
          {
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
            }
          }
        end

        let(:second_change) do
          {
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '1 low').id.to_s,
            }
          }
        end

        let(:third_change) do
          {
            'ticket.priority_id' => {
              'operator' => 'is',
              'value'    => Ticket::Priority.lookup(name: '2 normal').id.to_s,
            }
          }
        end

        context 'with Setting ticket_trigger_recursive: true' do
          before { Setting.set('ticket_trigger_recursive', true) }

          it 'fires each trigger once, without being caught in an endless loop' do
            expect { Timeout.timeout(2) { TransactionDispatcher.commit } }
              .to not_change { ticket.reload.priority.name }
              .and not_raise_error
          end
        end

        context 'with Setting ticket_trigger_recursive: false' do
          before { Setting.set('ticket_trigger_recursive', false) }

          it 'fires each trigger once, without being caught in an endless loop' do
            expect { Timeout.timeout(2) { TransactionDispatcher.commit } }
              .to not_change { ticket.reload.priority.name }
              .and not_raise_error
          end
        end
      end
    end

    context 'competing (i.e., trigger A un-satisfies trigger B)' do
      subject!(:triggers) do
        [
          create(:trigger, condition: initial_state, perform: change_a, name: 'A'),
          create(:trigger, condition: initial_state, perform: change_b, name: 'B')
        ]
      end

      let(:initial_state) do
        {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        }
      end

      let(:change_a) do
        {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'open').id.to_s,
          }
        }
      end

      let(:change_b) do
        {
          'ticket.priority_id' => {
            'operator' => 'is',
            'value'    => Ticket::Priority.lookup(name: '3 high').id.to_s,
          }
        }
      end

      it 'evaluates triggers in sequence, firing only the ones that match' do
        expect { TransactionDispatcher.commit }
          .to change { ticket.reload.state.name }.to('open')
          .and not_change { ticket.reload.priority.name }
      end
    end
  end

  describe 'multiselect triggers', db_strategy: :reset do

    let(:attribute_name) { 'multiselect' }

    let(:condition) do
      { "ticket.#{attribute_name}" => { 'operator' => operator, 'value' => trigger_values } }
    end

    let(:perform) do
      { 'article.note' => { 'subject' => 'Test subject note', 'internal' => 'true', 'body' => 'Test body note' } }
    end

    before do
      create(:object_manager_attribute_multiselect, name: attribute_name)
      ObjectManager::Attribute.migration_execute

      described_class.destroy_all # Default DB state includes three sample triggers
      trigger # create subject trigger
    end

    context 'when ticket is updated with a multiselect trigger condition', authenticated_as: :owner, db_strategy: :reset do
      let(:options) do
        {
          a: 'a',
          b: 'b',
          c: 'c',
          d: 'd',
          e: 'e',
        }
      end

      let(:trigger_values) { %w[a b c] }
      let(:group)          { create(:group) }
      let(:owner)          { create(:admin, group_ids: [group.id]) }
      let!(:ticket)        { create(:ticket, group: group,) }

      before do
        ticket.update_attribute(attribute_name, ticket_multiselect_values)
      end

      shared_examples 'updating the ticket with the trigger condition' do
        it 'updates the ticket with the trigger condition' do
          expect { TransactionDispatcher.commit }
            .to change(Ticket::Article, :count).by(1)
        end
      end

      shared_examples 'not updating the ticket with the trigger condition' do
        it 'does not update the ticket with the trigger condition' do
          expect { TransactionDispatcher.commit }
            .to not_change(Ticket::Article, :count)
        end
      end

      context "with 'contains all' used" do
        let(:operator) { 'contains all' }

        context 'when updated value is the same with trigger value' do
          let(:ticket_multiselect_values) { trigger_values }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when updated value is different from the trigger value' do
          let(:ticket_multiselect_values) { options.values - trigger_values }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when no value is selected' do
          let(:ticket_multiselect_values) { ['-'] }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when all value is selected' do
          let(:ticket_multiselect_values) { options.values }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when updated value contains one of the trigger value' do
          let(:ticket_multiselect_values) { [trigger_values.first] }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when updated value does not contain one of the trigger value' do
          let(:ticket_multiselect_values) { options.values - [trigger_values.first] }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end
      end

      context "with 'contains one' used" do
        let(:operator) { 'contains one' }

        context 'when updated value is the same with trigger value' do
          let(:ticket_multiselect_values) { trigger_values }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when updated value is different from the trigger value' do
          let(:ticket_multiselect_values) { options.values - trigger_values }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when no value is selected' do
          let(:ticket_multiselect_values) { ['-'] }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when all value is selected' do
          let(:ticket_multiselect_values) { options.values }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when updated value contains only one of the trigger value' do
          let(:ticket_multiselect_values) { [trigger_values.first] }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when updated value does not contain one of the trigger value' do
          let(:ticket_multiselect_values) { options.values - [trigger_values.first] }

          it_behaves_like 'updating the ticket with the trigger condition'
        end
      end

      context "with 'contains all not' used" do
        let(:operator) { 'contains all not' }

        context 'when updated value is the same with trigger value' do
          let(:ticket_multiselect_values) { trigger_values }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when updated value is different from the trigger value' do
          let(:ticket_multiselect_values) { options.values - trigger_values }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when no value is selected' do
          let(:ticket_multiselect_values) { ['-'] }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when all value is selected' do
          let(:ticket_multiselect_values) { options.values }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when updated value contains only one of the trigger value' do
          let(:ticket_multiselect_values) { [trigger_values.first] }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when updated value does not contain one of the trigger value' do
          let(:ticket_multiselect_values) { options.values - [trigger_values.first] }

          it_behaves_like 'updating the ticket with the trigger condition'
        end
      end

      context "with 'contains one not' used" do
        let(:operator) { 'contains one not' }

        context 'when updated value is the same with trigger value' do
          let(:ticket_multiselect_values) { trigger_values }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when updated value is different from the trigger value' do
          let(:ticket_multiselect_values) { options.values - trigger_values }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when no value is selected' do
          let(:ticket_multiselect_values) { ['-'] }

          it_behaves_like 'updating the ticket with the trigger condition'
        end

        context 'when all value is selected' do
          let(:ticket_multiselect_values) { options.values }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when updated value contains only one of the trigger value' do
          let(:ticket_multiselect_values) { [trigger_values.first] }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end

        context 'when updated value does not contain one of the trigger value' do
          let(:ticket_multiselect_values) { options.values - [trigger_values.first] }

          it_behaves_like 'not updating the ticket with the trigger condition'
        end
      end
    end
  end

  describe 'Triggers without configured action inside condition are executed differently compared to 5.3 #4550' do
    let(:ticket_match) { create(:ticket, group: Group.first) }
    let(:ticket_no_match) { create(:ticket, group: Group.first, priority: Ticket::Priority.find_by(name: '1 low')) }
    let(:condition) do
      { 'ticket.priority_id' => { 'operator' => 'is', 'value' => Ticket::Priority.where(name: ['2 normal', '3 high']).pluck(:id).map(&:to_s) } }
    end
    let(:perform) do
      { 'article.note' => { 'subject' => 'Test subject note', 'internal' => 'true', 'body' => 'Test body note' } }
    end

    shared_examples 'executing trigger when conditions match' do |execution_condition_mode:|
      it 'does not create an article if the state changes', if: execution_condition_mode == 'selective' do
        ticket_match.update(state: Ticket::State.find_by(name: 'closed'))
        expect { TransactionDispatcher.commit }.not_to change(Ticket::Article, :count)
      end

      it 'does create an article if the state changes', if: execution_condition_mode == 'always' do
        ticket_match.update(state: Ticket::State.find_by(name: 'closed'))
        expect { TransactionDispatcher.commit }.to change(Ticket::Article, :count)
      end

      it 'does create an article if priority changes' do
        ticket_match.update(priority: Ticket::Priority.find_by(name: '3 high'))
        expect { TransactionDispatcher.commit }.to change(Ticket::Article, :count).by(1)
      end

      it 'does create an article if priority matches and new article is created' do
        create(:ticket_article, ticket: ticket_match)
        expect { TransactionDispatcher.commit }.to change(Ticket::Article, :count).by(1)
      end
    end

    shared_examples "not executing trigger when conditions don't match" do
      it 'does not create an article if priority does not match but new article is created' do
        create(:ticket_article, ticket: ticket_no_match)
        expect { TransactionDispatcher.commit }.not_to change(Ticket::Article, :count)
      end

      it 'does not create an article if priority does not match and priority changes to low' do
        ticket_match.update(priority: Ticket::Priority.find_by(name: '1 low'))
        expect { TransactionDispatcher.commit }.not_to change(Ticket::Article, :count)
      end
    end

    before do
      ticket_match
      ticket_no_match
      trigger
      TransactionDispatcher.commit
    end

    context "with execution condition mode 'selective'" do
      it_behaves_like 'executing trigger when conditions match', execution_condition_mode: 'selective'
      it_behaves_like "not executing trigger when conditions don't match"
    end

    context "with execution condition mode 'always'" do
      let(:execution_condition_mode) { 'always' }

      it_behaves_like 'executing trigger when conditions match', execution_condition_mode: 'always'
      it_behaves_like "not executing trigger when conditions don't match"
    end
  end

  context 'when time events are reached', time_zone: 'Europe/London' do
    let(:activator)   { 'time' }
    let(:perform)     { { 'ticket.title' => { 'value' => 'triggered' } } }
    let(:ticket)      { create(:ticket, title: 'Test Ticket', state_name: state_name, pending_time: pending_time) }

    shared_examples 'getting triggered' do |attribute:, operator:, with_pending_time: false, with_escalation: false|
      let(:attribute)    { attribute }
      let(:condition)    { { attribute => { operator: operator } } }
      let(:state_name)   { 'pending reminder' if with_pending_time }
      let(:pending_time) { 1.hour.ago if with_pending_time }
      let(:calendar)     { create(:calendar, :'24/7') }
      let(:sla)          { create(:sla, :condition_blank, solution_time: 10, calendar: calendar) }

      before do
        sla if with_escalation
        ticket && trigger
        travel 1.hour if with_escalation
      end

      it "gets triggered for attribute: #{attribute}, operator: #{operator}" do
        expect { perform_job(attribute, operator) }
          .to change { ticket.reload.title }
          .to('triggered')
      end

      def job_type(attribute, operator)
        case [attribute, operator]
        in 'ticket.pending_time', _
          'reminder_reached'
        in 'ticket.escalation_at', 'has reached'
          'escalation'
        in 'ticket.escalation_at', 'has reached warning'
          'escalation_warning'
        end
      end

      def perform_job(...)
        TransactionJob.perform_now(
          object:     'Ticket',
          type:       job_type(...),
          object_id:  ticket.id,
          article_id: nil,
          user_id:    1,
        )
      end
    end

    it_behaves_like 'getting triggered', attribute: 'ticket.pending_time', operator: 'has reached', with_pending_time: true
    it_behaves_like 'getting triggered', attribute: 'ticket.escalation_at', operator: 'has reached', with_escalation: true
    it_behaves_like 'getting triggered', attribute: 'ticket.escalation_at', operator: 'has reached warning', with_escalation: true
  end

  context 'when aticle action is set' do
    let(:activator) { 'action' }
    let(:perform)   { { 'ticket.title' => { 'value' => 'triggered' } } }
    let(:ticket)    { create(:ticket, title: 'Test Ticket') }
    let(:article)   { create(:ticket_article, ticket: ticket) }

    shared_examples 'getting triggered' do |triggered:, operator:, with_article:, type:|
      before do
        ticket && trigger

        article if with_article
      end

      let(:article_id) { with_article ? article.id : nil }
      let(:type)       { type }
      let(:condition) do
        { 'article.action' => { 'operator' => operator, 'value' => 'create' } }
      end

      if triggered
        it "gets triggered for article action created operator: #{operator}" do
          expect { TransactionDispatcher.commit }
            .to change { ticket.reload.title }
            .to('triggered')
        end
      else
        it "does not get triggered for article action created operator: #{operator}" do
          expect { TransactionDispatcher.commit }
            .not_to change { ticket.reload.title }
        end
      end
    end

    it_behaves_like 'getting triggered', triggered: true,  operator: 'is',     with_article: true,  type: 'update'
    it_behaves_like 'getting triggered', triggered: false, operator: 'is not', with_article: true,  type: 'update'
    it_behaves_like 'getting triggered', triggered: false, operator: 'is',     with_article: false, type: 'update'
    it_behaves_like 'getting triggered', triggered: true,  operator: 'is not', with_article: false, type: 'update'

    it_behaves_like 'getting triggered', triggered: true,  operator: 'is',     with_article: true,  type: 'create'
    it_behaves_like 'getting triggered', triggered: false, operator: 'is not', with_article: true,  type: 'create'
    it_behaves_like 'getting triggered', triggered: false, operator: 'is',     with_article: false, type: 'create'
    it_behaves_like 'getting triggered', triggered: true,  operator: 'is not', with_article: false, type: 'create'
  end

  describe '#performed_on', current_user_id: 1 do
    let(:ticket) { create(:ticket) }

    before { ticket }

    context 'given action-based trigger' do
      let(:activator) { 'action' }

      it 'does nothing' do
        expect { trigger.performed_on(ticket, activator_type: 'reminder_reached') }
          .not_to change(History, :count)
      end
    end

    context 'given time-based trigger' do
      let(:activator) { 'time' }

      it 'creates history item' do
        expect { trigger.performed_on(ticket, activator_type: 'reminder_reached') }
          .to change(History, :count)
          .by(1)
      end
    end
  end

  describe 'performable_on?', current_user_id: 1 do
    let(:ticket) { create(:ticket) }

    before { ticket }

    context 'given action-based trigger' do
      let(:activator) { 'action' }

      it 'returns nil' do
        expect(trigger.performable_on?(ticket, activator_type: 'reminder_reached'))
          .to be_nil
      end
    end

    context 'given time-based trigger' do
      let(:activator) { 'time' }

      it 'returns true if it was not performed yet' do
        expect(trigger).to be_performable_on(ticket, activator_type: 'reminder_reached')
      end

      it 'returns true if it was performed yesterday' do
        travel(-1.day) do
          trigger.performed_on(ticket, activator_type: 'reminder_reached')
        end

        expect(trigger).to be_performable_on(ticket, activator_type: 'reminder_reached')
      end

      it 'returns true if it was performed today on another ticket' do
        trigger.performed_on(create(:ticket), activator_type: 'reminder_reached')

        expect(trigger).to be_performable_on(ticket, activator_type: 'reminder_reached')
      end

      it 'returns true if it was performed today by another activator' do
        trigger.performed_on(ticket, activator_type: 'escalation')

        expect(trigger).to be_performable_on(ticket, activator_type: 'reminder_reached')
      end

      it 'returns false if it was performed today on the same ticket by the same activator and same user' do
        trigger.performed_on(ticket, activator_type: 'reminder_reached')

        expect(trigger).not_to be_performable_on(ticket, activator_type: 'reminder_reached')
      end
    end
  end

  describe 'Log Trigger and Scheduler in Ticket History #4604' do
    let(:ticket) { create(:ticket) }

    context 'when title attribute' do
      it 'does create history entries for the trigger' do
        ticket && trigger
        TransactionDispatcher.commit
        expect(History.last).to have_attributes(
          o_id:       ticket.id,
          value_to:   'triggered',
          sourceable: trigger
        )
      end
    end

    context 'when group associated attribute' do
      let(:group) { create(:group) }

      let(:perform) do
        { 'ticket.group_id'=>{ 'value'=> group.id.to_s } }
      end

      it 'does create history entries with source information' do
        ticket && trigger
        TransactionDispatcher.commit
        expect(History.last).to have_attributes(
          o_id:       ticket.id,
          value_to:   group.name,
          sourceable: trigger
        )
      end
    end

    context 'when internal note article' do
      let(:perform) do
        { 'article.note' => { 'subject' => 'Test subject note', 'internal' => 'true', 'body' => 'Test body note' } }
      end

      it 'does create history entries with source information' do
        ticket && trigger
        TransactionDispatcher.commit
        expect(History.last).to have_attributes(
          o_id:         Ticket::Article.last.id,
          related_o_id: ticket.id,
          sourceable:   trigger
        )
      end
    end

    context 'when email notification article' do
      let(:perform) do
        {
          'notification.email' => {
            'recipient' => 'ticket_customer',
            'subject'   => 'foo',
            'body'      => 'some body with &gt;snip&lt;#{article.body_as_html}&gt;/snip&lt;', # rubocop:disable Lint/InterpolationCheck
          }
        }
      end

      it 'does create history entries with source information' do
        ticket && trigger
        TransactionDispatcher.commit
        expect(History.last).to have_attributes(
          o_id:         Ticket::Article.last.id,
          related_o_id: ticket.id,
          sourceable:   trigger
        )
      end
    end

    context 'when tags are added' do
      let(:tag) { SecureRandom.uuid }
      let(:perform) do
        { 'ticket.tags'=>{ 'operator' => 'add', 'value' => tag } }
      end

      it 'does create history entries with source information' do
        ticket && trigger
        TransactionDispatcher.commit
        expect(History.last).to have_attributes(
          history_type_id: History::Type.find_by(name: 'added').id,
          o_id:            ticket.id,
          sourceable:      trigger,
          value_to:        tag,
        )
      end
    end

    context 'when tags are removed' do
      let(:tag) { SecureRandom.uuid }
      let(:perform) do
        { 'ticket.tags'=>{ 'operator' => 'remove', 'value' => tag } }
      end

      it 'does create history entries with source information' do
        ticket&.tag_add(tag, 1) && trigger
        TransactionDispatcher.commit
        expect(History.last).to have_attributes(
          history_type_id: History::Type.find_by(name: 'removed').id,
          o_id:            ticket.id,
          sourceable:      trigger,
          value_to:        tag,
        )
      end
    end
  end

  describe 'Trigger fails to set custom timestamp on report #4677', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:ticket) { create(:ticket) }

    let(:perform_static) do
      { "ticket.#{field_name}" => { 'operator' => 'static', 'value' => '2023-07-18T06:00:00.000Z' } }
    end
    let(:perform_relative) do
      { "ticket.#{field_name}"=>{ 'operator' => 'relative', 'value' => '1', 'range' => 'day' } }
    end

    before do
      travel_to DateTime.new 2023, 0o7, 13, 10, 0o0
    end

    context 'when datetime' do
      before do
        create(:object_manager_attribute_datetime, object_name: 'Ticket', name: field_name, display: field_name)
        ObjectManager::Attribute.migration_execute
      end

      context 'when static' do
        let(:perform) { perform_static }

        it 'does set the value' do
          ticket && trigger
          TransactionDispatcher.commit
          expect(ticket.reload[field_name]).to eq(Time.zone.parse('2023-07-18T06:00:00.000Z'))
        end
      end

      context 'when relative' do
        let(:perform) { perform_relative }

        it 'does set the value' do
          ticket && trigger
          TransactionDispatcher.commit
          expect(ticket.reload[field_name]).to eq(1.day.from_now)
        end
      end
    end

    context 'when date' do
      before do
        create(:object_manager_attribute_date, object_name: 'Ticket', name: field_name, display: field_name)
        ObjectManager::Attribute.migration_execute
      end

      context 'when static' do
        let(:perform) { perform_static }

        it 'does set the value' do
          ticket && trigger
          TransactionDispatcher.commit
          expect(ticket.reload[field_name]).to eq(Time.zone.parse('2023-07-18'))
        end
      end

      context 'when relative' do
        let(:perform) { perform_relative }

        it 'does set the value' do
          ticket && trigger
          TransactionDispatcher.commit
          expect(ticket.reload[field_name]).to eq(1.day.from_now.to_date)
        end
      end
    end
  end

  describe 'Trigger with new regular expression operators' do
    let(:execution_condition_mode) { 'always' }

    before do
      ticket_match && ticket_no_match && trigger
      TransactionDispatcher.commit
    end

    context 'when the title is used in the conditions' do
      let(:perform) do
        { 'ticket.title'=> { 'value'=> 'Changed by trigger' } }
      end

      context 'when the operator is "matches regex"' do
        let(:ticket_match)    { create(:ticket, title: 'Welcome to Zammad') }
        let(:ticket_no_match) { create(:ticket, title: 'Spam') }

        let(:condition) do
          { 'ticket.title' => { operator: 'matches regex', value: '^welcome' } }
        end

        it 'does execute the trigger and perform changes', :aggregate_failures do
          expect(ticket_match.reload.title).to eq('Changed by trigger')
          expect(ticket_no_match.reload.title).to eq('Spam')
        end
      end

      context 'when the operator is "does not match regex"' do
        let(:ticket_no_match) { create(:ticket, title: 'Welcome to Zammad') }
        let(:ticket_match)    { create(:ticket, title: 'Spam') }

        let(:condition) do
          { 'ticket.title' => { operator: 'does not match regex', value: '^welcome' } }
        end

        it 'does not execute the trigger and perform no changes', :aggregate_failures do
          expect(ticket_no_match.reload.title).to eq('Welcome to Zammad')
          expect(ticket_match.reload.title).to eq('Changed by trigger')
        end
      end
    end
  end

  describe 'Extend trigger conditions with an article accounted time entry flag #4760' do
    let!(:ticket) { create(:ticket) }

    before do
      ticket && article && trigger
    end

    context 'when time accounting is present' do
      let!(:article) { create(:ticket_time_accounting, :for_article, ticket: ticket) }

      context 'with is set' do
        let(:condition) do
          { 'article.time_accounting'=> { 'operator' => 'is set' } }
        end

        it 'does trigger' do
          expect { TransactionDispatcher.commit }.to change { ticket.reload.title }.to('triggered')
        end
      end

      context 'with not set' do
        let(:condition) do
          { 'article.time_accounting'=> { 'operator' => 'not set' } }
        end

        it 'does not trigger' do
          expect { TransactionDispatcher.commit }.to not_change { ticket.reload.title }
        end
      end
    end

    context 'when time accounting is blank' do
      let!(:article) { create(:ticket_article, ticket: ticket) }

      context 'with is set' do
        let(:condition) do
          { 'article.time_accounting'=> { 'operator' => 'is set' } }
        end

        it 'does trigger' do
          expect { TransactionDispatcher.commit }.to not_change { ticket.reload.title }
        end
      end

      context 'with not set' do
        let(:condition) do
          { 'article.time_accounting'=> { 'operator' => 'not set' } }
        end

        it 'does not trigger' do
          expect { TransactionDispatcher.commit }.to change { ticket.reload.title }.to('triggered')
        end
      end
    end
  end

  describe 'Organization is missing when used in expert mode conditions #5483' do
    let(:conditions_orgs) { create_list(:organization, 3) }
    let(:trigger)         { create(:trigger, condition: condition) }

    context 'when old conditions' do
      let(:condition) do
        {
          'ticket.organization_id' => {
            'operator'         => 'is',
            'pre_condition'    => 'specific',
            'value'            => conditions_orgs.map { |row| row.id.to_s },
            'value_completion' => ''
          }
        }
      end

      it 'does contain assets for the conditions' do
        expect(trigger.assets({})[:Organization].keys.sort).to eq(conditions_orgs.map(&:id).sort)
      end
    end

    context 'when new conditions' do
      let(:condition) do
        Selector::Base.migrate_selector({
                                          'ticket.organization_id' => {
                                            'operator'         => 'is',
                                            'pre_condition'    => 'specific',
                                            'value'            => conditions_orgs.map { |row| row.id.to_s },
                                            'value_completion' => ''
                                          }
                                        })
      end

      it 'does contain assets for the conditions' do
        expect(trigger.assets({})[:Organization].keys.sort).to eq(conditions_orgs.map(&:id).sort)
      end
    end
  end
end
