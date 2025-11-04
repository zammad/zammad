# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

    describe 'escaping' do
      let(:ticket) { create(:ticket, title: '< + some % special " characters') }
      let(:objects)    { { ticket: ticket } }
      let(:renderer)   { build(:notification_factory_renderer, objects: objects, template: template, escape: escape, url_encode: url_encode) }
      let(:escape)     { false }
      let(:url_encode) { false }
      let(:template)   { 'embedded #{ ticket.title } value' }

      context 'without escaping' do
        it 'renders correctly' do
          expect(renderer.render).to eq "embedded #{ticket.title} value"
        end
      end

      context 'with HTML escaping' do
        let(:escape) { true }

        it 'renders correctly' do
          expect(renderer.render).to eq 'embedded &lt; + some % special &quot; characters value'
        end
      end

      context 'with link encoding' do
        let(:url_encode) { true }

        it 'renders correctly' do
          expect(renderer.render).to eq 'embedded %3C%20%2B%20some%20%25%20special%20%22%20characters value'
        end
      end
    end

    describe 'interpolation error handling' do
      let(:renderer)   { build(:notification_factory_renderer, objects: {}, template: template) }
      let(:template)   { '#{ ticket.title }' }

      context 'with debug_errors' do
        it 'renders an debug message' do
          expect(renderer.render).to eq "\#{ticket / no such object}"
        end
      end

      context 'without debug_errors' do
        it 'renders a dash' do
          expect(renderer.render(debug_errors: false)).to eq '-'
        end
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

          context 'with links' do
            context 'with &amp;' do
              let(:body) { "This is an example\nhttps://example.com/?query=foo&amp;query2=bar" }

              it "renders an #{tag} body with working links" do
                expect(renderer.render).to eq '&gt; This is an example<br>&gt; https://example.com/?query=foo&amp;query2=bar<br>'
              end
            end

            context 'with &' do
              let(:body) { "This is an example\nhttps://example.com/?query=foo&query2=bar" }

              it "renders an #{tag} body with working links" do
                expect(renderer.render).to eq '&gt; This is an example<br>&gt; https://example.com/?query=foo&amp;query2=bar<br>'
              end
            end
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
        let(:ticket)          { create(:ticket, customer: @user, select: 'key_1') }
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

      context 'with multiselect' do
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

        context 'with select (custom sorted) attribute on chained group object' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_select,
                   object_lookup_id:    ObjectLookup.by_name('Group'),
                   name:                'select',
                   data_option_options: [{ name: 'value_1', value: 'key_1' }, { name: 'value_2', value: 'key_2' }, { name: 'value_3', value: 'key_3' }])
          end
          let(:template)        { '#{ticket.group.select} _SEPERATOR_ #{ticket.group.select.value}' }
          let(:expected_render) { 'key_3 _SEPERATOR_ value_3' }

          let(:ticket) { create(:ticket, customer: @user) }

          before do
            group = ticket.group
            group.select = 'key_3'
            group.save
          end

          it_behaves_like 'correctly rendering the attributes'
        end

        context 'with multiple multiselect (custom sorted) attribute on chained group object' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_multiselect,
                   object_lookup_id:    ObjectLookup.by_name('Group'),
                   name:                'multiselect',
                   data_option_options: [{ name: 'value_1', value: 'key_1' }, { name: 'value_2', value: 'key_2' }, { name: 'value_3', value: 'key_3' }])
          end
          let(:template)        { '#{ticket.group.multiselect} _SEPERATOR_ #{ticket.group.multiselect.value}' }
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

        context 'with external data source attribute on chained group object' do
          let(:create_object_manager_attribute) do
            create(:object_manager_attribute_autocompletion_ajax_external_data_source,
                   object_lookup_id: ObjectLookup.by_name('Group'),
                   name:             'external_data_source')
          end
          let(:template)        { '#{ticket.group.external_data_source} _SEPERATOR_ #{ticket.group.external_data_source.value}' }
          let(:expected_render) { '1234 _SEPERATOR_ Example' }

          let(:ticket) { create(:ticket, customer: @user) }

          before do
            group = ticket.group
            group.external_data_source = {
              value: 1234,
              label: 'Example'
            }
            group.save
          end

          it_behaves_like 'correctly rendering the attributes'
        end
      end

      context 'with a tree select attribute' do
        let(:create_object_manager_attribute) do
          create(:object_manager_attribute_tree_select, name: 'tree_select')
        end
        let(:ticket)          { create(:ticket, customer: @user, tree_select: 'Incident::Hardware::Laptop') }
        let(:template)        { '#{ticket.tree_select} _SEPERATOR_ #{ticket.tree_select.value}' }
        let(:expected_render) { 'Incident::Hardware::Laptop _SEPERATOR_ Incident::Hardware::Laptop' }

        it_behaves_like 'correctly rendering the attributes'
      end

      context 'with a textarea attribute' do
        let(:create_object_manager_attribute) do
          create(:object_manager_attribute_textarea, name: 'textarea')
          create(:object_manager_attribute_textarea, name: 'textarea_empty')
        end
        let(:ticket)          { create(:ticket, customer: @user, textarea: "Line 1\nLine 2\nLine 3", textarea_empty: nil) }
        let(:template)        { '#{ticket.textarea} _SEPERATOR_ #{ticket.textarea.value} _SEPERATOR_ #{ticket.textarea_empty} _SEPERATOR_ #{ticket.textarea_empty.value}' }
        let(:expected_render) { 'Line 1<br>Line 2<br>Line 3 _SEPERATOR_ Line 1<br>Line 2<br>Line 3 _SEPERATOR_  _SEPERATOR_ ' }

        it_behaves_like 'correctly rendering the attributes'
      end
    end

    context 'when variables for not given objects should be ignored' do
      let(:ticket) { create(:ticket, customer: @user) }
      let(:user)            { create(:user, firstname: 'Max') }
      let(:template)        { '#{user.firstname} _SEPERATOR_ #{ticket.customer.lastname}' }
      let(:expected_render) { 'Nicole _SEPERATOR_ ' }

      it 'correctly renders variables for given object reference' do
        renderer = build(:notification_factory_renderer,
                         objects:                { user: },
                         template:,
                         ignore_missing_objects: true)
        expect(renderer.render).to eq 'Max _SEPERATOR_ #{ticket.customer.lastname}'
      end
    end
  end
  # rubocop:enable Lint/InterpolationCheck

  context 'with user avatar' do
    let(:base64_img) { 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' }
    let(:decoded_img) { Base64.decode64(base64_img) }
    let(:mime_type)   { 'image/png' }

    let(:avatar) do
      Avatar.add(
        object:        'User',
        o_id:          owner.id,
        full:          {
          content:   decoded_img,
          mime_type: mime_type,
        },
        resize:        {
          content:   decoded_img,
          mime_type: mime_type,
        },
        source:        "upload #{Time.zone.now}",
        deletable:     true,
        created_by_id: owner.id,
        updated_by_id: owner.id,
      )
    end

    let(:owner)  { create(:user, group_ids: Group.pluck(:id)) }
    let(:ticket) { create(:ticket, owner: owner, group: Group.first) }

    context 'with an avatar' do
      before do
        owner.update!(image: avatar.store_hash)
      end

      it 'returns a <img> tag' do
        renderer = build(:notification_factory_renderer, template: 'Avatar test #{ticket.owner.avatar(150, 150)}', objects: { ticket: ticket }, trusted: true) # rubocop:disable Lint/InterpolationCheck

        expect(renderer.render).to eq "Avatar test <img src='data:#{mime_type};base64,#{base64_img}' width='150' height='150' />"
      end
    end

    context 'without an avatar' do
      it 'returns empty string' do
        renderer = build(:notification_factory_renderer, template: 'Avatar test #{ticket.owner.avatar(150, 150)}', objects: { ticket: ticket }, trusted: true) # rubocop:disable Lint/InterpolationCheck

        expect(renderer.render).to eq 'Avatar test '
      end
    end
  end
end
