// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * Get the value of a Tailwind CSS variable from :root
 * @param variableName - The name of the CSS variable (e.g., '--color-green-400')
 * @returns The value of the CSS variable
 */

export const getTailwindStyleValue = (variableName: string) => {
  const styles = getComputedStyle(document.documentElement)

  return styles.getPropertyValue(variableName)
}
