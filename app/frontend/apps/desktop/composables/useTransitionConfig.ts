// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export const useTransitionConfig = () => {
  const durations = {
    normal: VITE_TEST_MODE ? undefined : { enter: 300, leave: 200 },
  }

  return { durations }
}
