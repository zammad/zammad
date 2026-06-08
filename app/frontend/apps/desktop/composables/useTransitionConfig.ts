// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export const useTransitionConfig = () => {
  const durations = {
    normal: { enter: 300, leave: 200 },
  }

  const timings = {
    short: 200,
    veryShort: 100,
  }

  return { durations, timings }
}
