# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Whatever a request names - updater, relation fields, filter ids, additional data, form data, dirty
#   fields or a stored taskbar state - nothing the user may not see is returned.
RSpec.describe 'FormUpdater authorization' do # rubocop:disable RSpec/DescribeClass
  let(:public_group)    { create(:group, name: 'Public Group') }
  let(:secret_group)    { create(:group, name: 'Secret Group') }
  let(:secret_agent)    { create(:agent, groups: [secret_group], firstname: 'SecretFirst', lastname: 'SecretLast', email: 'secret-agent@example.com', phone: '+49 111 999') }
  let(:nameless_user)   { create(:customer, firstname: '', lastname: '', email: 'nameless-secret@example.com', login: 'nameless-secret@example.com') }
  let(:secret_org)      { create(:organization, name: 'Secret Org', domain: 'secret-org.example') }
  let(:secret_calendar) { create(:calendar, name: 'Secret Calendar') }
  let(:secret_ticket)   { create(:ticket, group: secret_group, title: 'Secret title', note: 'Secret note', customer: nameless_user) }
  let(:secret_form_id)  { SecureRandom.uuid }

  let(:secrets) do
    ['SecretFirst', 'secret-agent@example.com', '+49 111 999', 'nameless-secret@example.com', 'Secret Org', 'secret-org.example',
     'Secret Group', 'Secret Calendar', 'Secret title', 'Secret note', 'secret-attachment.png']
  end

  let(:relation_fields) do
    ids = [secret_agent.id, nameless_user.id, secret_group.id, secret_calendar.id]

    [
      { name: 'owner_id', relation: 'User', filter_ids: ids },
      { name: 'group_id', relation: 'Group', filter_ids: ids },
      { name: 'calendar_id', relation: 'Calendar', filter_ids: ids },
      { name: 'other_owner_id', relation: 'Owner', filter_ids: ids },
      { name: 'other_group_id', relation: 'Group', filter_ids: ids },
    ]
  end

  let(:taskbar) do
    create(:taskbar, key: 'TicketCreateScreen-authorization', callback: 'TicketCreate', user_id: current_user.id,
                     state: { 'customer_id' => nameless_user.id, 'owner_id' => secret_agent.id, 'organization_id' => secret_org.id, 'form_id' => secret_form_id })
  end

  let(:meta) do
    {
      initial:         true,
      form_id:         SecureRandom.uuid,
      dirty_fields:    %w[title note owner_id customer_id organization_id group_id time_unit],
      additional_data: {
        'customer_id'              => secret_agent.id,
        'taskbarId'                => Gql::ZammadSchema.id_from_object(taskbar),
        'applyTaskbarState'        => true,
        'entity'                   => 'Ticket',
        'filterAutocompleteFields' => [
          { 'name' => 'ticket.customer_id', 'autocompleteFilterType' => 'customer' },
          { 'name' => 'ticket.organization_id', 'autocompleteFilterType' => 'organization' },
        ],
      },
    }
  end

  let(:data) do
    {
      'id'              => secret_ticket.id,
      'ticket_ids'      => secret_ticket.id.to_s,
      'title'           => 'Changed',
      'note'            => 'Changed',
      'customer_id'     => secret_agent.id,
      'owner_id'        => secret_agent.id,
      'organization_id' => secret_org.id,
      'group_id'        => secret_group.id,
      'filters'         => [
        { 'name' => 'ticket.customer_id', 'value' => [secret_agent.id, nameless_user.id] },
        { 'name' => 'ticket.organization_id', 'value' => [secret_org.id] },
      ],
    }
  end

  before do
    Setting.set('customer_ticket_create_group_ids', [public_group.id])
    create(:store, object: 'UploadCache', o_id: secret_form_id, filename: 'secret-attachment.png', created_by_id: secret_agent.id)
  end

  # The output of one updater, run as the current user like a GraphQL request; an updater that
  #   refuses the request returns nothing.
  def output_of(updater_class, id:)
    UserInfo.with_user_id(current_user.id) do
      updater = updater_class.new(context: { current_user: }, relation_fields:, meta: meta.deep_dup, data: data.deep_dup, id:)
      next if !updater.authorized?

      updater.resolve.to_json
    end
  rescue Exceptions::Forbidden, ActiveRecord::RecordNotFound
    nil
  end

  # An updater only gets ids of the type it works on, and one without an object none at all.
  def ids_for(updater_class)
    return [] if updater_class.instance_method(:object_type).owner == FormUpdater::Updater

    object_type = updater_class.allocate.object_type
    return [] if object_type.nil?

    objects.grep(object_type).map { |object| Gql::ZammadSchema.id_from_object(object) }
  end

  shared_examples 'returning nothing the user may not see' do
    it 'returns nothing the user may not see', :aggregate_failures do
      FormUpdater::Updater.updaters.each do |updater_class|
        [nil, *ids_for(updater_class)].each do |id|
          output = output_of(updater_class, id:)
          next if output.nil?

          secrets.each do |secret|
            expect(output).not_to include(secret), "#{updater_class} (id: #{id.inspect}) returned #{secret.inspect}"
          end
        end
      end
    end
  end

  context 'with a customer' do
    let(:organization) { create(:organization) }
    let(:current_user) { create(:customer, organization:) }
    let(:own_ticket)   { create(:ticket, group: public_group, customer: current_user, owner: secret_agent, note: 'Secret note') }
    let(:objects)      { [own_ticket, current_user, organization] }

    before { own_ticket.update_columns(time_unit: 42) }

    include_examples 'returning nothing the user may not see'
  end

  context 'with an agent without access to the secret group' do
    let(:current_user) { create(:agent, groups: [public_group]) }
    let(:objects)      { [secret_ticket] }

    # Agents may see every user, organization and group.
    let(:secrets) { ['Secret Calendar', 'Secret title', 'Secret note', 'secret-attachment.png'] }

    include_examples 'returning nothing the user may not see'
  end

  it 'has every updater declare who may use it' do
    FormUpdater::Updater.updaters.each do |updater_class|
      expect { updater_class.required_permissions }.not_to raise_error, "#{updater_class} declares no required permissions"
    end
  end

  it 'has every relation declare what the user may see' do
    relation_classes = FormUpdater::Relation.descendants - [FormUpdater::Relation::KnowledgeBaseEditorCategory]

    relation_classes.each do |relation_class|
      expect(relation_class.instance_method(:allowed_scope).owner).not_to eq(FormUpdater::Relation), "#{relation_class} declares no allowed scope"
    end
  end
end
