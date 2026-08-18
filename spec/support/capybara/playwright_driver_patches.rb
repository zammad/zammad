# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# THROWAWAY PILOT: targeted compensations for capybara-playwright-driver gaps,
#   each aligning the Playwright driver with the Selenium drivers' behavior so
#   specs can stay driver-agnostic. Kept in one place on purpose - candidates
#   for upstreaming, not a pattern to extend casually.

require 'capybara/playwright'

# The patches below reach into gem internals, so they are written against this
#   exact version. On an upgrade: check whether they were fixed upstream, drop
#   what is obsolete, then bump the pin here.
if Gem.loaded_specs['capybara-playwright-driver'].version != Gem::Version.new('0.5.10')
  raise 'capybara-playwright-driver was updated - re-evaluate the patches in ' \
        "#{__FILE__} against the new version, then adjust the version pin."
end

module ZammadCapybaraPlaywrightNodePatches
  # Most node operations are wrapped in the gem's #assert_element_not_stale,
  #   which translates raw Playwright errors for detached/navigated-away
  #   elements into StaleReferenceError - a member of the driver's
  #   invalid_element_errors, which Capybara's synchronize machinery rescues,
  #   reloads the node for and retries (just like Selenium's
  #   StaleElementReferenceError). These action methods lack the wrapper, so
  #   e.g. a list row torn down and re-rendered between find and click
  #   surfaces as a raw Playwright::Error that nothing retries. Route them
  #   through the same translation.
  %i[click right_click double_click hover obscured? drag_to].each do |method_name|
    define_method(method_name) do |*args, **options, &block|
      assert_element_not_stale { super(*args, **options, &block) }
    end
  end

  # The gem collapses consecutive newlines of an element's innerText
  #   (gsub(/\n+/, "\n")), which the Selenium drivers do not - blank lines
  #   (e.g. empty editor lines between paragraphs) become unobservable and
  #   would need driver-conditional expectations in specs. Same implementation
  #   as the gem's, minus that one gsub.
  def visible_text
    assert_element_not_stale do
      break '' if !visible?

      text = @element.evaluate(<<~JAVASCRIPT)
        function(el){
          if (el.nodeName == 'TEXTAREA'){
            return el.textContent;
          } else if (el instanceof SVGElement) {
            return el.textContent;
          } else {
            return el.innerText;
          }
        }
      JAVASCRIPT
      text.to_s.scrub.gsub(%r{\A[[:space:]&&[^\u00a0]]+}, '')
          .gsub(%r{[[:space:]&&[^\u00a0]]+\z}, '')
          .tr("\u00a0", ' ')
    end
  end
end

Capybara::Playwright::Node.prepend(ZammadCapybaraPlaywrightNodePatches)

module ZammadCapybaraPlaywrightTextInputPatches
  # The gem writes a value in two steps - #fill for everything but the last
  #   character, then #type for that last one, so key handlers see a real
  #   keystroke. #type focuses the element first, and a focus can put the caret
  #   at offset 0 (same reason a fresh field ignores :backspace), so if the page
  #   reacts to #fill's input event by re-rendering or refocusing, the final
  #   character is inserted at the *start* of the field. Nothing raises - the
  #   field just ends up holding a different value than the spec asked for
  #   (observed in CI: 'tag1, tag2, tag3' became '3tag1, tag2, tag').
  #
  # Re-assert the caret between the two steps, via the Selection API rather than
  #   an End keypress: End is meaningful to ARIA widgets (a listbox jumps to its
  #   last option), so pressing it changes behaviour in e.g. the desktop
  #   treeselect search. This way the page sees exactly the key events the
  #   unpatched gem would produce. Only the plain single-line case is handled
  #   here; everything else stays with the gem.

  private

  def set_text(text, append:)
    return super if append || text.include?("\t")
    return super if @element.evaluate('el => el.isContentEditable')
    return replace_number_text(text) if @element.evaluate('el => el.type === "number"')

    clusters   = text.scan(%r{\X})
    typed_text = clusters.last.to_s

    @element.fill(clusters[0...-1].join, timeout: @timeout)
    return if typed_text.empty?

    @element.evaluate(<<~JS)
      (el) => {
        // Throws for input types that have no text selection (number, date, ...).
        try { el.setSelectionRange(el.value.length, el.value.length) } catch (e) {}
      }
    JS
    @element.type(typed_text, timeout: @timeout)
  end

  # Playwright's #fill validates a number input against the HTML5 number grammar,
  #   so filling everything but the last character throws for values like '-7'
  #   ("Cannot type text into input[type=number]"). Select the current value and
  #   type over it instead, which also keeps the keystrokes intact. Same approach
  #   the gem takes upstream (capybara-playwright-driver#152), not yet released.
  def replace_number_text(text)
    return @element.fill('', timeout: @timeout) if text.empty?

    @element.select_text(timeout: @timeout)
    @element.type(text, timeout: @timeout)
  end
end

Capybara::Playwright::Node::TextInput.prepend(ZammadCapybaraPlaywrightTextInputPatches)
