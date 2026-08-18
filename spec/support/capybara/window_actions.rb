# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module WindowActions

  delegate :app_host, to: Capybara

  # This is a convenient wrapper method around #switch_to_window
  # which switch to an given window index, waiting for it to appear
  # first (e.g. right after triggering a new tab/window via a click,
  # it may not be registered in Capybara's #windows list yet).
  #
  # @example
  #  switch_to_window_index(2)
  # => switch to window index 2
  #
  def switch_to_window_index(index)
    window = wait.until { windows[index - 1] }

    switch_to_window(window)
  end

  # This is a convenient wrapper method around #close window
  # which will close the given window index, waiting for it to appear
  # first (see #switch_to_window_index).
  # If only one window is still open afterwards it will switch to it.
  #
  # @example
  #  close_window_index(2)
  # => close window with index 2
  #
  def close_window_index(index)
    window = wait.until { windows[index - 1] }

    window.close

    switch_to_window(windows[0]) if windows.length == 1
  end

  # This is a convenient wrapper method around #open_new_window
  # which open a new window and switched directly to it
  #
  # @example
  #  open_window_and_switch
  # => open new window and switch to this window
  #
  def open_window_and_switch
    window = open_new_window

    switch_to_window(window)
  end
end

RSpec.configure do |config|
  config.include WindowActions, type: :system
end
