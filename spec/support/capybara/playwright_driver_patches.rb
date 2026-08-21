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

  # Capybara reads - #text, #[], #visible? - run hundreds of times per example,
  #   and the gem spends 2-4 browser round trips on each one: #assert_element_
  #   not_stale fires a bare `enabled?` liveness probe before every read,
  #   #visible_text additionally calls #visible? (another probe + evaluate)
  #   before extracting the text, and #[] splits property and attribute lookup
  #   over three calls. Selenium needs one WebDriver command for each of these;
  #   measured on one desktop example the difference is 7,319 vs 1,195 round
  #   trips, and in CI every round trip crosses the Docker network to the
  #   browser service container. Fold each read into a single evaluate.
  #
  # The staleness contract stays intact: for a detached element the JS throws
  #   the exact message the gem's own rescue translates into
  #   StaleReferenceError, so Capybara's synchronize machinery reloads the node
  #   and retries the same as before.
  STALE_GUARD_JS = <<~JS.freeze
    if (!el.isConnected) throw new Error('Element is not attached to the DOM');
  JS

  # The gem's #visible? visibility walk, verbatim (non-interpolating heredoc:
  #   `${map_name}` is a JS template literal).
  IS_VISIBLE_JS = <<~'JS'.freeze
    function isVisible(el) {
      if (el.tagName == 'AREA'){
        const map_name = document.evaluate('./ancestor::map/@name', el, null, XPathResult.STRING_TYPE, null).stringValue;
        el = document.querySelector(`img[usemap='#${map_name}']`);
        if (!el){
          return false;
        }
      }
      var forced_visible = false;
      while (el) {
        const style = window.getComputedStyle(el);
        if (style.visibility == 'visible')
          forced_visible = true;
        if ((style.display == 'none') ||
            ((style.visibility == 'hidden') && !forced_visible) ||
            (parseFloat(style.opacity) == 0)) {
          return false;
        }
        var parent = el.parentElement;
        if (parent && (parent.tagName == 'DETAILS') && !parent.open && (el.tagName != 'SUMMARY')) {
          return false;
        }
        el = parent;
      }
      return true;
    }
  JS

  VISIBLE_JS = <<~JS.freeze
    (el) => {
      #{STALE_GUARD_JS}
      #{IS_VISIBLE_JS}
      return isVisible(el);
    }
  JS

  # Text extraction as in the gem's #visible_text, but the normalization keeps
  #   consecutive newlines: the gem's gsub(/\n+/, "\n") makes blank lines (e.g.
  #   empty editor lines between paragraphs) unobservable, which the Selenium
  #   drivers do observe - specs would need driver-conditional expectations.
  VISIBLE_TEXT_JS = <<~JS.freeze
    (el) => {
      #{STALE_GUARD_JS}
      #{IS_VISIBLE_JS}
      if (!isVisible(el)) {
        return '';
      }
      if (el.nodeName == 'TEXTAREA' || el instanceof SVGElement) {
        return el.textContent;
      }
      return el.innerText;
    }
  JS

  ALL_TEXT_JS = <<~JS.freeze
    (el) => {
      #{STALE_GUARD_JS}
      return el.textContent;
    }
  JS

  # Property first, attribute as fallback - same decision the gem makes in
  #   Ruby (`property(name) || attribute(name)`, where objects and functions
  #   are discarded), expressed with JS falsiness matching Ruby's.
  PROPERTY_OR_ATTRIBUTE_JS = <<~JS.freeze
    (el, name) => {
      #{STALE_GUARD_JS}
      let value = el[name];
      if (typeof value === 'object' || typeof value === 'function') {
        value = null;
      }
      if (value === null || value === undefined || value === false) {
        return el.getAttribute(name);
      }
      return value;
    }
  JS

  def visible?
    read_in_one_round_trip(VISIBLE_JS)
  end

  def visible_text
    text = read_in_one_round_trip(VISIBLE_TEXT_JS)
    text.to_s.scrub.gsub(%r{\A[[:space:]&&[^\u00a0]]+}, '')
        .gsub(%r{[[:space:]&&[^\u00a0]]+\z}, '')
        .tr("\u00a0", ' ')
  end

  def all_text
    text = read_in_one_round_trip(ALL_TEXT_JS)
    text.to_s.gsub(%r{[\u200b\u200e\u200f]}, '')
        .gsub(%r{[\ \n\f\t\v\u2028\u2029]+}, ' ')
        .gsub(%r{\A[[:space:]&&[^\u00a0]]+}, '')
        .gsub(%r{[[:space:]&&[^\u00a0]]+\z}, '')
        .tr("\u00a0", ' ')
  end

  def [](name)
    read_in_one_round_trip(PROPERTY_OR_ATTRIBUTE_JS, arg: name.to_s)
  end

  private

  def read_in_one_round_trip(script, arg: nil)
    @element.evaluate(script, arg: arg)
  rescue ::Playwright::Error => e
    # Route the error through the gem's translation table. Its leading
    #   `enabled?` probe runs only on this error path, never on the hot path.
    assert_element_not_stale { raise e }
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
  #
  # Asserting the caret narrows the race but cannot close it: the page's own
  #   timers keep running, and one firing between the assertion and the keystroke
  #   moves the caret again. That still happened in CI (tags_spec wrote
  #   '3New Tag 12'), so verify the result and repair it - see #set_text.

  private

  def set_text(text, append:)
    return super if append || text.include?("\t")

    case @element.evaluate('el => el.isContentEditable ? "contenteditable" : (el.type === "number" ? "number" : "")')
    when 'contenteditable'
      return super
    when 'number'
      return replace_number_text(text)
    end

    clusters   = text.scan(%r{\X})
    typed_text = clusters.last.to_s
    prefix     = clusters[0...-1].join

    @element.fill(prefix, timeout: @timeout)
    return if typed_text.empty?

    move_caret_to_end
    @element.type(typed_text, timeout: @timeout)

    observed = @element.input_value(timeout: @timeout)
    return if observed == text

    # Repair only a misplaced keystroke: the value has to be the prefix with the
    #   typed character inserted at some other position. Anything else belongs to
    #   the page - a keydown handler discarding the character, an input mask
    #   rewriting the value - and repairing that would put back what the page
    #   just refused, letting this driver quietly disagree with the Selenium ones
    #   instead of failing.
    return if misplaced_values(clusters).exclude?(observed)

    @element.fill(text, timeout: @timeout)
  end

  # Every value the field could hold if the typed character had landed at the
  #   wrong offset, built from grapheme clusters so multi-codepoint characters
  #   stay intact. Excludes the character being missing altogether, which is a
  #   refusal by the page rather than a misplacement.
  def misplaced_values(clusters)
    prefix_clusters = clusters[0...-1]

    (0..prefix_clusters.length).map do |index|
      (prefix_clusters[0...index] + [clusters.last] + prefix_clusters[index...]).join
    end
  end

  def move_caret_to_end
    @element.evaluate(<<~JS)
      (el) => {
        // Throws for input types that have no text selection (number, date, ...).
        try { el.setSelectionRange(el.value.length, el.value.length) } catch (e) {}
      }
    JS
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
