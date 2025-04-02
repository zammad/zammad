# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Customer & Organization Avatars', authenticated_as: :authenticate, type: :system do
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:customer) { create(:customer) }
  let(:ticket)   { create(:ticket, group: group, customer: customer) }
  let(:article)  { create(:ticket_article, ticket: ticket) }

  def authenticate
    ticket && article

    agent
  end

  before do
    visit "#ticket/zoom/#{ticket.id}"
  end

  context 'without organization' do
    before do
      click('.content.active .tabsSidebar-tab[data-tab="customer"]')
    end

    shared_examples 'displaying customer avatar' do |containers, vip|
      it "displays customer avatar with the crown in: #{containers}", if: vip do
        containers.each do |container|
          within "#{container} .avatar--unique" do
            expect(page).to have_css('.icon-crown')
          end
        end
      end

      it "displays customer avatar without the crown in: #{containers}", if: !vip do
        containers.each do |container|
          within "#{container} .avatar--unique" do
            expect(page).to have_no_css('.icon-crown')
          end
        end
      end
    end

    shared_examples 'not displaying organization avatar' do |container|
      it "does not display organization avatar in '#{container}'" do
        within container do
          expect(page).to have_no_css('.avatar--organization')
        end
      end
    end

    it_behaves_like 'not displaying organization avatar', '.ticketZoom-header'

    context 'with customer vip status' do
      let(:customer) { create(:customer, vip: true) }

      it_behaves_like 'displaying customer avatar', ['.ticketZoom-header', '.sidebar[data-tab="customer"]'], true
    end

    context 'without customer vip status' do
      let(:customer) { create(:customer, vip: false) }

      it_behaves_like 'displaying customer avatar', ['.ticketZoom-header', '.sidebar[data-tab="customer"]'], false
    end
  end

  context 'with organization' do
    let(:organization) { create(:organization, vip: vip_organization) }
    let(:customer)     { create(:customer, organization: organization) }

    before do
      click('.content.active .tabsSidebar-tab[data-tab="organization"]')
    end

    shared_examples 'displaying organization avatar' do |containers, active, vip|
      it "displays active organization avatar with the crown in: #{containers}", if: active && vip do
        containers.each do |container|
          within "#{container} .avatar--organization" do
            expect(page).to have_css('.icon-organization').and have_css('.icon-crown-silver')
          end
        end
      end

      it "displays active organization avatar without the crown in: #{containers}", if: active && !vip do
        containers.each do |container|
          within "#{container} .avatar--organization" do
            expect(page).to have_css('.icon-organization').and have_no_css('.icon-crown-silver')
          end
        end
      end

      it "displays inactive active organization avatar with the crown in: #{containers}", if: !active && vip do
        containers.each do |container|
          within "#{container} .avatar--organization" do
            expect(page).to have_css('.icon-inactive-organization').and have_css('.icon-crown-silver')
          end
        end
      end

      it "displays inactive organization avatar without the crown in: #{containers}", if: !active && !vip do
        containers.each do |container|
          within "#{container} .avatar--organization" do
            expect(page).to have_css('.icon-inactive-organization').and have_no_css('.icon-crown-silver')
          end
        end
      end
    end

    context 'with organization vip status' do
      let(:vip_organization) { true }

      it_behaves_like 'displaying organization avatar', ['.ticketZoom-header', '.sidebar[data-tab="organization"]'], true, true
    end

    context 'without organization vip status' do
      let(:vip_organization) { false }

      it_behaves_like 'displaying organization avatar', ['.ticketZoom-header', '.sidebar[data-tab="organization"]'], true, false
    end

    context 'with inactive organization' do
      let(:organization) { create(:organization, vip: vip_organization, active: false) }

      context 'with organization vip status' do
        let(:vip_organization) { true }

        it_behaves_like 'displaying organization avatar', ['.ticketZoom-header', '.sidebar[data-tab="organization"]'], false, true
      end

      context 'without organization vip status' do
        let(:vip_organization) { false }

        it_behaves_like 'displaying organization avatar', ['.ticketZoom-header', '.sidebar[data-tab="organization"]'], false, false
      end
    end
  end
end
