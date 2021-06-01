# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'pagination' do |model:, klass:, path:, sort_by: :name|
  def prepare(model)
    create_list(model, 500)
  end

  it 'does paginate' do
    prepare(model)
    visit path
    refresh # more stability
    expect(page).to have_css('.js-pager', wait: 10)

    class_page1 = klass.order(sort_by => :asc, id: :asc).offset(50).first
    expect(page).to have_text(class_page1.name, wait: 10)

    page.first('.js-page', text: '2').click
    await_empty_ajax_queue

    class_page2 = klass.order(sort_by => :asc, id: :asc).offset(175).first
    expect(page).to have_text(class_page2.name, wait: 10)

    page.first('.js-page', text: '3').click
    await_empty_ajax_queue

    class_page3 = klass.order(sort_by => :asc, id: :asc).offset(325).first
    expect(page).to have_text(class_page3.name, wait: 10)

    page.first('.js-page', text: '4').click
    await_empty_ajax_queue

    class_page4 = klass.order(sort_by => :asc, id: :asc).offset(475).first
    expect(page).to have_text(class_page4.name, wait: 10)

    page.first('.js-page', text: '1').click
    await_empty_ajax_queue

    page.first('.js-tableHead[data-column-key=name]').click
    await_empty_ajax_queue
    expect(page).to have_text(class_page1.name, wait: 10)

    page.first('.js-tableHead[data-column-key=name]').click
    await_empty_ajax_queue
    class_last = klass.order(sort_by => :desc).first
    expect(page).to have_text(class_last.name, wait: 10)
  end
end
