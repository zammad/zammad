# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module PlaywrightNative
  module FormHelpers
    # The form field with this label, i.e. its FormKit outer element. Views kept alive in the
    #   background, like other taskbar tabs, keep their hidden fields.
    def field(label, within: page)
      within.locator('.formkit-outer', has: page.locator('label').get_by_text(label, exact: true)).filter(visible: true)
    end

    # The selected options of a select, autocomplete or tree select.
    def selected_options(label, within: page)
      field(label, within:).get_by_role('combobox').get_by_role('listitem')
    end

    def fill_field(label, value, within: page)
      outer = field(label, within:)

      after_form_update_of(outer) { outer.get_by_label(label, exact: true).fill(value) }
    end

    # The rich text editor of the field, a textbox named like it.
    def editor(label, within: page)
      field(label, within:).get_by_role('textbox', name: label)
    end

    # Types like a user: a string as text, a symbol presses the key of that name. A click focuses
    #   the editor only if it has no focus yet, so a cursor placed before stays where it is.
    def type_in_editor(label, *keys, within: page)
      outer   = field(label, within:)
      textbox = editor(label, within:)

      wait_for_editor_ready(textbox)
      textbox.click if !textbox.evaluate('(textbox) => textbox.contains(document.activeElement)')

      after_form_update_of(outer) do
        keys.each { |key| key.is_a?(Symbol) ? page.keyboard.press(key.to_s.camelize) : page.keyboard.type(key) }
      end
    end

    # Types the mention and picks the user from the suggestions, which subscribes them.
    def mention_in_editor(label, user, within: page)
      type_in_editor(label, "@@#{user.firstname}", within:)

      after_form_update_of(field(label, within:)) do
        page.get_by_role('listbox', name: 'Users').get_by_role('option', name: user.fullname).click
      end
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
    #   form renders the answer anew. A field teleported out of its form, like the ticket
    #   attributes in the sidebar, has no form around it, so any form of the page may answer.
    def after_form_update_of(field, &)
      return yield if field.get_attribute('data-triggers-form-updater') != 'true'

      forms = field.evaluate('outer => outer.closest("form") ? [outer.closest("form").id] : [...document.forms].map((form) => form.id)')

      await_form_updater(*forms, &)
    end

    # The form is aria-busy while its form updater request is open and sets a test flag once it
    #   has applied the answer. One answer can lead to the next request, so the change waits for
    #   quiet forms before and after.
    def await_form_updater(*forms)
      flags = forms.map { |form| "#{form}.formUpdater.applied" }

      wait_for_quiet_forms
      page.evaluate('(flags) => flags.forEach((flag) => window.testFlags.clear(flag))', arg: flags)

      yield

      begin
        page.wait_for_function('(flags) => flags.some((flag) => window.testFlags.get(flag))', arg: flags)
      rescue Playwright::TimeoutError
        raise "Form updater answer not applied to #{forms.join(', ')}"
      end
      wait_for_quiet_forms
    end

    private

    # Checked every frame, Playwright's expectations would wait up to a second between checks.
    def wait_for_quiet_forms
      page.wait_for_function('() => !document.querySelector("form[aria-busy]")')
    end

    # A menu that opens upwards grows from its bottom edge, a click on a moving option goes astray.
    def wait_for_menu_to_open(menu)
      page.wait_for_function(<<~JS, arg: menu.element_handle)
        (menu) => !document.getAnimations().some(({ effect, playState }) =>
          playState === 'running' && effect?.target && (effect.target.contains(menu) || menu.contains(effect.target)))
      JS
    end

    # The menu is teleported to the end of the document; the field's combobox names it in aria-controls.
    def choose_from_menu(label, within:)
      outer    = field(label, within:)
      combobox = outer.get_by_role('combobox')

      after_form_update_of(outer) do
        combobox.click

        menu = page.locator("##{combobox.get_attribute('aria-controls')}").get_by_role('menu')
        expect(menu).to be_visible
        wait_for_menu_to_open(menu)

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
