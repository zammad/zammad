# How to Test With QUnit

Some tests of the JS API are implemented in QUnit.

## Running

- You can reach individual test pages directly at `host:3000/tests_name`
- Whole suite via `rspec spec/system/js/q_unit_spec.rb`
- Single file via `QUNIT_TEST=name rspec spec/system/js/q_unit_spec.rb`

Opening directly depends on browser settings for timezone and locale. Running via rspec sets timezone and locale.

## Tooling

- [QUnit unit tests](http://qunitjs.com)
- [Sinon mocking https](//sinonjs.org)
- [Syn events simulating](https://github.com/bitovi/syn)

## Major bits

- Mandatory: `name.js` file in [public/assets/tests/qunit/](/public/assets/tests/qunit/)
- Optional: `name.html.erb` file [app/views/tests/](/app/views/tests/)

## HTML template logic

- Defaults to `app/views/tests/show.html.erb`
- `form_*` tests default to `app/views/tests/form.html.erb`
- Picks `name.html.erb`
