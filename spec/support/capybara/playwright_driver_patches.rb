# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# THROWAWAY PILOT: targeted compensations for capybara-playwright-driver gaps,
#   each aligning the Playwright driver with the Selenium drivers' behavior so
#   specs can stay driver-agnostic. Kept in one place on purpose - candidates
#   for upstreaming, not a pattern to extend casually.

require 'capybara/playwright'

# The patches below reach into gem internals, so they are written against this
#   exact version. On an upgrade: check whether they were fixed upstream, drop
#   what is obsolete, then bump the pin here.
if Gem.loaded_specs['capybara-playwright-driver'].version != Gem::Version.new('0.5.12')
  raise 'capybara-playwright-driver was updated - re-evaluate the patches in ' \
        "#{__FILE__} against the new version, then adjust the version pin."
end

module ZammadCapybaraPlaywrightNodePatches
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

  VISIBLE_TEXT_JS = <<~JS.freeze
    (el) => {
      #{STALE_GUARD_JS}
      #{IS_VISIBLE_JS}
      if (!isVisible(el)) {
        return '';
      }
      if (el.nodeName == 'TEXTAREA') {
        return el.textContent;
      }
      if (el instanceof SVGElement) {
        return el.textContent.replace(/\\n+/g, '\\n');
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
