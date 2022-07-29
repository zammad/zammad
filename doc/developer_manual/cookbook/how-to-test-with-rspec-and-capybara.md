# How to Test with RSpec and Capybara

RSpec is the recommended way of writing back end tests for Zammad,
and in combination with Capybara also Selenium based end-to-end tests.

This page explains some Zammad specific extensions that make testing easier.

## Running

To run tests locally in the test environment, you need to first ensure the `test` database is in the expected state:

```sh
$ RAILS_ENV=test bundle exec rake db:drop db:create zammad:ci:test:prepare
```

Now, running a single test can be done via the following command:

```sh
$ bundle exec rspec spec/system/ticket/zoom_spec.rb
```

Note that it's also possible to run a specific test case by including the line number in the command:

```sh
$ bundle exec rspec spec/system/ticket/zoom_spec.rb:1072
```

If you would like to specify the used browser for Capybara end-to-end tests, simply set the `BROWSER` environment variable:

```sh
BROWSER=firefox bundle exec rspec spec/system/ticket/zoom_spec.rb
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

Takes boolean, symbol or lambda. Symbol is a method name to be executed. Works for  RSpec's `let` too! Lambda or referenced method are expected to return `User` object or a boolean.

`true` is the default value. It logs in with `admin@example.com` admin user. If a `User` is returned, it attempts to login with it. `false` causes to skip logging in altogether.

Lambda or referenced method is evaluated before web page is loaded. Thus this is a good place to prepare for the test. For example to set `Setting`.

### `time_zone`

Allows to set custom time zone. Takes Rails timezone names. Beware that it sets timezone for the server process. Browser in CI is not affected.

Example usage: `Rspec.describe :example, time_zone: 'Vilnius/Lithuania'`

### `db_strategy: :reset / :reset_all`

RSpec resets database using transaction after each example. But DBs can't handle some changes (e.g. altering schema) this way. MySQL is especially bad at this.

- `db_strategy: :reset` will reset database after each example
- `db_strategy: :reset_all` will reset database only once after whole context! This is a great way to increase performance. But easy to shoot yourself in a foot too! Use custom `before :all` and `after :all` to setup and tear down environment

### `performs_jobs`

ActiveJob background jobs are not performed automatically outside of `spec/jobs`! If you want to run `performs_jobs` in other  Specs, please do following:

```ruby
context 'example', performs_jobs: true
```

### `required_envs`

Checks if required ENVs are present. Raises error if one of them is missing. Since most ENV variables are credentials for 3rd party services, given variables are filtered from VCR cassettes too.

```ruby
context 'example', required_envs: %w[FACEBOOK_ADMIN_USER_ID FACEBOOK_ADMIN_FIRSTNAME]
```

## Capybara Helpers

### `await_empty_ajax_queue`

Forces test to wait for JQuery ajax requests to finish. After the last request is finished, it waits for another 0.5s. Effectively giving time for response to render. Great to use in `TicketZoom` and other complicated views.

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

Waits till connection to websocket is established. Sometimes actions rely on Websocket. But Capybara may be too fast and execution action before Websocket is established

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

When `expect` is called in the given block, `in_modal` does not wait for modal to close. It assumes the intention was to test something in the modal and closing it is not relevant.

### `wait`

Wait for block to return expected value. Supports `#until`, `#until_appears`, `#until_disappears`, `#until_constant`

## Capybara Selectors

### `have_* / have_no_*`

Capybara selectors wait for few seconds to see if expectation is fulfilled or not. Thus `expect(page).to have_no_selector()` is much much faster than `expect(page).not_to have_selector()`

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
