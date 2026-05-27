// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { breakpointsTailwind, useBreakpoints } from '@vueuse/core'

export const useAppBreakpoints = () => {
  const breakpoints = useBreakpoints(breakpointsTailwind)
  const isSmallScreen = breakpoints.smaller('lg')
  const isSmallestScreen = breakpoints.smaller('md')

  return {
    isSmallScreen,
    isSmallestScreen,
  }
}
