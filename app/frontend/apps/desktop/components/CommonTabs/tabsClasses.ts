// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Shared styling for the items rendered inside a CommonScrollList (CommonTab buttons
// and CommonNavigationTabs links), so both stay visually in sync.
export const tabItemClasses =
  'inline-flex cursor-pointer disabled:cursor-not-allowed items-center gap-1 border-0 bg-transparent text-sm! text-nowrap text-gray-100 dark:text-neutral-400'

export const tabItemFontSize = {
  medium: 'text-sm leading-snug',
  large: 'text-base leading-snug',
} as const

export const tabItemIconSize = {
  medium: 'tiny',
  large: 'small',
} as const

/**
 * @param hasMarker whether the tabs draws the sliding marker pill behind the active
 *   item. When it does (single tabs, navigation) the item stays transparent; when it
 *   doesn't (multiselect options) the active item paints its own background.
 */
export const tabItemColorClasses = (active: boolean, disabled?: boolean, hasMarker = true) => {
  if (active) return `${hasMarker ? '' : 'bg-white dark:bg-gray-200'} text-black! dark:text-white!`

  if (disabled) return 'text-stone-200 dark:text-neutral-500'

  return 'not-disabled:hover:text-black not-disabled:hover:dark:text-white'
}
