# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket::Overviews > Sorting' do # rubocop:disable RSpec/DescribeClass
  let(:overview) do
    create(
      :overview,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value:    Ticket::State.pluck(:id),
        },
      },
    )
  end

  let(:user) { create(:agent, groups: [Group.first], preferences: { 'locale' => locale }) }

  let(:result) { Ticket::Overviews.tickets_for_overview(overview, user, order_by:, order_direction:).map(&:id) }

  before do
    Ticket.destroy_all

    user && tickets && overview
  end

  shared_examples 'it sorts correctly' do
    it 'sorts correctly' do
      expect(result).to eq(sorted_tickets.pluck(:id))
    end
  end

  context 'when sorting by state_id' do
    let(:order_by) { 'state_id' }

    let(:tickets) do
      states = Ticket::State.where(name: %w[open new closed]).map { |state| { state.name => state.id } }

      create_list(:ticket, 3, group_id: Group.first.id).tap { |tickets| states.each_with_index { |s, idx| tickets[idx].update!(state_id: s.values.first) } }
    end

    context "when language is set to 'de-de'" do
      let(:locale)         { 'de-de' }
      let(:sorted_tickets) { tickets.sort_by { |ticket| Translation.translate(locale, ticket.state.name) } }

      context 'when ascending' do
        let(:order_direction) { 'ASC' }

        it_behaves_like 'it sorts correctly'
      end

      context 'when descending' do
        let(:order_direction) { 'DESC' }
        let(:sorted_tickets)  { tickets.sort_by { |ticket| Translation.translate(locale, ticket.state.name) }.reverse }

        it_behaves_like 'it sorts correctly'
      end
    end
  end

  context 'when sorting by group_id' do
    let(:order_by)       { 'group_id' }
    let(:locale)         { 'en-us' }
    let(:sorted_tickets) { tickets.sort_by { |ticket| ticket.group.name.downcase } }

    let(:tickets) do
      groups = create_list(:group, 10).tap { |gs| gs.each { |g| g.update!(name: Faker::App.unique.name) } }
      user.update!(group_ids: Group.pluck(:id))

      create_list(:ticket, 10).tap { |tickets| tickets.each_with_index { |t, idx| t.update!(group_id: groups[idx].id) } }
    end

    context 'when ascending' do
      let(:order_direction) { 'ASC' }

      it_behaves_like 'it sorts correctly'
    end

    context 'when descending' do
      let(:order_direction) { 'DESC' }
      let(:sorted_tickets)  { tickets.sort_by { |ticket| ticket.group.name.downcase }.reverse }

      it_behaves_like 'it sorts correctly'
    end
  end

  context 'when sorting by customer_id' do
    let(:order_by)       { 'customer_id' }
    let(:locale)         { 'en-us' }

    let(:tickets) do
      groups = create_list(:group, 10).tap { |gs| gs.each { |g| g.update!(name: Faker::App.unique.name) } }
      user.update!(group_ids: Group.pluck(:id))

      create_list(:ticket, 10).tap { |tickets| tickets.each_with_index { |t, idx| t.update!(group_id: groups[idx].id) } }
    end

    context 'when ascending' do
      let(:order_direction) { 'ASC' }
      let(:sorted_tickets) { tickets.sort_by { |ticket| ticket.customer.fullname.downcase } }

      it_behaves_like 'it sorts correctly'
    end

    context 'when descending' do
      let(:order_direction) { 'DESC' }
      let(:sorted_tickets)  { tickets.sort_by { |ticket| ticket.customer.fullname.downcase }.reverse }

      it_behaves_like 'it sorts correctly'
    end
  end

  context 'when grouping and sorting' do
    let(:overview)  { super().tap { it.update! group_by: 'customer_id', group_direction: 'ASC' } }
    let(:customers) { create_list(:customer, 3) }
    let(:order_by)  { 'title' }
    let(:locale)    { 'en-us' }

    let(:tickets) do
      customers.flat_map do |customer|
        Array.new(3) do
          create(:ticket, customer:, group: Group.first, title: Faker::Lorem.sentence)
        end
      end
    end

    context 'when ascending' do
      let(:order_direction) { 'ASC' }
      let(:sorted_tickets)  do
        tickets
          .sort do |a, b|
            initial = a.customer.fullname.casecmp(b.customer.fullname)

            next initial if !initial.zero?

            a.title.casecmp(b.title)
          end
      end

      it_behaves_like 'it sorts correctly'
    end

    context 'when descending' do
      let(:order_direction) { 'DESC' }
      let(:sorted_tickets)  do
        tickets
          .sort do |a, b|
            initial = a.customer.fullname.casecmp(b.customer.fullname)

            next initial if !initial.zero?

            b.title.casecmp(a.title)
          end
      end

      it_behaves_like 'it sorts correctly'
    end

    context 'when grouping by organization_id' do
      let(:overview)        { super().tap { it.update! group_by: 'organization_id', group_direction: } }
      let(:group_direction) { 'ASC' }
      let(:customers)       { create_list(:customer, 3) + create_list(:customer, 3, :with_org) }

      def organization_compare(ticket_a, ticket_b)
        org_a = ticket_a.organization&.name
        org_b = ticket_b.organization&.name

        case [org_a.blank?, org_b.blank?]
        when [true, false], [false, true] # Ruby puts empty values at the end, SQL puts them at the top
          org_b.to_s.casecmp org_a.to_s
        else
          org_a.to_s.casecmp org_b.to_s
        end
      end

      def ticket_compare(ticket_a, ticket_b, org_direction: :same)
        org_cmp = org_direction == :same ? organization_compare(ticket_a, ticket_b) : organization_compare(ticket_b, ticket_a)

        return org_cmp if !org_cmp.zero?

        ticket_a.title.casecmp(ticket_b.title)
      end

      context 'when ascending' do
        let(:order_direction) { 'ASC' }

        context 'when group direction is ascending' do
          let(:sorted_tickets) { tickets.sort { |a, b| ticket_compare(a, b) } }

          it_behaves_like 'it sorts correctly'
        end

        context 'when group direction is descending' do
          let(:group_direction) { 'DESC' }
          let(:sorted_tickets)  { tickets.sort { |a, b| ticket_compare(a, b, org_direction: :opposite) } }

          it_behaves_like 'it sorts correctly'
        end
      end

      context 'when descending' do
        let(:order_direction) { 'DESC' }

        context 'when group direction is ascending' do
          let(:sorted_tickets) { tickets.sort { |a, b| ticket_compare(b, a, org_direction: :opposite) } }

          it_behaves_like 'it sorts correctly'
        end

        context 'when group direction is descending' do
          let(:group_direction) { 'DESC' }
          let(:sorted_tickets)  { tickets.sort { |a, b| ticket_compare(b, a) } }

          it_behaves_like 'it sorts correctly'
        end
      end
    end
  end
end
