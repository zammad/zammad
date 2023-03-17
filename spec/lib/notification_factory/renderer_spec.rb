# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe NotificationFactory::Renderer do
  # rubocop:disable Lint/InterpolationCheck
  describe 'render' do
    before { @user = User.where(firstname: 'Nicole').first }

    it 'correctly renders a blank template' do
      renderer = build(:notification_factory_renderer)
      expect(renderer.render).to eq ''
    end

    context 'when rendering templates with ERB tags' do

      let(:template) { '<%% <%= "<%" %> %%>' }

      it 'ignores pre-existing ERB tags in an untrusted template' do
        renderer = build(:notification_factory_renderer, template: template)
        expect(renderer.render).to eq '<% <%= "<%" %> %%>'
      end

      it 'executes pre-existing ERB tags in a trusted template' do
        renderer = build(:notification_factory_renderer, template: template, trusted: true)
        expect(renderer.render).to eq '<% <% %%>'
      end
    end

    it 'correctly renders chained object references' do
      user = User.where(firstname: 'Nicole').first
      ticket = create(:ticket, customer: user)
      renderer = build(:notification_factory_renderer,
                       objects:  { ticket: ticket },
                       template: '#{ticket.customer.firstname.downcase}')
      expect(renderer.render).to eq 'nicole'
    end

    it 'correctly renders multiple value calls' do
      ticket = create(:ticket, customer: @user)
      renderer = build(:notification_factory_renderer,
                       objects:  { ticket: ticket },
                       template: '#{ticket.created_at.value.value.value.value.to_s.first}')
      expect(renderer.render).to eq '2'
    end

    it 'raises a StandardError when rendering a template with a broken syntax' do
      renderer = build(:notification_factory_renderer, template: 'test <% if %>', objects: {}, trusted: true)
      expect { renderer.render }.to raise_error(StandardError)
    end

    it 'raises a StandardError when rendering a template calling a non existant method' do
      renderer = build(:notification_factory_renderer, template: 'test <% Ticket.non_existant_method %>', objects: {}, trusted: true)
      expect { renderer.render }.to raise_error(StandardError)
    end

    it 'raises a StandardError when rendering a template referencing a non existant object' do
      renderer = build(:notification_factory_renderer, template: 'test <% NonExistantObject.first %>', objects: {}, trusted: true)
      expect { renderer.render }.to raise_error(StandardError)
    end

    context 'with different article variables' do

      let(:customer) { create(:customer, firstname: 'Nicole') }
      let(:ticket)   { create(:ticket, customer: customer) }
      let(:objects)  do
        last_article = nil
        last_internal_article = nil
        last_external_article = nil
        all_articles = ticket.articles

        if article.nil?
          last_article = all_articles.last
          last_internal_article = all_articles.reverse.find(&:internal?)
          last_external_article = all_articles.reverse.find { |a| !a.internal? }
        else
          last_article = article
          last_internal_article = article.internal? ? article : all_articles.reverse.find(&:internal?)
          last_external_article = article.internal? ? all_articles.reverse.find { |a| !a.internal? } : article
        end

        {
          ticket:                   ticket,
          article:                  last_article,
          last_article:             last_article,
          last_internal_article:    last_internal_article,
          last_external_article:    last_external_article,
          created_article:          article,
          created_internal_article: article&.internal? ? article : nil,
          created_external_article: article&.internal? ? nil : article,
        }
      end
      let(:renderer) do
        build(:notification_factory_renderer,
              objects:  objects,
              template: template)
      end
      let(:body)     { 'test' }
      let(:article)  { create(:ticket_article, ticket: ticket, body: body) }

      context 'with ticket.tags as template' do
        let(:template) { '#{ticket.tags}' }

        before do
          ticket.tag_add('Tag1', customer.id)
        end

        it 'correctly renders ticket tags references' do
          expect(renderer.render).to eq 'Tag1'
        end
      end

      %w[article last_article last_internal_article last_external_article
         created_article created_internal_article created_external_article].each do |tag|
        context "with #{tag}.body as template" do
          let(:template) { "\#{#{tag}.body}" }
          let(:article) do
            create(
              :ticket_article,
              ticket:   ticket,
              body:     body,
              internal: tag.match?('internal')
            )
          end

          it "renders an #{tag} body with quote" do
            expect(renderer.render).to eq "&gt; #{body}<br>"
          end
        end
      end
    end

    context 'when handling ObjectManager::Attribute usage', db_strategy: :reset do
      before do
        create_object_manager_attribute
        ObjectManager::Attribute.migration_execute
      end

      let(:renderer) do
        build(:notification_factory_renderer,
              objects:  { ticket: ticket },
              template: template)
      end

      shared_examples 'correctly rendering the attributes' do
        it 'correctly renders the attributes' do
          expect(renderer.render).to eq expected_render
        end
      end

      context 'with a simple select attribute' do
        let(:create_object_manager_attribute) do
          create(:object_manager_attribute_select, name: 'select')
        end
        let(:ticket) { create(:ticket, customer: @user, select: 'key_1') }
        let(:template)        { '#{ticket.select} _SEPERATOR_ #{ticket.select.value}' }
        let(:expected_render) { 'key_1 _SEPERATOR_ value_1' }

        it_behaves_like 'correctly rendering the attributes'
      end

      context 'with select attribute on chained user object' do
        let(:create_object_manager_attribute) do
          create(:object_manager_attribute_select,
                 object_lookup_id: ObjectLookup.by_name('User'),
                 name:             'select')
        end

        let(:user) do
          user = User.where(firstname: 'Nicole').first
          user.select = 'key_2'
          user.save
          user
        end

        let(:ticket) { create(:ticket, customer: user) }
        let(:template)        { '#{ticket.customer.select} _SEPERATOR_ #{ticket.customer.select.value}' }
        let(:expected_render) { 'key_2 _SEPERATOR_ value_2' }

        it_behaves_like 'correctly rendering the attributes'
      end

      context 'with select attribute on chained group object' do
        let(:create_object_manager_attribute) do
          create(:object_manager_attribute_select,
                 object_lookup_id: ObjectLookup.by_name('Group'),
                 name:             'select')
        end
        let(:template) { '#{ticket.group.select} _SEPERATOR_ #{ticket.group.select.value}' }
        let(:expected_render) { 'key_3 _SEPERATOR_ value_3' }

        let(:ticket) { create(:ticket, customer: @user) }

        before do
          group = ticket.group
          group.select = 'key_3'
          group.save
        end

        it_behaves_like 'correctly rendering the attributes'
      end

      context 'with select attribute on chained organization object' do
        let(:create_object_manager_attribute) do
          create(:object_manager_attribute_select,
                 object_lookup_id: ObjectLookup.by_name('Organization'),
                 name:             'select')
        end

        let(:user) do
          @user.organization.select = 'key_2'
          @user.organization.save
          @user
        end

        let(:ticket)          { create(:ticket, customer: user) }
        let(:template)        { '#{ticket.customer.organization.select} _SEPERATOR_ #{ticket.customer.organization.select.value}' }
        let(:expected_render) { 'key_2 _SEPERATOR_ value_2' }

        it_behaves_like 'correctly rendering the attributes'
      end

      context 'with multiselect', mariadb: true do
        context 'with a simple multiselect attribute' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_multiselect, name: 'multiselect')
          end
          let(:ticket) { create(:ticket, customer: @user, multiselect: ['key_1']) }
          let(:template)        { '#{ticket.multiselect} _SEPERATOR_ #{ticket.multiselect.value}' }
          let(:expected_render) { 'key_1 _SEPERATOR_ value_1' }

          it_behaves_like 'correctly rendering the attributes'
        end

        context 'with single multiselect attribute on chained user object' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_multiselect,
                   object_lookup_id: ObjectLookup.by_name('User'),
                   name:             'multiselect')
          end

          let(:user) do
            user = User.where(firstname: 'Nicole').first
            user.multiselect = ['key_2']
            user.save
            user
          end

          let(:ticket) { create(:ticket, customer: user) }
          let(:template)        { '#{ticket.customer.multiselect} _SEPERATOR_ #{ticket.customer.multiselect.value}' }
          let(:expected_render) { 'key_2 _SEPERATOR_ value_2' }

          it_behaves_like 'correctly rendering the attributes'
        end

        context 'with single multiselect attribute on chained group object' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_multiselect,
                   object_lookup_id: ObjectLookup.by_name('Group'),
                   name:             'multiselect')
          end
          let(:template) { '#{ticket.group.multiselect} _SEPERATOR_ #{ticket.group.multiselect.value}' }
          let(:expected_render) { 'key_3 _SEPERATOR_ value_3' }

          let(:ticket) { create(:ticket, customer: @user) }

          before do
            group = ticket.group
            group.multiselect = ['key_3']
            group.save
          end

          it_behaves_like 'correctly rendering the attributes'
        end

        context 'with single multiselect attribute on chained organization object' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_multiselect,
                   object_lookup_id: ObjectLookup.by_name('Organization'),
                   name:             'multiselect')
          end

          let(:user) do
            @user.organization.multiselect = ['key_2']
            @user.organization.save
            @user
          end

          let(:ticket)          { create(:ticket, customer: user) }
          let(:template)        { '#{ticket.customer.organization.multiselect} _SEPERATOR_ #{ticket.customer.organization.multiselect.value}' }
          let(:expected_render) { 'key_2 _SEPERATOR_ value_2' }

          it_behaves_like 'correctly rendering the attributes'
        end

        context 'with a multiple multiselect attribute' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_multiselect, name: 'multiselect')
          end
          let(:ticket) { create(:ticket, customer: @user, multiselect: %w[key_1 key_2]) }
          let(:template)        { '#{ticket.multiselect} _SEPERATOR_ #{ticket.multiselect.value}' }
          let(:expected_render) { 'key_1, key_2 _SEPERATOR_ value_1, value_2' }

          it_behaves_like 'correctly rendering the attributes'
        end

        context 'with multiple multiselect attribute on chained user object' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_multiselect,
                   object_lookup_id: ObjectLookup.by_name('User'),
                   name:             'multiselect')
          end

          let(:user) do
            user = User.where(firstname: 'Nicole').first
            user.multiselect = %w[key_2 key_3]
            user.save
            user
          end

          let(:ticket) { create(:ticket, customer: user) }
          let(:template)        { '#{ticket.customer.multiselect} _SEPERATOR_ #{ticket.customer.multiselect.value}' }
          let(:expected_render) { 'key_2, key_3 _SEPERATOR_ value_2, value_3' }

          it_behaves_like 'correctly rendering the attributes'
        end

        context 'with multiple multiselect attribute on chained group object' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_multiselect,
                   object_lookup_id: ObjectLookup.by_name('Group'),
                   name:             'multiselect')
          end
          let(:template) { '#{ticket.group.multiselect} _SEPERATOR_ #{ticket.group.multiselect.value}' }
          let(:expected_render) { 'key_3, key_1 _SEPERATOR_ value_3, value_1' }

          let(:ticket) { create(:ticket, customer: @user) }

          before do
            group = ticket.group
            group.multiselect = %w[key_3 key_1]
            group.save
          end

          it_behaves_like 'correctly rendering the attributes'
        end

        context 'with multiple multiselect attribute on chained organization object' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_multiselect,
                   object_lookup_id: ObjectLookup.by_name('Organization'),
                   name:             'multiselect')
          end

          let(:user) do
            @user.organization.multiselect = %w[key_2 key_1]
            @user.organization.save
            @user
          end

          let(:ticket)          { create(:ticket, customer: user) }
          let(:template)        { '#{ticket.customer.organization.multiselect} _SEPERATOR_ #{ticket.customer.organization.multiselect.value}' }
          let(:expected_render) { 'key_2, key_1 _SEPERATOR_ value_2, value_1' }

          it_behaves_like 'correctly rendering the attributes'
        end
      end

      context 'with a tree select attribute' do
        let(:create_object_manager_attribute) do
          create(:object_manager_attribute_tree_select, name: 'tree_select')
        end
        let(:ticket) { create(:ticket, customer: @user, tree_select: 'Incident::Hardware::Laptop') }
        let(:template)        { '#{ticket.tree_select} _SEPERATOR_ #{ticket.tree_select.value}' }
        let(:expected_render) { 'Incident::Hardware::Laptop _SEPERATOR_ Incident::Hardware::Laptop' }

        it_behaves_like 'correctly rendering the attributes'
      end
    end
  end
  # rubocop:enable Lint/InterpolationCheck
end
