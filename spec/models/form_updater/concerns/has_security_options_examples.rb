# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::HasSecurityOptions' do |type:|
  context 'with security options' do
    let(:base_data) do
      case type
      when 'create'
        {
          'articleSenderType' => 'email-out',
        }
      when 'edit'
        {
          'article' => {
            'articleType' => 'email',
          },
        }
      end
    end
    let(:data) { base_data }

    before do
      Setting.set('smime_integration', true)
      Setting.set('smime_config', smime_config) if defined?(smime_config)
    end

    shared_examples 'resolving security field' do |expected_result:|
      it 'resolves security field' do
        result = resolved_result.resolve[:fields]

        expect(result['security']).to include(expected_result)
      end
    end

    shared_examples 'not resolving security field' do
      it 'does not resolve security field' do
        result = resolved_result.resolve[:fields]

        expect(result['security']).to be_nil
      end
    end

    it_behaves_like 'resolving security field', expected_result: {
      securityAllowed:        { 'SMIME' => [] },
      securityDefaultOptions: { 'SMIME' => [] },
      value:                  { 'method' => 'SMIME', 'options' => [] },
    }

    context 'when PGP is activated as well' do
      before do
        Setting.set('pgp_integration', true)
      end

      security_messages =
        {
          'PGP'   => { 'encryption' => { message: 'There was no recipient found.', messagePlaceholder: [] }, 'sign' => { message: 'There was no PGP key found.', messagePlaceholder: [] } },
          'SMIME' => { 'encryption' => { message: 'There was no recipient found.', messagePlaceholder: [] }, 'sign' => { message: 'There was no certificate found.', messagePlaceholder: [] } }
        }

      it_behaves_like 'resolving security field', expected_result: {
        securityAllowed:        { 'SMIME' => [], 'PGP' => [] },
        securityDefaultOptions: { 'SMIME' => [], 'PGP' => [] },
        value:                  { 'method' => 'SMIME', 'options' => [] },
        securityMessages:       security_messages,
      }
    end

    context 'when secure mailing is not configured' do
      before do
        Setting.set('smime_integration', false)
      end

      it_behaves_like 'not resolving security field'
    end

    context 'without article type present' do
      let(:data) do
        base_data.tap do |data|
          case type
          when 'create'
            data.delete('articleSenderType')
          when 'edit'
            data['article'].delete('articleType')
          end
        end
      end

      it_behaves_like 'not resolving security field'
    end

    context 'with phone article type present' do
      let(:data) do
        base_data.tap do |data|
          case type
          when 'create'
            data['articleSenderType'] = 'phone-out'
          when 'edit'
            data['article']['articleType'] = 'phone'
          end
        end
      end

      it_behaves_like 'not resolving security field'
    end

    context 'when user has no agent permission' do
      let(:user) { create(:customer, groups: [group]) }

      it_behaves_like 'not resolving security field'
    end

    context 'with recipient present' do
      let(:recipient_email_address) { 'smime2@example.com' }
      let(:customer)                { create(:customer, email: recipient_email_address) }
      let(:data)                    do
        base_data.tap do |data|
          case type
          when 'create'
            data['customer_id'] = customer.id.to_s
          when 'edit'
            data['article']['to'] = [customer.email]
          end
        end
      end

      it_behaves_like 'resolving security field', expected_result: {
        securityAllowed:        { 'SMIME' => [] },
        securityDefaultOptions: { 'SMIME' => [] },
        value:                  { 'method' => 'SMIME', 'options' => [] },
        securityMessages:       { 'SMIME'=>{ 'encryption' => { message: 'The certificate for smime2@example.com was not found.', messagePlaceholder: [] }, 'sign' => { message: 'There was no certificate found.', messagePlaceholder: [] } } }
      }

      context 'with recipient certificate present' do
        before do
          create(:smime_certificate, fixture: recipient_email_address)
        end

        it_behaves_like 'resolving security field', expected_result: {
          securityAllowed:        { 'SMIME' => ['encryption'] },
          securityDefaultOptions: { 'SMIME' => ['encryption'] },
          value:                  { 'method' => 'SMIME', 'options' => ['encryption'] },
          securityMessages:       { 'SMIME' => { 'encryption' => { message: 'The certificates for %s were found.', messagePlaceholder: ['smime2@example.com'] }, 'sign' => { message: 'There was no certificate found.', messagePlaceholder: [] } } }
        }
      end
    end

    context 'with additional recipient present' do
      let(:recipient_email_address) { 'smime3@example.com' }
      let(:data) do
        base_data.tap do |data|
          case type
          when 'create'
            data['cc'] = [recipient_email_address]
          when 'edit'
            data['article']['cc'] = [recipient_email_address]
          end
        end
      end

      it_behaves_like 'resolving security field', expected_result: {
        securityAllowed:        { 'SMIME' => [] },
        securityDefaultOptions: { 'SMIME' => [] },
        value:                  { 'method' => 'SMIME', 'options' => [] },
      }

      context 'with recipient certificate present' do
        before do
          create(:smime_certificate, fixture: recipient_email_address)
        end

        it_behaves_like 'resolving security field', expected_result: {
          securityAllowed:        { 'SMIME'=>['encryption'] },
          securityDefaultOptions: { 'SMIME' => ['encryption'] },
          value:                  { 'method' => 'SMIME', 'options' => ['encryption'] },
        }
      end

      context 'when email address is invalid' do
        let(:recipient_email_address) { 'invalid-email-address' }

        it_behaves_like 'resolving security field', expected_result: {
          securityAllowed:        { 'SMIME' => [] },
          securityDefaultOptions: { 'SMIME' => [] },
          value:                  { 'method' => 'SMIME', 'options' => [] },
        }
      end
    end

    context 'with both recipient and additional recipient present' do
      let(:recipient_email_address1) { 'smime2@example.com' }
      let(:recipient_email_address2) { 'smime3@example.com' }
      let(:customer)                 { create(:customer, email: recipient_email_address1) }
      let(:data) do
        base_data.tap do |data|
          case type
          when 'create'
            data['customer_id'] = customer.id.to_s
            data['cc'] = [recipient_email_address2]
          when 'edit'
            data['article']['to'] = [customer.email]
            data['article']['cc'] = [recipient_email_address2]
          end
        end
      end

      it_behaves_like 'resolving security field', expected_result: {
        securityAllowed:        { 'SMIME' => [] },
        securityDefaultOptions: { 'SMIME' => [] },
        value:                  { 'method' => 'SMIME', 'options' => [] },
      }

      context 'with only one recipient certificate present' do
        before do
          create(:smime_certificate, fixture: recipient_email_address1)
        end

        it_behaves_like 'resolving security field', expected_result: {
          securityAllowed:        { 'SMIME' => [] },
          securityDefaultOptions: { 'SMIME' => [] },
          value:                  { 'method' => 'SMIME', 'options' => [] },
        }
      end

      context 'with both recipient certificates present' do
        before do
          create(:smime_certificate, fixture: recipient_email_address1)
          create(:smime_certificate, fixture: recipient_email_address2)
        end

        it_behaves_like 'resolving security field', expected_result: {
          securityAllowed:        { 'SMIME' => ['encryption'] },
          securityDefaultOptions: { 'SMIME' => ['encryption'] },
          value:                  { 'method' => 'SMIME', 'options' => ['encryption'] },
        }
      end
    end

    context 'with group present' do
      let(:data) { base_data.tap { |data| data['group_id'] = group.id } }

      it_behaves_like 'resolving security field', expected_result: {
        securityAllowed:        { 'SMIME' => [] },
        securityDefaultOptions: { 'SMIME' => [] },
        value:                  { 'method' => 'SMIME', 'options' => [] },
      }

      context 'when the group has a configured sender address' do
        let(:system_email_address) { 'smime1@example.com' }
        let(:email_address)        { create(:email_address, email: system_email_address) }
        let(:group)                { create(:group, email_address: email_address) }

        it_behaves_like 'resolving security field', expected_result: {
          securityAllowed:        { 'SMIME' => [] },
          securityDefaultOptions: { 'SMIME' => [] },
          value:                  { 'method' => 'SMIME', 'options' => [] },
        }

        context 'with sender certificate present' do
          before do
            create(:smime_certificate, :with_private, fixture: system_email_address)
          end

          it_behaves_like 'resolving security field', expected_result: {
            securityAllowed:        { 'SMIME'=>['sign'] },
            securityDefaultOptions: { 'SMIME' => ['sign'] },
            value:                  { 'method' => 'SMIME', 'options' => ['sign'] },
          }
        end
      end
    end

    context 'with recipient and group present' do
      let(:recipient_email_address) { 'smime2@example.com' }
      let(:system_email_address)    { 'smime1@example.com' }
      let(:customer)                { create(:customer, email: recipient_email_address) }
      let(:email_address)           { create(:email_address, email: system_email_address) }
      let(:group)                   { create(:group, email_address: email_address) }
      let(:data) do
        base_data.tap do |data|
          case type
          when 'create'
            data['customer_id'] = customer.id.to_s
            data['group_id'] = group.id
          when 'edit'
            data['article']['to'] = [customer.email]
            data['group_id'] = group.id
          end
        end
      end

      it_behaves_like 'resolving security field', expected_result: {
        securityAllowed:        { 'SMIME' => [] },
        securityDefaultOptions: { 'SMIME' => [] },
        value:                  { 'method' => 'SMIME', 'options' => [] },
      }

      context 'with recipient and sender certificates present' do
        before do
          create(:smime_certificate, fixture: recipient_email_address)
          create(:smime_certificate, :with_private, fixture: system_email_address)
        end

        it_behaves_like 'resolving security field', expected_result: {
          securityAllowed:        { 'SMIME' => %w[sign encryption] },
          securityDefaultOptions: { 'SMIME' => %w[sign encryption] },
          value:                  { 'method' => 'SMIME', 'options' => %w[sign encryption] },
        }

        context 'with default group configuration' do
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
          let(:default_encryption) { true }
          let(:default_sign)       { true }

          it_behaves_like 'resolving security field', expected_result: {
            securityDefaultOptions: { 'SMIME' => %w[sign encryption] },
            value:                  { 'method' => 'SMIME', 'options' => %w[sign encryption] }
          }

          context 'when it has no value' do
            let(:group_defaults) { {} }

            it_behaves_like 'resolving security field', expected_result: {
              securityDefaultOptions: { 'SMIME' => %w[sign encryption] },
              value:                  { 'method' => 'SMIME', 'options' => %w[sign encryption] },
            }
          end

          context 'when encryption is disabled' do
            let(:default_encryption) { false }

            it_behaves_like 'resolving security field', expected_result: {
              securityDefaultOptions: { 'SMIME' => ['sign'] },
              value:                  { 'method' => 'SMIME', 'options' => ['sign'] },
            }
          end

          context 'when signing is disabled' do
            let(:default_sign) { false }

            it_behaves_like 'resolving security field', expected_result: {
              securityDefaultOptions: { 'SMIME' => ['encryption'] },
              value:                  { 'method' => 'SMIME', 'options' => ['encryption'] },
            }
          end

          context 'when both encryption and signing are disabled' do
            let(:default_encryption) { false }
            let(:default_sign)       { false }

            it_behaves_like 'resolving security field', expected_result: {
              securityDefaultOptions: { 'SMIME' => [] },
              value:                  { 'method' => 'SMIME', 'options' => [] },
            }
          end
        end
      end
    end
  end
end
