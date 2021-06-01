# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base canonical link', type: :system, current_user_id: 1, authenticated_as: false do
  include_context 'basic Knowledge Base'

  let(:path)          { '/path' }
  let(:subdomain)     { 'subdomain.example.net' }
  let(:locale)        { primary_locale.system_locale.locale }
  let(:category_slug) { category.translations.first.to_param }
  let(:answer_slug)   { published_answer.translations.first.to_param }

  before do
    published_answer
    knowledge_base.update! custom_address: custom_address
  end

  shared_examples 'having canonical links on all pages' do
    it 'includes canonical link on home page' do
      visit help_root_path(locale)
      expect(page).to have_canonical_url("#{prefix}/#{locale}")
    end

    it 'includes canonical link on category page' do
      visit help_category_path(locale, category)
      expect(page).to have_canonical_url("#{prefix}/#{locale}/#{category_slug}")
    end

    it 'includes canonical link on answer page' do
      visit help_answer_path(locale, published_answer.category, published_answer)
      expect(page).to have_canonical_url("#{prefix}/#{locale}/#{category_slug}/#{answer_slug}")
    end
  end

  shared_examples 'core locations' do
    let(:scheme) { ssl ? 'https' : 'http' }
    before { Setting.set('http_type', scheme) }

    context 'with custom domain' do
      let(:custom_address) { subdomain }
      let(:prefix) { "#{scheme}://#{subdomain}" }

      it_behaves_like 'having canonical links on all pages'
    end

    context 'with custom path' do
      let(:custom_address) { path }
      let(:prefix) { "#{scheme}://#{Setting.get('fqdn')}#{path}" }

      it_behaves_like 'having canonical links on all pages'
    end

    context 'with custom domain and path' do
      let(:custom_address) { "#{subdomain}#{path}" }
      let(:prefix) { "#{scheme}://#{subdomain}#{path}" }

      it_behaves_like 'having canonical links on all pages'
    end

    context 'without custom address' do
      let(:custom_address) { nil }
      let(:prefix) { "#{scheme}://#{Setting.get('fqdn')}/help" }

      it_behaves_like 'having canonical links on all pages'
    end
  end

  context 'when SSL disabled' do
    let(:ssl) { false }

    include_examples 'core locations'
  end

  context 'when SSL enabled' do
    let(:ssl) { true }

    include_examples 'core locations'
  end

  matcher :have_canonical_url do |expected|
    match do
      return false if canonical_link_element.blank?

      canonical_link_target == expected
    end

    failure_message do
      return 'no canonical link found' if canonical_link_element.blank?

      "expected canonical link pointing to \"#{expected}\", but found \"#{canonical_link_target}\" instead"
    end

    def canonical_link_element
      return @canonical_link_element if defined?(@canonical_link_element)

      @canonical_link_element = actual.first('head link[rel=canonical]', visible: :hidden, minimum: 0)
    end

    def canonical_link_target
      @canonical_link_target ||= canonical_link_element[:href]
    end

    description { "have canonical tag with href of #{expected}" }
  end
end
