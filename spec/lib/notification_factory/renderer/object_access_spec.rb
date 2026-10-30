# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe NotificationFactory::Renderer::ObjectAccess do
  describe '.allows?' do
    context 'with a model a template may reach' do
      it 'allows a column' do
        expect(described_class.allows?(Ticket.new, 'title')).to be(true)
      end

      it 'allows an association to another allowed model' do
        expect(described_class.allows?(Ticket.new, 'customer')).to be(true)
      end

      it 'allows a has_many association to another allowed model' do
        expect(described_class.allows?(Organization.new, 'members')).to be(true)
      end

      it 'allows a named helper' do
        expect(described_class.allows?(Ticket.new, 'tag_list')).to be(true)
      end

      it 'refuses an association to a model a template may not reach' do
        expect(described_class.allows?(Group.new, 'email_address')).to be(false)
      end

      it 'refuses the tokens of a user' do
        expect(described_class.allows?(User.new, 'tokens')).to be(false)
      end

      it 'refuses the password of a user' do
        expect(described_class.allows?(User.new, 'password')).to be(false)
      end

      it 'refuses the preferences of a user' do
        expect(described_class.allows?(User.new, 'preferences')).to be(false)
      end

      it 'refuses the class of a record' do
        expect(described_class.allows?(Ticket.new, 'class')).to be(false)
      end

      it 'refuses a method that is neither a column, an association nor a helper' do
        expect(described_class.allows?(Ticket.new, 'articles_count')).to be(false)
      end
    end

    context 'with a model a template may not reach' do
      it 'refuses a column' do
        expect(described_class.allows?(Setting.new, 'name')).to be(false)
      end
    end

    context 'with a class' do
      it 'refuses any method' do
        expect(described_class.allows?(Ticket, 'first')).to be(false)
      end
    end

    context 'with a plain value' do
      it 'allows a listed method on a string' do
        expect(described_class.allows?('abc', 'downcase')).to be(true)
      end

      it 'refuses turning a string into a constant' do
        expect(described_class.allows?('Setting', 'constantize')).to be(false)
      end

      it 'allows to_s on nil' do
        expect(described_class.allows?(nil, 'to_s')).to be(true)
      end

      it 'allows first on an array' do
        expect(described_class.allows?([1, 2], 'first')).to be(true)
      end

      it 'allows to_s on a time' do
        expect(described_class.allows?(Time.zone.now, 'to_s')).to be(true)
      end
    end

    context 'with a relation' do
      it 'allows first' do
        expect(described_class.allows?(Ticket.all, 'first')).to be(true)
      end

      it 'refuses offset' do
        expect(described_class.allows?(Ticket.all, 'offset')).to be(false)
      end
    end

    context 'with a struct' do
      let(:struct) { Struct.new(:instruction).new('text') }

      it 'allows a member' do
        expect(described_class.allows?(struct, 'instruction')).to be(true)
      end

      it 'refuses any other method' do
        expect(described_class.allows?(struct, 'class')).to be(false)
      end
    end

    context 'with an external data source' do
      let(:source) { ExternalDataSource.new(options: {}, term: 'abc', render_context: {}) }

      it 'allows the search term' do
        expect(described_class.allows?(source, 'term')).to be(true)
      end

      it 'refuses the options' do
        expect(described_class.allows?(source, 'options')).to be(false)
      end
    end

    context 'with any other object' do
      it 'refuses any method' do
        expect(described_class.allows?(Object.new, 'to_s')).to be(false)
      end
    end
  end
end
