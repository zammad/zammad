# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module PlaywrightNative
  module FormHelpers
    # The form field with this label, i.e. its FormKit outer element.
    def field(label, within: page)
      within.locator('.formkit-outer', has: page.locator('label').get_by_text(label, exact: true))
    end

    def fill_field(label, value, within: page)
      outer = field(label, within:)

      after_form_update_of(outer) { outer.get_by_label(label, exact: true).fill(value) }
    end

    def select_option(label, option, within: page)
      choose_from_menu(label, within:) do |_combobox, menu|
        menu.get_by_role('option', name: option).click
      end
    end

    # For autocompletes and tree selects. With a block, the block picks from the menu.
    def search_for_option(label, query, option: query, within: page)
      choose_from_menu(label, within:) do |combobox, menu|
        combobox.get_by_role('searchbox').fill(query)
        next yield menu if block_given?

        menu.get_by_role('option', name: option).click
      end
    end

    # A field marked data-triggers-form-updater asks the server again after a change, and the
    #   form renders the answer anew.
    def after_form_update_of(field, &)
      return yield if field.get_attribute('data-triggers-form-updater') != 'true'

      await_form_updater(field.evaluate('outer => outer.closest("form").id'), &)
    end

    # The form is aria-busy while its form updater request is open and sets a test flag once it
    #   has applied the answer. One answer can lead to the next request, so the change waits for
    #   quiet forms before and after.
    def await_form_updater(form)
      wait_for_quiet_forms
      page.evaluate('(flag) => window.testFlags.clear(flag)', arg: "#{form}.formUpdater.applied")

      yield

      wait_for_test_flag("#{form}.formUpdater.applied")
      wait_for_quiet_forms
    end

    private

    # Checked every frame, Playwright's expectations would wait up to a second between checks.
    def wait_for_quiet_forms
      page.wait_for_function('() => !document.querySelector("form[aria-busy]")')
    end

    # The menu is teleported to the end of the document; the field's combobox names it in aria-controls.
    def choose_from_menu(label, within:)
      outer    = field(label, within:)
      combobox = outer.get_by_role('combobox')

      after_form_update_of(outer) do
        combobox.click

        menu = page.locator("##{combobox.get_attribute('aria-controls')}").get_by_role('menu')
        expect(menu).to be_visible

        yield combobox, menu

        page.keyboard.press('Escape') if menu.visible?
        expect(menu).to have_count(0)
      end
    end
  end
end

RSpec.configure do |config|
  config.include PlaywrightNative::FormHelpers, type: :playwright
end
