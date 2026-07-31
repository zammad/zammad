# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'pagination', authenticated_as: :authenticate do |model:, klass:, path:, create_params: {}, main_column: :name|
  let(:create_params) { create_params }
  let(:model)         { model }
  let(:klass)         { klass }
  let(:base_scope)    { klass.try(:changeable) || klass }
  let(:indexable)     { Models.indexable.include?(klass) }
  let(:main_column)   { main_column }

  def authenticate
    create_list(model, 500, **create_params)
    true
  end

  # The main column is not necessarily the first cell - a table may lead with an icon column.
  def main_column_text(row)
    index = page.all('.js-tableHead').index { |header| header['data-column-key'] == main_column.to_s }

    page.first("#{row} td:nth-child(#{(index || 0) + 1})").text.strip
  end

  def current_first_row
    main_column_text('.js-tableBody tr:first-child')
  end

  def current_last_row
    main_column_text('.js-tableBody tr:last-child')
  end

  def wait_until_first_and_last_changed(first_row, last_row)
    wait.until do
      first_row != current_first_row && last_row != current_last_row
    end
  end

  def search(search_query)
    search_field = page.find('.js-search')

    # A prior programmatic blur (below) can leave the cursor position such
    # that fill_in's clear: :backspace clears nothing and the new value gets
    # inserted at the start instead of replacing the field - explicitly
    # select-all before typing, regardless of where the cursor ended up.
    search_field.click
    search_field.send_keys([magic_key, 'a'], :backspace)
    search_field.send_keys(search_query)
    search_field.execute_script('this.blur()')

    wait.until { page.current_url.end_with?("1/#{ERB::Util.url_encode(search_query.to_s)}") }

    await_empty_ajax_queue
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

    await_empty_ajax_queue
    expect(page).to have_css('.js-page.btn--active', text: '2')
    expect(page).to have_no_css('.js-tableBody table-draggable')
    wait_until_first_and_last_changed(first_row, last_row)

    first_row = current_first_row
    last_row  = current_last_row
    page.first('.js-page', text: '3').click

    await_empty_ajax_queue
    expect(page).to have_css('.js-page.btn--active', text: '3')
    expect(page).to have_no_css('.js-tableBody table-draggable')
    wait_until_first_and_last_changed(first_row, last_row)

    first_row = current_first_row
    last_row  = current_last_row
    page.first('.js-page', text: '4').click

    await_empty_ajax_queue
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
      search(base_scope.last.try(main_column))
      expect(page).to have_css('.js-tableBody tr', count: 1)

      # does stay after reload
      refresh
      expect(page).to have_css('.js-search')
      expect(page).to have_css('.js-tableBody tr', count: 1)

      # remove filter
      search(' ')

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
        search(search_query)
        wait.until { page.first('.js-pager').all('.js-page').count == 4 }

        # Drain any in-flight AJAX (e.g. the first-page data load triggered by
        # the search) before navigating to page 2, otherwise that response can
        # race the click and reset the pager back to page 1.
        await_empty_ajax_queue

        page.first('.js-page', text: '2').click

        await_empty_ajax_queue
        expect(page).to have_css('.js-page.btn--active', text: '2')
        expect(page).to have_no_css('.js-tableBody table-draggable')

        wait.until { page.find('.js-search').present? && page.find('.js-search').value == search_query && page.first('.js-pager').all('.js-page').count == 4 }
      end
    end
  end
end
