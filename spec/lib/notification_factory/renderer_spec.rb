# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
          first_article:            all_articles.first,
          first_internal_article:   all_articles.find(&:internal?),
          first_external_article:   all_articles.find { |a| !a.internal? },
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

      context 'with first_article.body as template' do
        let(:template) { '#{first_article.body}' }

        before do
          create(:ticket_article, ticket: ticket, body: 'older', internal: false)
          create(:ticket_article, ticket: ticket, body: 'newer', internal: true)
        end

        it 'renders the very first article body' do
          expect(renderer.render).to eq '&gt; older<br>'
        end
      end

      context 'with first_internal_article.body as template' do
        let(:template) { '#{first_internal_article.body}' }

        before do
          create(:ticket_article, ticket: ticket, body: 'external', internal: false)
          create(:ticket_article, ticket: ticket, body: 'internal1', internal: true)
          create(:ticket_article, ticket: ticket, body: 'internal2', internal: true)
        end

        it 'renders the first internal article body' do
          expect(renderer.render).to eq '&gt; internal1<br>'
        end
      end

      context 'with first_external_article.body as template' do
        let(:template) { '#{first_external_article.body}' }

        before do
          create(:ticket_article, ticket: ticket, body: 'internal', internal: true)
          create(:ticket_article, ticket: ticket, body: 'external1', internal: false)
          create(:ticket_article, ticket: ticket, body: 'external2', internal: false)
        end

        it 'renders the first external article body' do
          expect(renderer.render).to eq '&gt; external1<br>'
        end
      end

      context 'with article.body_as_text as template' do
        let(:template) { '#{first_article.body_as_text.text2html}' }

        before do
          create(:ticket_article, ticket: ticket, body: "hello \n world", internal: false)
        end

        it 'renders the first article body as plain text' do
          expect(renderer.render).to eq 'hello <br> world'
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

    context 'with non-persisted objects and low-level placeholder parsing' do
      let(:group)        { Group.new(name: 'Users') }
      let(:owner)        { User.new(firstname: 'Owner<b>xxx</b>', lastname: 'Agent1<b>yyy</b>') }
      let(:current_user) { User.new(firstname: 'CurrentUser<b>xxx</b>', lastname: 'Agent2<b>yyy</b>') }
      let(:state)        { Ticket::State.new(name: 'new') }
      let(:ticket) do
        Ticket.new(
          id:         1,
          title:      '<b>Welcome to Zammad!</b>',
          group:      group,
          owner:      owner,
          state:      state,
          created_by: current_user,
          updated_by: current_user,
          created_at: Time.zone.parse('2016-11-12 12:00:00 UTC'),
          updated_at: Time.zone.parse('2016-11-12 14:00:00 UTC'),
        )
      end
      let(:article_html1) do
        Ticket::Article.new(
          body:         'test <b>hello</b><br>some new line',
          content_type: 'text/html',
        )
      end
      let(:article_plain1) do
        Ticket::Article.new(
          body:         "test <b>hello</b>\nsome new line",
          content_type: 'text/plain',
        )
      end
      let(:article_plain2) do
        Ticket::Article.new(
          body: "test <b>hello</b>\nsome new line",
        )
      end

      def render_result(template:, objects:, locale: 'en-us', timezone: 'Europe/Berlin')
        described_class.new(
          objects:  objects,
          locale:   locale,
          timezone: timezone,
          template: template,
        ).render
      end

      context 'with simple attribute access' do
        it 'renders ticket.title, HTML-escaped' do
          expect(render_result(template: '#{ticket.title}', objects: { ticket: ticket })).to eq(CGI.escapeHTML(ticket.title))
        end

        it 'renders ticket.created_at, converted to the given timezone' do
          expect(render_result(template: '#{ticket.created_at}', objects: { ticket: ticket })).to eq('11/12/2016  1:00 pm (Europe/Berlin)')
        end

        it 'renders ticket.created_by.firstname, HTML-escaped' do
          expect(render_result(template: '#{ticket.created_by.firstname}', objects: { ticket: ticket })).to eq('CurrentUser&lt;b&gt;xxx&lt;/b&gt;')
        end

        it 'renders ticket.updated_at, converted to the given timezone' do
          expect(render_result(template: '#{ticket.updated_at}', objects: { ticket: ticket })).to eq('11/12/2016  3:00 pm (Europe/Berlin)')
        end

        it 'renders ticket.updated_by.firstname, HTML-escaped' do
          expect(render_result(template: '#{ticket.updated_by.firstname}', objects: { ticket: ticket })).to eq('CurrentUser&lt;b&gt;xxx&lt;/b&gt;')
        end

        it 'renders ticket.owner.firstname, HTML-escaped' do
          expect(render_result(template: '#{ticket.owner.firstname}', objects: { ticket: ticket })).to eq('Owner&lt;b&gt;xxx&lt;/b&gt;')
        end
      end

      context 'with whitespace tolerance around the attribute name' do
        it 'tolerates a leading space' do
          expect(render_result(template: '#{ticket. title}', objects: { ticket: ticket })).to eq(CGI.escapeHTML(ticket.title))
        end

        it 'tolerates a leading newline' do
          expect(render_result(template: "\#{ticket.\n title}", objects: { ticket: ticket })).to eq(CGI.escapeHTML(ticket.title))
        end

        it 'tolerates a leading tab' do
          expect(render_result(template: "\#{ticket.\t title}", objects: { ticket: ticket })).to eq(CGI.escapeHTML(ticket.title))
        end

        it 'tolerates mixed leading tabs, newlines and a trailing tab' do
          expect(render_result(template: "\#{ticket.\t\n title\t}", objects: { ticket: ticket })).to eq(CGI.escapeHTML(ticket.title))
        end

        it 'tolerates a stray double-quote before the attribute name' do
          expect(render_result(template: "\#{ticket.\" title\t}", objects: { ticket: ticket })).to eq(CGI.escapeHTML(ticket.title))
        end
      end

      context 'with HTML auto-injected by the browser around the placeholder' do
        it 'strips an <a> tag wrapped around the placeholder' do
          template = '#{<a href="/test123">ticket." title</a>}'
          expect(render_result(template: template, objects: { ticket: ticket })).to eq(CGI.escapeHTML(ticket.title))
        end
      end

      context 'with article body rendering' do
        let(:template) { 'some test<br>#{article.body}' }

        it 'quotes an HTML article body' do
          expect(render_result(template: template, objects: { article: article_html1 })).to eq('some test<br>&gt; test hello<br>&gt; some new line<br>')
        end

        it 'quotes and HTML-escapes a plain text article body with an explicit content_type' do
          expect(render_result(template: template, objects: { article: article_plain1 })).to eq('some test<br>&gt; test &lt;b&gt;hello&lt;/b&gt;<br>&gt; some new line<br>')
        end

        it 'quotes and HTML-escapes a plain text article body with a default content_type' do
          expect(render_result(template: template, objects: { article: article_plain2 })).to eq('some test<br>&gt; test &lt;b&gt;hello&lt;/b&gt;<br>&gt; some new line<br>')
        end
      end

      context 'with config values' do
        it 'renders a single config value' do
          expect(render_result(template: '#{config.fqdn}', objects: { ticket: ticket })).to eq(Setting.get('fqdn'))
        end

        it 'renders multiple config values in one template' do
          template = 'some #{config.fqdn} and #{config.product_name}'
          expect(render_result(template: template, objects: { ticket: ticket })).to eq("some #{Setting.get('fqdn')} and #{Setting.get('product_name')}")
        end

        it 'tolerates whitespace around the config placeholder' do
          template = "some \#{ config.fqdn} and \#{\tconfig.product_name}"
          expect(render_result(template: template, objects: { ticket: ticket })).to eq("some #{Setting.get('fqdn')} and #{Setting.get('product_name')}")
        end
      end

      context 'with translations' do
        it 'renders a single translation' do
          expect(render_result(template: "\#{t('new')}", objects: { ticket: ticket }, locale: 'de-de')).to eq('neu')
        end

        it 'renders multiple translations in one template' do
          template = "some text \#{t('new')} and \#{t('open')}"
          expect(render_result(template: template, objects: { ticket: ticket }, locale: 'de-de')).to eq('some text neu and offen')
        end

        it 'tolerates whitespace inside the translation call' do
          template = "some text \#{t('new') } and \#{ t('open')}"
          expect(render_result(template: template, objects: { ticket: ticket }, locale: 'de-de')).to eq('some text neu and offen')
        end

        it 'tolerates newlines and tabs around the translation call' do
          template = "some text \#{\nt('new') } and \#{ t('open')\t}"
          expect(render_result(template: template, objects: { ticket: ticket }, locale: 'de-de')).to eq('some text neu and offen')
        end
      end

      it 'renders a translation of a chained attribute value' do
        expect(render_result(template: "\#{t(ticket.state.name)}", objects: { ticket: ticket }, locale: 'de-de')).to eq('neu')
      end

      context 'with missing objects and attributes' do
        it 'renders a debug message for an empty placeholder' do
          expect(render_result(template: '#{}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{no such object}'))
        end

        it 'renders a debug message for a missing object with a missing attribute' do
          expect(render_result(template: '#{notexsiting.notexsiting}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{notexsiting / no such object}'))
        end

        it 'renders a debug message for a missing attribute on an existing object' do
          expect(render_result(template: '#{ticket.notexsiting}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{ticket.notexsiting / no such method}'))
        end

        it 'renders a debug message for an empty attribute name' do
          expect(render_result(template: '#{ticket.}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{ticket. / no such method}'))
        end

        it 'renders a debug message for a missing attribute chained off an existing attribute value' do
          expect(render_result(template: '#{ticket.title.notexsiting}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{ticket.title.notexsiting / no such method}'))
        end

        it 'renders a debug message for a missing attribute chained off another missing attribute' do
          expect(render_result(template: '#{ticket.notexsiting.notexsiting}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{ticket.notexsiting / no such method}'))
        end

        it 'renders a debug message for a missing object' do
          expect(render_result(template: '#{notexsiting}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{notexsiting / no such object}'))
        end

        it 'renders a debug message for a missing object with a trailing dot' do
          expect(render_result(template: '#{notexsiting.}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{notexsiting / no such object}'))
        end

        it 'renders a plain string value' do
          expect(render_result(template: '#{string}', objects: { string: 'some string' })).to eq(CGI.escapeHTML('some string'))
        end

        it 'renders an integer value' do
          expect(render_result(template: '#{fixum}', objects: { fixum: 123 })).to eq(CGI.escapeHTML('123'))
        end

        it 'renders a float value' do
          expect(render_result(template: '#{float}', objects: { float: 123.99 })).to eq(CGI.escapeHTML('123.99'))
        end
      end

      context 'with disallowed methods' do
        %w[destroy save update create delete remove drop new update_att all find where].each do |method|
          it "renders a debug message instead of calling ##{method}" do
            template = "\#{ticket.#{method}}"
            expect(render_result(template: template, objects: { ticket: ticket })).to eq(CGI.escapeHTML("\#{ticket.#{method} / not allowed}"))
          end
        end

        it 'renders a debug message for a shell injection attempt appended to an attribute call' do
          template = '#{ticket.title `echo 1`}'
          expect(render_result(template: template, objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{ticket.title`echo1` / not allowed}'))
        end

        context 'with whitespace before the disallowed method' do
          it 'rejects the method with a leading space' do
            expect(render_result(template: '#{ticket. destroy}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('#{ticket.destroy / not allowed}'))
          end

          it 'rejects the method with a leading newline' do
            expect(render_result(template: "\#{ticket.\n destroy}", objects: { ticket: ticket })).to eq(CGI.escapeHTML("\#{ticket.destroy / not allowed}"))
          end

          it 'rejects the method with a leading tab' do
            expect(render_result(template: "\#{ticket.\t destroy}", objects: { ticket: ticket })).to eq(CGI.escapeHTML("\#{ticket.destroy / not allowed}"))
          end

          it 'rejects the method with a leading carriage return' do
            expect(render_result(template: "\#{ticket.\r destroy}", objects: { ticket: ticket })).to eq(CGI.escapeHTML("\#{ticket.destroy / not allowed}"))
          end
        end
      end

      context 'with methods taking a single integer parameter' do
        it 'calls .first(n) with an allowed integer parameter' do
          expect(render_result(template: '#{ticket.title.first(3)}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('<b>'))
        end

        it 'calls .last(n) with an allowed integer parameter' do
          expect(render_result(template: '#{ticket.title.last(4)}', objects: { ticket: ticket })).to eq(CGI.escapeHTML('</b>'))
        end

        it 'rejects .slice with multiple parameters' do
          expect(render_result(template: '#{ticket.title.slice(3, 4)}', objects: { ticket: ticket })).to eq(CGI.escapeHTML("\#{ticket.title.slice(3,4) / invalid parameter: 3,4}"))
        end

        it 'rejects a method call with a non-integer parameter' do
          template = "\#{ticket.title.first('some invalid parameter')}"
          expect(render_result(template: template, objects: { ticket: ticket })).to eq("\#{ticket.title.first(someinvalidparameter) / invalid parameter: someinvalidparameter}")
        end

        it 'rejects a shell injection attempt as a method parameter' do
          template = '#{ticket.title.chomp(`cat /etc/passwd`)}'
          expect(render_result(template: template, objects: { ticket: ticket })).to eq("\#{ticket.title.chomp(`cat/etc/passwd`) / not allowed}")
        end
      end
    end
  end
  # rubocop:enable Lint/InterpolationCheck

  context 'with user avatar' do
    let(:base64_img)  { 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==' }
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
