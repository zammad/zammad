# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'pagination', authenticated_as: :authenticate do |model:, klass:, path:, create_params: {}, main_column: :name|
  let(:create_params) { create_params }
  let(:model)         { model }
  let(:klass)         { klass }
  let(:base_scope)    { klass.try(:changeable) || klass }
  let(:indexable)     { Models.indexable.include?(klass) }

  def authenticate
    create_list(model, 500, **create_params)
    true
  end

  def current_first_row
    page.first('.js-tableBody tr:first-child td').text.strip
  end

  def current_last_row
    page.first('.js-tableBody tr:last-child td').text.strip
  end

  def wait_until_first_and_last_changed(first_row, last_row)
    wait.until do
      first_row != current_first_row && last_row != current_last_row
    end
  end

  before do
    visit path
  end

  it 'does paginate' do
    page.all('.js-tableBody tr').count

    expect(page).to have_css('.js-pager')
    expect(page).to have_css('.js-page.btn--active', text: '1')
    expect(page).to have_no_css('.js-tableBody table-draggable')

    first_row = current_first_row
    last_row  = current_last_row
    page.first('.js-page', text: '2').click

    expect(page).to have_css('.js-page.btn--active', text: '2')
    expect(page).to have_no_css('.js-tableBody table-draggable')
    wait_until_first_and_last_changed(first_row, last_row)

    first_row = current_first_row
    last_row  = current_last_row
    page.first('.js-page', text: '3').click

    expect(page).to have_css('.js-page.btn--active', text: '3')
    expect(page).to have_no_css('.js-tableBody table-draggable')
    wait_until_first_and_last_changed(first_row, last_row)

    first_row = current_first_row
    last_row  = current_last_row
    page.first('.js-page', text: '4').click

    expect(page).to have_css('.js-page.btn--active', text: '4')
    expect(page).to have_no_css('.js-tableBody table-draggable')
    wait_until_first_and_last_changed(first_row, last_row)

    page.first('.js-page', text: '1').click

    page.first(".js-tableHead[data-column-key=#{main_column}]").click
    expect(page).to have_css('.js-page.btn--active', text: '1')
    expect(page).to have_no_css('.js-tableBody table-draggable')

    first_row = current_first_row
    last_row  = current_last_row
    page.first(".js-tableHead[data-column-key=#{main_column}]").click

    wait_until_first_and_last_changed(first_row, last_row)
  end

  context 'when search is enabled' do
    before do
      skip 'No search field enabled' if !indexable || !page.has_css?('.page-content .searchfield .js-search', wait: 5)
    end

    it 'does filter results with the search bar' do
      page.find('.js-search').fill_in with: base_scope.last.try(main_column)
      expect(page).to have_css('.js-tableBody tr', count: 1)

      # does stay after reload
      refresh
      expect(page).to have_css('.js-search')
      expect(page).to have_css('.js-tableBody tr', count: 1)

      # remove filter
      page.find('.js-search').fill_in with: ' '

      expect(page).to have_css('.js-tableBody tr', count: 50)
    end

    context 'when ES is enabled', authenticated_as: :authenticate, searchindex: true do
      def authenticate
        create_list(model, 500, **create_params)
        searchindex_model_reload([klass]) if indexable
        create(:admin)
      end

      it 'does only show 2 pages because of a search filter and paginate through it' do
        entries_per_page = page.all('.js-tableBody tr').count
        search_query = base_scope.limit(entries_per_page * 2).pluck(:id).map { |i| "id: #{i}" }.join(' OR ')
        page.find('.js-search').fill_in with: search_query, fill_options: { clear: :backspace }
        wait.until { page.first('.js-pager').all('.js-page').count == 4 }

        page.first('.js-page', text: '2').click
        expect(page).to have_css('.js-page.btn--active', text: '2')
        expect(page).to have_no_css('.js-tableBody table-draggable')

        wait.until { page.find('.js-search').present? && page.find('.js-search').value == search_query && page.first('.js-pager').all('.js-page').count == 4 }
      end
    end
  end
end
