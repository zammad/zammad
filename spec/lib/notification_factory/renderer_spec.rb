# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe NotificationFactory::Renderer do
  # rubocop:disable Lint/InterpolationCheck
  describe 'render' do
    before { @user = User.where(firstname: 'Nicole').first }

    it 'correctly renders a blank template' do
      renderer = build :notification_factory_renderer
      expect(renderer.render).to eq ''
    end

    context 'when rendering templates with ERB tags' do

      let(:template) { '<%% <%= "<%" %> %%>' }

      it 'ignores pre-existing ERB tags in an untrusted template' do
        renderer = build :notification_factory_renderer, template: template
        expect(renderer.render).to eq '<% <%= "<%" %> %%>'
      end

      it 'executes pre-existing ERB tags in a trusted template' do
        renderer = build :notification_factory_renderer, template: template, trusted: true
        expect(renderer.render).to eq '<% <% %%>'
      end
    end

    it 'correctly renders chained object references' do
      user = User.where(firstname: 'Nicole').first
      ticket = create :ticket, customer: user
      renderer = build :notification_factory_renderer,
                       objects:  { ticket: ticket },
                       template: '#{ticket.customer.firstname.downcase}'
      expect(renderer.render).to eq 'nicole'
    end

    it 'correctly renders multiple value calls' do
      ticket = create :ticket, customer: @user
      renderer = build :notification_factory_renderer,
                       objects:  { ticket: ticket },
                       template: '#{ticket.created_at.value.value.value.value.to_s.first}'
      expect(renderer.render).to eq '2'
    end

    it 'raises a StandardError when rendering a template with a broken syntax' do
      renderer = build :notification_factory_renderer, template: 'test <% if %>', objects: {}, trusted: true
      expect { renderer.render }.to raise_error(StandardError)
    end

    it 'raises a StandardError when rendering a template calling a non existant method' do
      renderer = build :notification_factory_renderer, template: 'test <% Ticket.non_existant_method %>', objects: {}, trusted: true
      expect { renderer.render }.to raise_error(StandardError)
    end

    it 'raises a StandardError when rendering a template referencing a non existant object' do
      renderer = build :notification_factory_renderer, template: 'test <% NonExistantObject.first %>', objects: {}, trusted: true
      expect { renderer.render }.to raise_error(StandardError)
    end

    context 'when handling ObjectManager::Attribute usage', db_strategy: :reset do

      it 'correctly renders simple select attributes' do
        create :object_manager_attribute_select, name: 'select'
        ObjectManager::Attribute.migration_execute

        ticket = create :ticket, customer: @user, select: 'key_1'

        renderer = build :notification_factory_renderer,
                         objects:  { ticket: ticket },
                         template: '#{ticket.select} _SEPERATOR_ #{ticket.select.value}'

        expect(renderer.render).to eq 'key_1 _SEPERATOR_ value_1'
      end

      it 'correctly renders select attributes on chained user object' do
        create :object_manager_attribute_select,
               object_lookup_id: ObjectLookup.by_name('User'),
               name:             'select'
        ObjectManager::Attribute.migration_execute

        user = User.where(firstname: 'Nicole').first
        user.select = 'key_2'
        user.save
        ticket = create :ticket, customer: user

        renderer = build :notification_factory_renderer,
                         objects:  { ticket: ticket },
                         template: '#{ticket.customer.select} _SEPERATOR_ #{ticket.customer.select.value}'

        expect(renderer.render).to eq 'key_2 _SEPERATOR_ value_2'
      end

      it 'correctly renders select attributes on chained group object' do
        create :object_manager_attribute_select,
               object_lookup_id: ObjectLookup.by_name('Group'),
               name:             'select'
        ObjectManager::Attribute.migration_execute

        ticket = create :ticket, customer: @user
        group = ticket.group
        group.select = 'key_3'
        group.save

        renderer = build :notification_factory_renderer,
                         objects:  { ticket: ticket },
                         template: '#{ticket.group.select} _SEPERATOR_ #{ticket.group.select.value}'

        expect(renderer.render).to eq 'key_3 _SEPERATOR_ value_3'
      end

      it 'correctly renders select attributes on chained organization object' do
        create :object_manager_attribute_select,
               object_lookup_id: ObjectLookup.by_name('Organization'),
               name:             'select'
        ObjectManager::Attribute.migration_execute

        @user.organization.select = 'key_2'
        @user.organization.save
        ticket = create :ticket, customer: @user

        renderer = build :notification_factory_renderer,
                         objects:  { ticket: ticket },
                         template: '#{ticket.customer.organization.select} _SEPERATOR_ #{ticket.customer.organization.select.value}'

        expect(renderer.render).to eq 'key_2 _SEPERATOR_ value_2'
      end

      it 'correctly renders tree select attributes' do
        create :object_manager_attribute_tree_select, name: 'tree_select'
        ObjectManager::Attribute.migration_execute

        ticket = create :ticket, customer: @user, tree_select: 'Incident::Hardware::Laptop'

        renderer = build :notification_factory_renderer,
                         objects:  { ticket: ticket },
                         template: '#{ticket.tree_select} _SEPERATOR_ #{ticket.tree_select.value}'

        expect(renderer.render).to eq 'Incident::Hardware::Laptop _SEPERATOR_ Incident::Hardware::Laptop'
      end
    end
  end
  # rubocop:enable Lint/InterpolationCheck
end
