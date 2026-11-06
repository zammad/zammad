# How to Test with RSpec and Playwright

System specs of the desktop view and of the mobile app are written directly against
[Playwright](https://playwright.dev) through
[playwright-ruby-client](https://playwright-ruby-client.vercel.app), without Capybara.
RSpec stays: factories, `let`, contexts and checks against the database work as in
every other spec. Specs of the legacy (CoffeeScript) app keep using Capybara, see
[How to test with RSpec / Capybara](how-to-test-with-rspec-and-capybara.md).

## Running

```bash
TEST_BROWSER_HEADLESS=1 RAILS_ENV=test VITE_TEST_MODE=1 bundle exec rspec spec/system/apps/desktop/ticket/create_spec.rb
```

- `TEST_BROWSER=firefox` runs the spec in Playwright's Firefox instead of Chromium.
- Locally, a one-time `pnpm playwright:install` downloads Chromium
  (`pnpm exec playwright install firefox` for Firefox).
- The app is served on `TEST_APP_PORT` (default `3002`), next to the Capybara specs.
- A failed example leaves a screenshot in `tmp/screenshots/` and a trace in
  `tmp/playwright-traces/`. Open the trace with
  `pnpm exec playwright show-trace <file>`: every step with the page as it was.

## Writing a spec

Mark the spec with `type: :playwright`:

```ruby
RSpec.describe 'Desktop > Ticket > Create', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  it 'creates a new ticket' do
    open_desktop('/ticket/create')
    wait_for_form_to_settle('ticket-create')

    fill_field('Title', 'Example Ticket Title')
    search_for_option('Customer', customer.email, option: customer.fullname)
    select_option('Priority', '3 high')

    page.get_by_role('button', name: 'Create', exact: true).click

    expect(notification('Ticket has been created successfully')).to be_visible
    expect(Ticket.last).to have_attributes(title: 'Example Ticket Title')
  end
end
```

Each example gets a fresh browser context. `page` is the Playwright page, like in
Playwright for JavaScript and Python, so the
[Playwright documentation](https://playwright.dev/docs/locators) applies directly.

`open_desktop(route)` and `open_mobile(route)` open a route of the app and wait until it
has loaded. An example with `app: :mobile` runs in a phone-sized viewport.

### Several tabs

`open_tab` opens another tab of the same browser, it shares the login and the storage
with `page`. The helpers act on `page`, `on_tab` lets them act on the other tab:

```ruby
open_desktop("/tickets/#{ticket.id}")

other_tab = open_tab
on_tab(other_tab) { open_desktop("/tickets/#{ticket.id}") }

select_option('Priority', '3 high')

on_tab(other_tab) do
  expect(selected_options('Priority')).to have_text('3 high')
end
```

### Logging in

Examples start logged in as the `authenticated_as` user. With `authenticated_as: false`,
`sign_in(username:, password:, remember_me:)` fills the login form of the desktop view and
of the mobile app.

### Finding elements

Find elements like assistive technology does: by role and accessible name, form
fields by their label. Avoid CSS classes, ids and `data-test-id`.

```ruby
page.get_by_role('button', name: 'Create', exact: true)
main_content.get_by_role('link', name: '+49 30 609854180')
flyout('New user').get_by_label('First name')
```

If an element cannot be found this way, it often lacks an accessible name in the
app. Prefer fixing the app over a CSS selector.

Page areas (`spec/support/playwright/page_areas.rb`):

| Helper                | Finds                                             |
| --------------------- | ------------------------------------------------- |
| `main_content`        | the main area                                     |
| `page_navigation`     | the left navigation                               |
| `main_sidebar`        | the left sidebar with the quick search            |
| `content_sidebar`     | the sidebar next to the content, e.g. of a ticket |
| `flyout(title)`       | the flyout with this title                        |
| `notification(text)`  | the notification with this text                   |
| `table_rows(caption)` | the body rows of the table with this caption      |

### Forms

The form helpers (`spec/support/playwright/form_helpers.rb`) find a field by its
label and take `within:` to look inside a flyout or dialog:

```ruby
fill_field('First name', 'Erika', within: flyout('New user'))
select_option('Priority', '3 high')
search_for_option('Group', group.name)                  # autocompletes and tree selects
search_for_option('CC', email) { |menu| menu.get_by_role('button').click }
expect(selected_options('Priority')).to have_text('3 high')
```

The helpers only see visible fields: views kept alive in the background, like other
taskbar tabs, keep their hidden fields.

A field that triggers the form updater waits for the server's answer on its own, so
specs never count form updater calls. A form is `aria-busy` while a form updater request
is open and sets the test flag `<form>.formUpdater.applied` once it has applied the
answer. The helpers wait for that flag and for no busy form before and after a change,
as one answer can lead to the next request. A field teleported out of its form, like the
ticket attributes in the sidebar, waits for any form of the page. Use
`await_form_updater('ticket-create') { … }` only for an action outside a field, e.g.
applying a template.

### Checking

`Playwright::Test::Matchers` wait until the expectation holds:

```ruby
expect(main_content).to contain_text('Franz Bauer')         # part of the text
expect(page.get_by_role('heading', level: 1)).to have_text('New ticket')  # whole text
expect(table_rows('Caller log')).to have_count(2)
expect(page).to have_url(%r{/desktop/tickets/\d+$})
expect(main_content).to not_contain_text('Ringing…')
```

- `have_text` compares the whole text, `contain_text` a part of it.
  playwright-ruby-client up to 1.64 still matches a part with `have_text` as well
  ([#401](https://github.com/YusukeIwaki/playwright-ruby-client/issues/401)),
  so write the one that fits now.
- Negations are `not_…` matchers (`not_contain_text`, `not_have_value`).
- Text is compared as `textContent`, without line breaks between blocks.
- Regular expressions use `^` and `$` for the start and the end; Ruby's `\A` and `\z`
  do not reach the browser.
- The matchers take over RSpec's `be_empty`, `be_visible` and others: compare plain
  Ruby arrays with `eq([])`.
- Option names are camelCase, as in JavaScript: `filter(hasText: 'Text')`.

### Waiting for the app

`spec/support/playwright/test_flags.rb` waits for the app's test flags:
`wait_for_query`, `wait_for_mutation`, `wait_for_subscription_start`,
`wait_for_form_to_settle`, `wait_for_test_flag`; `test_flag_set?` checks a flag without
waiting. For state outside the browser, e.g. the database, use
`wait_until { missed_call.reload.done }`.
