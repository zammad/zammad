// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// TODO add light color, if we have light theme
// TODO toggle color, if we have light theme
export const useAppTheme = () => {
  const meta =
    document.head.querySelector('meta[name="theme-color"]') ||
    document.createElement('meta')

  meta.setAttribute('name', 'theme-color')
  meta.setAttribute('content', '#191919')

  if (!document.head.contains(meta)) {
    document.head.appendChild(meta)
  }
}
