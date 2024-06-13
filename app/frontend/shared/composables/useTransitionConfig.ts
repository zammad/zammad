// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getAbstracts } from '#shared/initializer/initializeAbstracts.ts'

export const useTransitionConfig = () => {
  const durations = {
    normal: VITE_TEST_MODE ? undefined : getAbstracts().durations.normal,
  }

  const isTestMode = VITE_TEST_MODE

  return { durations, isTestMode }
}
