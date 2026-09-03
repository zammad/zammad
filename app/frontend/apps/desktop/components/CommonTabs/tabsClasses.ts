// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Shared styling for the items rendered inside a CommonScrollList (CommonTab buttons
// and CommonNavigationTabs links), so both stay visually in sync.
export const tabItemClasses =
  'inline-flex w-full cursor-pointer disabled:cursor-not-allowed items-center gap-1 border-0 bg-transparent text-nowrap text-gray-100 dark:text-neutral-400'

/**
 * The container width at which a tab strip stops being a row of equally stretched icons and
 * becomes tabs sized to their own content, each with its label beside the icon.
 *
 * Which one a strip wants depends on how much room it is given and how long its labels are, not
 * on the window — a bar that also carries buttons has far less room for labels than a strip that
 * has a row to itself, and the same strip in another language has longer ones. A strip whose
 * labels would be cramped picks a larger breakpoint and stays on icons for longer.
 */
export type TabsLabelBreakpoint = 'md' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl'

/**
 * The four places the breakpoint has to reach, per value. Spelled out rather than interpolated
 * into the breakpoint name: Tailwind generates a utility only where it can read the whole class
 * out of the source.
 *
 * - `group` — the strip shrinks to its content instead of filling the row
 * - `listItem` / `item` — a tab is sized by its content instead of taking an equal share
 * - `align` — the tabs sit at the start rather than centered in their share
 * - `label` — the label joins the icon (`whitespace-nowrap` because `not-sr-only` resets
 *   `white-space` to `normal`, which would otherwise wrap the label over the icon)
 */
export const tabsLabelBreakpointClasses: Record<
  TabsLabelBreakpoint,
  { group: string; listItem: string; item: string; align: string; label: string }
> = {
  md: {
    group: '@md:w-fit',
    listItem: '@md:grow-0',
    item: '@md:w-auto',
    align: '@md:justify-start',
    label: 'sr-only whitespace-nowrap @md:not-sr-only',
  },
  lg: {
    group: '@lg:w-fit',
    listItem: '@lg:grow-0',
    item: '@lg:w-auto',
    align: '@lg:justify-start',
    label: 'sr-only whitespace-nowrap @lg:not-sr-only',
  },
  xl: {
    group: '@xl:w-fit',
    listItem: '@xl:grow-0',
    item: '@xl:w-auto',
    align: '@xl:justify-start',
    label: 'sr-only whitespace-nowrap @xl:not-sr-only',
  },
  '2xl': {
    group: '@2xl:w-fit',
    listItem: '@2xl:grow-0',
    item: '@2xl:w-auto',
    align: '@2xl:justify-start',
    label: 'sr-only whitespace-nowrap @2xl:not-sr-only',
  },
  '3xl': {
    group: '@3xl:w-fit',
    listItem: '@3xl:grow-0',
    item: '@3xl:w-auto',
    align: '@3xl:justify-start',
    label: 'sr-only whitespace-nowrap @3xl:not-sr-only',
  },
  '4xl': {
    group: '@4xl:w-fit',
    listItem: '@4xl:grow-0',
    item: '@4xl:w-auto',
    align: '@4xl:justify-start',
    label: 'sr-only whitespace-nowrap @4xl:not-sr-only',
  },
}

export const DEFAULT_TABS_LABEL_BREAKPOINT: TabsLabelBreakpoint = 'lg'

export const tabItemFontSize = {
  small: 'text-xs leading-snug',
  medium: 'text-sm leading-snug',
  large: 'text-base leading-snug',
} as const

export const tabItemIconSize = {
  small: 'xs',
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
