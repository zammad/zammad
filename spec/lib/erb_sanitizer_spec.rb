# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ErbSanitizer, :aggregate_failures do
  let(:object_key)    { :type_enrichment_data }
  let(:allowed_names) { %w[flag_on flag_off note] }
  let(:object_values) { { 'flag_on' => true, 'flag_off' => false, 'note' => 'hello' } }

  # Run sanitize + ERB end-to-end so assertions can match the final output exactly
  #   as a caller would see it. Any payload fully escaped by the sanitizer appears
  #   unchanged in the output (ERB converts `<%%` back to `<%` on render).
  def render(template, names: allowed_names, values: object_values)
    sanitized = described_class.sanitize(template, object_key: object_key, allowed_names: names)
    struct    = Struct.new(*values.keys.map(&:to_sym)).new(*values.values)
    context   = Object.new.tap { |o| o.instance_variable_set(:@objects, { object_key => struct }) }
    ERB.new(sanitized).result(context.instance_eval { binding })
  end

  describe '.sanitize' do
    context 'with an allowed condition referencing a known name' do
      it 'keeps the body when the condition is truthy' do
        expect(render('A<% if @objects[:type_enrichment_data].flag_on %>B<% end %>C')).to eq('ABC')
      end

      it 'drops the body when the condition is falsy' do
        expect(render('A<% if @objects[:type_enrichment_data].flag_off %>B<% end %>C')).to eq('AC')
      end

      it 'handles else branches' do
        expect(render('<% if @objects[:type_enrichment_data].flag_on %>X<% else %>Y<% end %>')).to eq('X')
        expect(render('<% if @objects[:type_enrichment_data].flag_off %>X<% else %>Y<% end %>')).to eq('Y')
      end

      it 'handles nested conditions' do
        expect(render('<% if @objects[:type_enrichment_data].flag_on %>a<% if @objects[:type_enrichment_data].flag_off %>b<% end %>c<% end %>')).to eq('ac')
      end
    end

    context 'with a reserved predicate check' do
      let(:object_values) { { 'note' => '' } }

      it 'accepts .present?' do
        expect(render('<% if @objects[:type_enrichment_data].note.present? %>X<% end %>')).to eq('')
      end

      it 'accepts .blank?' do
        expect(render('<% if @objects[:type_enrichment_data].note.blank? %>X<% end %>')).to eq('X')
      end

      it 'accepts .empty?' do
        expect(render('<% if @objects[:type_enrichment_data].note.empty? %>X<% end %>')).to eq('X')
      end
    end

    context 'when the value is blank (plain Ruby truthiness)' do
      let(:object_values) { { 'note' => '' } }

      it 'is truthy (empty string is truthy in Ruby)' do
        expect(render('<% if @objects[:type_enrichment_data].note %>X<% end %>')).to eq('X')
      end
    end

    context 'when the name is not in allowed_names' do
      it 'renders the tag and its matching end as literal text' do
        payload = '<% if @objects[:type_enrichment_data].unknown %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with an unknown bareword (not even via @objects)' do
      it 'renders as literal text' do
        payload = '<% if unknown %>B<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with a method call in the condition expression' do
      it 'renders as literal text' do
        payload = '<% if Setting.get("tag_new") %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with arbitrary ERB code in the template' do
      it 'renders as literal text' do
        payload = "<% File.read('/etc/passwd') %>"

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with an ERB output tag' do
      it 'renders as literal text' do
        payload = '<%= 1 + 1 %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with an ERB comment tag' do
      it 'renders as literal text' do
        payload = '<%# a comment %>'

        expect(render(payload)).to eq(payload)
      end
    end

    # The whitelist must not be bypassable. Each payload below looks superficially
    #   close to an allowed construct and must still render as its exact input text
    #   (all `<%` escaped, nothing executed).
    context 'with a method chain after the whitelisted access path' do
      it 'renders as literal text' do
        payload = '<% if @objects[:type_enrichment_data].flag_on.tap { 1 / 0 } %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with access to a different @objects key' do
      it 'renders as literal text' do
        payload = '<% if @objects[:ticket] %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with hash-bracket access on the whitelisted object' do
      it 'renders as literal text' do
        payload = '<% if @objects[:type_enrichment_data][:flag_on] %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with a .send() method call' do
      it 'renders as literal text' do
        payload = '<% if @objects[:type_enrichment_data].send(:flag_on) %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with a comparison operator against a literal value' do
      let(:object_values) { { 'mode' => 'add', 'count' => 3, 'flag_on' => true } }
      let(:allowed_names) { %w[mode count flag_on] }

      it 'accepts == against a single-quoted string' do
        expect(render("<% if @objects[:type_enrichment_data].mode == 'add' %>X<% end %>")).to eq('X')
        expect(render("<% if @objects[:type_enrichment_data].mode == 'fill' %>X<% end %>")).to eq('')
      end

      it 'accepts != against a single-quoted string' do
        expect(render("<% if @objects[:type_enrichment_data].mode != 'fill' %>X<% end %>")).to eq('X')
      end

      it 'accepts == and != against integer literals' do
        expect(render('<% if @objects[:type_enrichment_data].count == 3 %>X<% end %>')).to eq('X')
        expect(render('<% if @objects[:type_enrichment_data].count != 3 %>X<% end %>')).to eq('')
      end

      it 'accepts == against the true/false/nil keywords' do
        expect(render('<% if @objects[:type_enrichment_data].flag_on == true %>X<% end %>')).to eq('X')
        expect(render('<% if @objects[:type_enrichment_data].flag_on == false %>X<% end %>')).to eq('')
        expect(render('<% if @objects[:type_enrichment_data].flag_on == nil %>X<% end %>')).to eq('')
      end

      it 'routes the elsif chain correctly' do
        template = "<% if @objects[:type_enrichment_data].mode == 'add' %>A<% elsif @objects[:type_enrichment_data].mode == 'fill' %>F<% else %>E<% end %>"

        expect(render(template)).to eq('A')
      end
    end

    context 'with a comparison operator against an executable RHS' do
      it 'rejects a double-quoted string (interpolation bypass risk)' do
        payload = '<% if @objects[:type_enrichment_data].flag_on == "add" %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end

      it 'rejects a method call on the RHS' do
        payload = '<% if @objects[:type_enrichment_data].flag_on == Setting.get("x") %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end

      it 'rejects a variable reference on the RHS' do
        payload = '<% if @objects[:type_enrichment_data].flag_on == @other %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end

      it 'rejects a compound RHS expression' do
        payload = "<% if @objects[:type_enrichment_data].flag_on == 'a' + 'b' %>X<% end %>"

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with a compound condition combining && and a method call' do
      it 'renders as literal text' do
        payload = '<% if @objects[:type_enrichment_data].flag_on && Setting.get("x") %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with the unless keyword' do
      it 'renders as literal text' do
        payload = '<% unless @objects[:type_enrichment_data].flag_on %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with a for loop' do
      it 'renders as literal text' do
        payload = '<% for i in [1, 2] %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with a predicate method not in the whitelist' do
      it 'renders as literal text' do
        payload = '<% if @objects[:type_enrichment_data].flag_on.to_proc %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with an assignment via the whitelisted path' do
      it 'renders as literal text' do
        payload = '<% @objects[:type_enrichment_data].flag_on = "pwned" %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with a string-keyed @objects access' do
      it 'renders as literal text' do
        payload = '<% if @objects["type_enrichment_data"].flag_on %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with an <%= output tag that looks allowed' do
      it 'renders as literal text' do
        payload = '<%= @objects[:type_enrichment_data].flag_on %>'

        expect(render(payload)).to eq(payload)
      end
    end
  end

  describe 'parameterization' do
    context 'with a different object_key' do
      let(:object_key)    { :my_context }
      let(:object_values) { { 'flag_on' => true } }
      let(:allowed_names) { %w[flag_on] }

      it 'accepts the chosen key' do
        expect(render('A<% if @objects[:my_context].flag_on %>B<% end %>C')).to eq('ABC')
      end

      it 'rejects the default key when a different one is configured' do
        payload = '<% if @objects[:type_enrichment_data].flag_on %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end

    context 'with allowed_names passed as symbols' do
      let(:allowed_names) { %i[flag_on] }

      it 'treats them the same as strings' do
        expect(render('A<% if @objects[:type_enrichment_data].flag_on %>B<% end %>C')).to eq('ABC')
      end
    end

    context 'with allowed_names passed as a mix of symbols and strings' do
      let(:allowed_names) { [:flag_on, 'flag_off'] }

      it 'treats them the same' do
        expect(render('A<% if @objects[:type_enrichment_data].flag_on %>B<% end %>C')).to eq('ABC')
        expect(render('<% if @objects[:type_enrichment_data].flag_off %>X<% end %>')).to eq('')
      end
    end

    context 'with empty allowed_names' do
      let(:allowed_names) { [] }

      it 'escapes every conditional' do
        payload = '<% if @objects[:type_enrichment_data].flag_on %>X<% end %>'

        expect(render(payload)).to eq(payload)
      end
    end
  end

  describe 'RESERVED_CHECKS' do
    it 'lists the expected predicate methods' do
      expect(described_class::RESERVED_CHECKS).to eq(%w[present? blank? empty? any? none? nil?])
    end

    it 'is frozen' do
      expect(described_class::RESERVED_CHECKS).to be_frozen
    end
  end
end
