# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::AppliesTicketTemplate' do
  context 'when applying a ticket template' do

    let(:object_name)           { 'ticket' }
    let(:field_name)            { 'title' }
    let(:field_template_config) { { 'value' => 'test' } }
    let(:field_result)          { { value: 'test' } }
    let(:template)              { create(:template, options: { "#{object_name}.#{field_name}" => field_template_config }) }
    let(:dirty_fields)          { [] }
    let(:additional_data)       { { 'templateId' => Gql::ZammadSchema.id_from_object(template) } }
    let(:meta)                  { { additional_data:, dirty_fields: } }

    shared_examples 'skips the field' do
      it 'skips the field' do
        expect(resolved_result.resolve[:fields][field_name]).not_to have_key(:value)
      end
    end

    shared_examples 'sets the template value for the field' do
      it 'sets the template value for the field' do
        expect(resolved_result.resolve[:fields][field_name]).to include(field_result)
      end
    end

    context 'without a template to be applied' do
      let(:additional_data) { {} }

      include_examples 'skips the field'
    end

    context 'with a template to be applied' do

      context 'when the field is dirty and has a value' do
        let(:data)         { { field_name => 'previous value' } }
        let(:dirty_fields) { [field_name] }

        include_examples 'skips the field'
      end

      context 'when a value is present, but the field is not marked as dirty' do
        let(:data) { { field_name: 'already present' } }

        include_examples 'sets the template value for the field'
      end

      context 'with simple fields' do
        include_examples 'sets the template value for the field'
      end

      context 'with tags field' do
        let(:data)                  { { 'tags' => %w[tag2 tag3] } }
        let(:field_name)            { 'tags' }
        let(:field_template_config) { { 'value' => 'tag1, tag2', 'operator' => operator } }

        context 'when adding tags' do
          let(:operator) { 'add' }

          context 'when tags field is not dirty' do
            # replace field content
            let(:field_result) { { value: %w[tag1 tag2] } }

            include_examples 'sets the template value for the field'
          end

          context 'when tags field is dirty' do
            let(:dirty_fields) { ['tags'] }
            # merge field content
            let(:field_result) { { value: %w[tag2 tag3 tag1] } }

            include_examples 'sets the template value for the field'
          end
        end

        context 'when removing tags' do
          let(:operator) { 'remove' }
          let(:field_result) { { value: ['tag3'] } }

          include_examples 'sets the template value for the field'
        end

      end

      context 'with user autocomplete fields' do
        let(:search_user)           { create(:user, organization: create(:organization)) }
        let(:object_attribute)      { create(:object_manager_attribute_user_autocompletion) }
        let(:field_name)            { object_attribute.name }
        let(:field_template_config) { { 'value' => search_user.id, 'value_completion' => search_user.fullname } }
        let(:field_result) do
          {
            value:   search_user.id,
            options: [{
              value:   search_user.id,
              label:   search_user.fullname,
              heading: search_user.organization.name,
              object:  search_user.attributes
                        .slice('active', 'email', 'firstname', 'fullname', 'image', 'lastname', 'mobile', 'out_of_office', 'out_of_office_end_at', 'out_of_office_start_at', 'phone', 'source', 'vip')
                        .merge({
                                 '__typename' => 'User',
                                 'id'         => Gql::ZammadSchema.id_from_internal_id('User', search_user.id),
                               })

            }]
          }
        end

        include_examples 'sets the template value for the field'
      end

      context 'with recipient autocomplete fields' do
        let(:search_user)           { create(:user) }
        let(:object_name)           { 'article' }
        let(:field_name)            { 'cc' }
        let(:field_template_config) { { 'value' => search_user.email } }
        let(:field_result) do
          {
            value:   [search_user.email],
            options: [{ value: search_user.email, label: search_user.email, heading: search_user.fullname }]
          }
        end

        include_examples 'sets the template value for the field'

        context 'with unknown email' do
          let(:search_user)           { 'dummy@non-existing.com' }
          let(:field_template_config) { { 'value' => search_user } }
          let(:field_result) do
            {
              value:   [search_user],
              options: [{ value: search_user, label: search_user }]
            }
          end

          include_examples 'sets the template value for the field'
        end

        context 'with multiple recipients' do
          let(:recipient_user)        { create(:user) }
          let(:recipient_email)       { 'dummy@non-existing.com' }
          let(:field_template_config) { { 'value' => "#{recipient_user.email}, #{recipient_email}" } }
          let(:field_result) do
            {
              value:   [recipient_user.email, recipient_email],
              options: [
                { value: recipient_user.email, label: recipient_user.email, heading: recipient_user.fullname },
                { value: recipient_email, label: recipient_email },
              ],
            }
          end

          include_examples 'sets the template value for the field'
        end
      end

      context 'with organization autocomplete fields' do
        let(:search_organization)   { create(:organization) }
        let(:object_attribute)      { create(:object_manager_attribute_organization_autocompletion) }
        let(:field_name)            { object_attribute.name }
        let(:field_template_config) { { 'value' => search_organization.id.to_s, 'value_completion' => search_organization.name } }
        let(:field_result) do
          {
            value:   search_organization.id,
            options: [{ value: search_organization.id, label: search_organization.name }]
          }
        end

        include_examples 'sets the template value for the field'
      end

      context 'with date fields' do
        let(:object_attribute)      { create(:object_manager_attribute_date) }
        let(:field_name)            { object_attribute.name }

        context 'with fixed value' do
          let(:field_template_config) { { 'value' => '2024-01-01', 'operator' => 'static' } }
          let(:field_result) { { value: '2024-01-01' } }

          include_examples 'sets the template value for the field'
        end

        context 'with relative value' do
          before do
            travel_to(DateTime.parse('2024-01-01 00:00:00 UTC'))
          end

          let(:field_template_config) { { 'value' => '1', 'operator' => 'relative', 'range' => 'month' } }
          let(:field_result) { { value: '2024-02-01' } }

          include_examples 'sets the template value for the field'
        end
      end

      context 'with datetime fields' do
        let(:object_attribute)      { create(:object_manager_attribute_datetime) }
        let(:field_name)            { object_attribute.name }

        context 'with fixed value' do
          let(:field_template_config) { { 'value' => '2024-01-01T00:00:00Z', 'operator' => 'static' } }
          let(:field_result) { { value: '2024-01-01T00:00:00Z' } }

          include_examples 'sets the template value for the field'
        end

        context 'with relative value' do
          before do
            travel_to(DateTime.parse('2024-01-01 00:00:00 UTC'))
          end

          let(:field_template_config) { { 'value' => '1', 'operator' => 'relative', 'range' => 'month' } }
          let(:field_result) { { value: '2024-02-01T00:00:00Z' } }

          include_examples 'sets the template value for the field'
        end
      end

      context 'with group and owner fields' do
        let(:group)    { create(:group, name: 'Example 1') }
        let(:user)     { create(:agent, groups: [group]) }
        let(:context)  { { current_user: user } }
        let(:template) { create(:template, options: { 'ticket.group_id' => { 'value' => group.id.to_s }, 'ticket.owner_id' => { 'value' => user.id.to_s } }) }

        it 'sets the template value for both fields', :aggregate_failures do
          expect(resolved_result.resolve[:fields]['group_id']).to include(value: group.id)
          expect(resolved_result.resolve[:fields]['owner_id']).to include(value: user.id)
        end
      end
    end
  end
end
