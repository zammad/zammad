require 'rails_helper'

require 'system/examples/text_modules_examples'

RSpec.describe 'Ticket Create', type: :system do
  context 'when applying ticket templates' do
    let(:agent) { create(:agent, groups: [permitted_group]) }
    let(:permitted_group) { create(:group) }
    let(:unpermitted_group) { create(:group) }
    let!(:template) { create(:template, :dummy_data, group: unpermitted_group, owner: agent) }

    # Regression test for issue #2424 - Unavailable ticket template attributes get applied
    it 'unavailable attributes do not get applied', authenticated_as: :agent do
      visit 'ticket/create'

      use_template(template)
      expect(page).to have_no_selector 'select[name="group_id"]'
    end
  end

  context 'when using text modules' do
    include_examples 'text modules', path: 'ticket/create'
  end

  context 'S/MIME', authenticated_as: :authenticate do
    def authenticate
      Setting.set('smime_integration', true)
      Setting.set('smime_config', smime_config) if defined?(smime_config)

      current_user
    end

    context 'no certificate present' do
      let!(:template)    { create(:template, :dummy_data) }
      let(:current_user) { true }

      it 'has no security selections' do
        visit 'ticket/create'

        within(:active_content) do
          use_template(template)

          expect(page).to have_no_css('div.js-securityEncrypt.btn--active')
          expect(page).to have_no_css('div.js-securitySign.btn--active')
          click '.js-submit'

          expect(page).to have_css('.ticket-article-item', count: 1)

          open_article_meta

          expect(page).to have_no_css('span', text: 'Signed')
          expect(page).to have_no_css('span', text: 'Encrypted')

          security_result = Ticket::Article.last.preferences['security']
          expect(security_result['encryption']['success']).to be nil
          expect(security_result['sign']['success']).to be nil
        end
      end
    end

    context 'private key configured' do
      let(:current_user) { agent }
      let!(:template) { create(:template, :dummy_data, group: group, owner: agent, customer: customer) }

      let(:system_email_address) { 'smime1@example.com' }
      let(:email_address) { create(:email_address, email: system_email_address) }
      let(:group) { create(:group, email_address: email_address) }
      let(:agent_groups) { [group] }
      let(:agent) { create(:agent, groups: agent_groups) }

      before do
        create(:smime_certificate, :with_private, fixture: system_email_address)
      end

      context 'recipient certificate present' do

        let(:recipient_email_address) { 'smime2@example.com' }
        let(:customer) { create(:customer, email: recipient_email_address) }

        before do
          create(:smime_certificate, fixture: recipient_email_address)
        end

        it 'plain' do
          visit 'ticket/create'

          within(:active_content) do
            use_template(template)

            # wait till S/MIME check AJAX call is ready
            expect(page).to have_css('div.js-securityEncrypt.btn--active', wait: 5)
            expect(page).to have_css('div.js-securitySign.btn--active', wait: 5)

            # deactivate encryption and signing
            click '.js-securityEncrypt'
            click '.js-securitySign'

            click '.js-submit'

            expect(page).to have_css('.ticket-article-item', count: 1)

            open_article_meta

            expect(page).to have_no_css('span', text: 'Signed')
            expect(page).to have_no_css('span', text: 'Encrypted')

            security_result = Ticket::Article.last.preferences['security']
            expect(security_result['encryption']['success']).to be nil
            expect(security_result['sign']['success']).to be nil
          end
        end

        it 'signed' do
          visit 'ticket/create'

          within(:active_content) do
            use_template(template)

            # wait till S/MIME check AJAX call is ready
            expect(page).to have_css('div.js-securityEncrypt.btn--active', wait: 5)
            expect(page).to have_css('div.js-securitySign.btn--active', wait: 5)

            # deactivate encryption
            click '.js-securityEncrypt'

            click '.js-submit'

            expect(page).to have_css('.ticket-article-item', count: 1)

            open_article_meta

            expect(page).to have_css('span', text: 'Signed')
            expect(page).to have_no_css('span', text: 'Encrypted')

            security_result = Ticket::Article.last.preferences['security']
            expect(security_result['encryption']['success']).to be nil
            expect(security_result['sign']['success']).to be true
          end
        end

        it 'encrypted' do
          visit 'ticket/create'

          within(:active_content) do
            use_template(template)

            # wait till S/MIME check AJAX call is ready
            expect(page).to have_css('div.js-securityEncrypt.btn--active', wait: 5)
            expect(page).to have_css('div.js-securitySign.btn--active', wait: 5)

            # deactivate signing
            click '.js-securitySign'

            click '.js-submit'

            expect(page).to have_css('.ticket-article-item', count: 1)

            open_article_meta

            expect(page).to have_no_css('span', text: 'Signed')
            expect(page).to have_css('span', text: 'Encrypted')

            security_result = Ticket::Article.last.preferences['security']
            expect(security_result['encryption']['success']).to be true
            expect(security_result['sign']['success']).to be nil
          end
        end

        it 'signed and encrypted' do
          visit 'ticket/create'

          within(:active_content) do
            use_template(template)

            # wait till S/MIME check AJAX call is ready
            expect(page).to have_css('div.js-securityEncrypt.btn--active', wait: 5)
            expect(page).to have_css('div.js-securitySign.btn--active', wait: 5)

            click '.js-submit'

            expect(page).to have_css('.ticket-article-item', count: 1)

            open_article_meta

            expect(page).to have_css('span', text: 'Signed')
            expect(page).to have_css('span', text: 'Encrypted')

            security_result = Ticket::Article.last.preferences['security']
            expect(security_result['encryption']['success']).to be true
            expect(security_result['sign']['success']).to be true
          end
        end

        context 'Group default behavior' do

          let(:smime_config) { {} }

          shared_examples 'security defaults example' do |sign:, encrypt:|

            it "security defaults sign: #{sign}, encrypt: #{encrypt}" do
              within(:active_content) do
                encrypt_button = find('.js-securityEncrypt', wait: 5)
                sign_button    = find('.js-securitySign', wait: 5)

                await_empty_ajax_queue

                active_button_class = '.btn--active'
                expect(encrypt_button.matches_css?(active_button_class, wait: 2)).to be(encrypt)
                expect(sign_button.matches_css?(active_button_class, wait: 2)).to be(sign)
              end
            end
          end

          shared_examples 'security defaults' do |sign:, encrypt:|

            before do
              visit 'ticket/create'

              within(:active_content) do
                use_template(template)
              end
            end

            include_examples 'security defaults example', sign: sign, encrypt: encrypt
          end

          shared_examples 'security defaults group change' do |sign:, encrypt:|

            before do
              visit 'ticket/create'

              within(:active_content) do
                use_template(template)

                await_empty_ajax_queue

                select new_group.name, from: 'group_id'
              end
            end

            include_examples 'security defaults example', sign: sign, encrypt: encrypt
          end

          context 'not configured' do
            it_behaves_like 'security defaults', sign: true, encrypt: true
          end

          context 'configuration present' do

            let(:smime_config) do
              {
                'group_id' => group_defaults
              }
            end

            let(:group_defaults) do
              {
                'default_encryption' => {
                  group.id.to_s => default_encryption,
                },
                'default_sign'       => {
                  group.id.to_s => default_sign,
                }
              }
            end

            let(:default_sign) { true }
            let(:default_encryption) { true }

            shared_examples 'sign and encrypt variations' do |check_examples_name|

              it_behaves_like check_examples_name, sign: true, encrypt: true

              context 'no value' do
                let(:group_defaults) { {} }

                it_behaves_like check_examples_name, sign: true, encrypt: true
              end

              context 'signing disabled' do
                let(:default_sign) { false }

                it_behaves_like check_examples_name, sign: false, encrypt: true
              end

              context 'encryption disabled' do
                let(:default_encryption) { false }

                it_behaves_like check_examples_name, sign: true, encrypt: false
              end
            end

            context 'same Group' do
              it_behaves_like 'sign and encrypt variations', 'security defaults'
            end

            context 'Group change' do
              let(:new_group) { create(:group, email_address: email_address) }

              let(:agent_groups) { [group, new_group] }

              let(:group_defaults) do
                {
                  'default_encryption' => {
                    new_group.id.to_s => default_encryption,
                  },
                  'default_sign'       => {
                    new_group.id.to_s => default_sign,
                  }
                }
              end

              it_behaves_like 'sign and encrypt variations', 'security defaults group change'
            end
          end
        end
      end
    end
  end

  describe 'object manager attributes maxlength', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create :object_manager_attribute_text, name: 'maxtest', display: 'maxtest', screens: attributes_for(:required_screen), data_option: {
        'type'      => 'text',
        'maxlength' => 3,
        'null'      => true,
        'translate' => false,
        'default'   => '',
        'options'   => {},
        'relation'  => '',
      }
      ObjectManager::Attribute.migration_execute
      true
    end

    it 'checks ticket create' do
      visit 'ticket/create'
      within(:active_content) do
        fill_in 'maxtest', with: 'hellu'
        expect(page.find_field('maxtest').value).to eq('hel')
      end
    end
  end
end
