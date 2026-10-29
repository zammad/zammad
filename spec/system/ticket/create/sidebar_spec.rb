# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Create > Sidebar', time_zone: 'Europe/London', type: :system do
  context 'when using the sidebar' do
    context 'when using a template' do
      before do
        visit 'ticket/create'
        use_template(create(:template, :dummy_data, customer: create(:customer, :with_org)))
      end

      it 'does show the edit link for the customer' do
        click '.tabsSidebar-tab[data-tab=customer]'
        click '#userAction'
        click_on 'Edit Customer'
        modal_ready
      end

      it 'does show the edit link for the organization' do
        click '.tabsSidebar-tab[data-tab=organization]'
        click '#userAction'
        click_on 'Edit Organization'
        modal_ready
      end
    end

    %w[idoit gitlab github].each do |service_name|
      it "#{service_name} tab is hidden" do
        visit 'ticket/create'

        expect(page).to have_css('.tabsSidebar-tab[data-tab="template"]')
        expect(page).to have_no_css(".tabsSidebar-tab[data-tab=#{service_name}]")
      end

      context "when #{service_name} is enabled" do
        before do
          Setting.set("#{service_name}_integration", true)
        end

        context 'when agent' do
          it "#{service_name} tab is visible" do
            visit 'ticket/create'

            expect(page).to have_css(".tabsSidebar-tab[data-tab=#{service_name}]")
          end
        end

        context 'when customer', authenticated_as: :customer do
          let(:customer) { create(:customer) }

          it "#{service_name} tab is hidden" do
            visit 'customer_ticket_new'

            expect(page).to have_field('title')
            expect(page).to have_no_css(".tabsSidebar-tab[data-tab=#{service_name}]")
          end
        end
      end
    end
  end
end
