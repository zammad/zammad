# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'pagination' do |model:, klass:, path:, sort_by: :name|
  let(:model) { model }

  def authenticate
    create_list(model, 500)
    true
  end

  it 'does paginate', authenticated_as: :authenticate do
    visit path
    expect(page).to have_css('.js-pager', wait: 10)

    class_page1 = klass.order(sort_by => :asc, id: :asc).offset(50).first
    expect(page).to have_text(class_page1.name, wait: 10)
    expect(page).to have_css('.js-page.is-selected', text: '1')

    page.first('.js-page', text: '2', wait: 10).click

    class_page2 = klass.order(sort_by => :asc, id: :asc).offset(175).first
    expect(page).to have_text(class_page2.name, wait: 10)
    expect(page).to have_css('.js-page.is-selected', text: '2')

    page.first('.js-page', text: '3', wait: 10).click

    class_page3 = klass.order(sort_by => :asc, id: :asc).offset(325).first
    expect(page).to have_text(class_page3.name, wait: 10)
    expect(page).to have_css('.js-page.is-selected', text: '3')

    page.first('.js-page', text: '4', wait: 10).click

    class_page4 = klass.order(sort_by => :asc, id: :asc).offset(475).first
    expect(page).to have_text(class_page4.name, wait: 10)
    expect(page).to have_css('.js-page.is-selected', text: '4')

    page.first('.js-page', text: '1', wait: 10).click

    page.first('.js-tableHead[data-column-key=name]').click
    expect(page).to have_text(class_page1.name, wait: 10)
    expect(page).to have_css('.js-page.is-selected', text: '1')

    page.first('.js-tableHead[data-column-key=name]').click
    class_last = klass.order(sort_by => :desc).first
    expect(page).to have_text(class_last.name, wait: 10)
  end
end
