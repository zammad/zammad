# How to Test with RSpec and Capybara

RSpec is the recommended way of writing back end tests for Zammad,
and in combination with Capybara also Selenium based end-to-end tests.

This page explains some Zammad specific extensions that make testing easier.

## Running

To run tests locally in the test environment, you need to first ensure the `test` database is in the expected state:

```sh
RAILS_ENV=test bundle exec rake db:drop db:create zammad:ci:test:prepare
```

Now, running a single test can be done via the following command:

```sh
bundle exec rspec spec/system/ticket/zoom_spec.rb
```

Note that it's also possible to run a specific test case by including the line number in the command:

```sh
bundle exec rspec spec/system/ticket/zoom_spec.rb:1072
```

If you would like to specify the used browser for Capybara end-to-end tests, simply set the `BROWSER` environment
variable:

```sh
BROWSER=firefox bundle exec rspec spec/system/ticket/zoom_spec.rb
```

Also running failed tests only is possible with the option `--only-failures`.

```sh
bundle exec rspec --only-failures spec/system/ticket/zoom_spec.rb
```

## Default RSpec Environment

RSpec will populate the database at startup. These users are available in any test right away:

- admin: `admin@example.com`
- agent: `agent1@example.com`
- client: `nicole.braun@zammad.org`

## RSpec Meta Attributes

### `authenticated_as`

Manages logging in.

Example usage: `Rspec.describe :example, authenticated_as: true`

Takes boolean, symbol or lambda. Symbol is a method name to be executed. Works for RSpec's `let` too! Lambda or
referenced method are expected to return `User` object or a boolean.

`true` is the default value. It logs in with `admin@example.com` admin user. If a `User` is returned, it attempts to
login with it. `false` causes to skip logging in altogether.

Lambda or referenced method is evaluated before web page is loaded. Thus this is a good place to prepare for the test.
For example to set `Setting`.

### `time_zone`

Allows to set custom time zone. Takes Rails timezone names. Beware that it sets timezone for the server process.
Browser in CI is not affected.

Example usage: `Rspec.describe :example, time_zone: 'Vilnius/Lithuania'`

### `db_strategy: :reset / :reset_all`

RSpec resets database using transaction after each example. But DBs can't handle some changes (e.g. altering schema)
this way. MySQL is especially bad at this.

- `db_strategy: :reset` will reset database after each example
- `db_strategy: :reset_all` will reset database only once after whole context! This is a great way to increase
performance. But easy to shoot yourself in a foot too! Use custom `before :all` and `after :all` to setup and tear down
environment

### `performs_jobs`

ActiveJob background jobs are not performed automatically outside of `spec/jobs`! If you want to run `performs_jobs` in
other Specs, please do following:

```ruby
context 'example', performs_jobs: true
```

### `required_envs`

Checks if required ENVs are present. Raises error if one of them is missing. Since most ENV variables are credentials
for 3rd party services, given variables are filtered from VCR cassettes too.

```ruby
context 'example', required_envs: %w[FACEBOOK_ADMIN_USER_ID FACEBOOK_ADMIN_FIRSTNAME]
```

## Capybara Helpers

### `await_empty_ajax_queue`

Forces test to wait for JQuery ajax requests to finish. After the last request is finished, it waits for another 0.5s.
Effectively giving time for response to render. Great to use in `TicketZoom` and other complicated views.

Even if nothing is being loaded, it causes 0.5s pause!

Example usage:

```ruby
it 'example' do
  visit ticket_url
  await_empty_ajax_queue
  expect(page).to have_css('#css')
end
```

### `ensure_websocket`

Waits till connection to websocket is established. Sometimes actions rely on Websocket. But Capybara may be too fast
and execution action before Websocket is established

```ruby
it 'example' do
  visit ticket_url
  ensure_websocket
  expect(page).to have_css('#css')
end
```

### `authenticated_as`

As the default the login in selenium will be simulated and not the real form in the frontend.

With the `authentication_type` it's possible to switch to the real form with he value `form`.

### `current_user_id`

Returns ID of the current session user

### `current_user`

Returns current session user object

### `in_modal`

Waits for modal to load, wraps in `within` and waits for modal to close

```ruby
it 'example' do
  click 'open modal'
  in_modal do
    do_something_in_modal
  end

  expect
end
```

When `expect` is called in the given block, `in_modal` does not wait for modal to close. It assumes the intention was
to test something in the modal and closing it is not relevant.

### `wait`

Wait for block to return expected value. Supports `#until`, `#until_appears`, `#until_disappears`, `#until_constant`

## Capybara Selectors

### `have_* / have_no_*`

Capybara selectors wait for few seconds to see if expectation is fulfilled or not. Thus
`expect(page).to have_no_selector()` is much much faster than `expect(page).not_to have_selector()`

### `active_content`

Selects content (right-hand) tab

### `active_ticket_article`

Selects a given ticket article with ID. Great to wait for TicketZoom to (re)load!

Example usage: `find :active_ticket_article, 123`

### Advanced usage of `find`

`find` may take `text:` attribute. Then it filters the list of elements by text they contain

`find '.popular_class', text: 'value'`

`find` also allows to manually check elements before returning

`find('.popular_class') { |elem| process(elem) }`

### Form helpers for the new stack

#### Finding fields

FormKit-based fields have a custom implementation, so a number of helpers is provided to make it easier to find them
via their labels:

```ruby
find_input('Title')
find_select('Owner')
find_treeselect('Category')
find_autocomplete('Customer')
find_editor('Text')
find_datepicker('Pending till')
```

Radio fields do not have textual labels, so they can be found via their identifiers instead:

```ruby
find_radio('articleSenderType')
```

In case of ambiguous labels, make sure to pass `exact_text` option:

```ruby
find_datepicker(nil, exact_text: 'Date')
```

### Executing actions on fields

Returned form field elements have some special syntactic sugar that provide actions depending on the type of the field:

```ruby
find_input('Title').type('Foo Bar')
find_editor('Text').type('Lorem ipsum dolor sit amet.')

find_radio('articleSenderType').select_choice('Outbound Call')

find_datepicker('Date Picker').select_date(Date.tomorrow)
find_datepicker('Pending till').select_datetime('2023-01-01T09:00:00.000Z')
find_datepicker('Date').type_date(Date.today)
find_datepicker('Date Time').type_datetime(DateTime.now)

find_select('Owner').select_option('Test Admin Agent')
find_select('Multi Select').select_options(['Option 1', 'Option 2'])
find_treeselect('Tree Select').select_option('Parent 1::Option A')
find_treeselect('Multi Tree Select').select_options(['Parent 1::Option A', 'Parent 2::Option C'])

find_treeselect('Tree Select').search_for_option('Parent 1::Option A')
find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
find_autocomplete('Tags').search_for_options([tag_1, tag_2, tag_3])

find_toggle('Boolean').toggle
find_toggle('Boolean').toggle_on
find_toggle('Boolean').toggle_off
```

To wait for a custom GraphQL response in autocomplete fields, you can provide expected `gql_filename` and/or
`gql_number` arguments:

```ruby
find_autocomplete('Custom').search_for_option('foo', gql_filename: 'shared/entities/user/graphql/queries/user.graphql', gql_number: 4)
```

Clearing selections and input is also possible, if the field supports it:

```ruby
find_select('Select').clear_selection
find_treeselect('Tree Select').clear_selection
find_autocomplete('Auto Complete').clear_selection
find_editor('Text').clear
find_datepicker('Date Picker').clear
```

All custom actions are chainable, in the same way as other Capybara actions:

```ruby
find_treeselect('Tree Select').clear_selection.search_for_option('Option C')
find_autocomplete('Tags').search_for_options([tag_1, tag_2, tag_3]).select_options(%w[foo bar])
```

### Form context

In order to stabilize multiple field interactions, actions can be executed within the same form context:

```ruby
within_form(form_updater_gql_number: 2) do
  find_autocomplete('CC').search_for_options([email_address_1, email_address_2])
  find_autocomplete('Tags').search_for_options([tag_1, tag_2, tag_3]).select_options(%w[foo bar])
  find_editor('Text').type(body)
end
```

Within the same context all form updater responses (Core Workflow) are automatically tracked and waited on, as well as
multiple types of GraphQL responses behind the autocomplete fields. To define a custom starting form updater response
number, use the `form_updater_gql_number` argument.

### Custom matchers

A number of useful test matchers is also available, including their negated versions:

```ruby
expect(find_select('Select')).to have_selected_option('Option 1')
expect(find_select('Select')).to have_no_selected_option('Option 2')
expect(find_select('Multi Select')).to have_selected_options(['Option 1', 'Option 2'])
expect(find_treeselect('Tree Select')).to have_selected_option_with_parent('Parent 1::Option A')
expect(find_editor('Text')).to have_text_value('foo bar')
expect(find_editor('Text')).to have_text_value('', exact: true)
expect(find_editor('Text')).to have_data_value('<p>foo bar</p>')
expect(find_datepicker('Date')).to have_date(Date.today)
expect(find_datepicker('Date Time')).to have_datetime(DateTime.now)
expect(find_toggle('Boolean')).to be_toggled_on
```
