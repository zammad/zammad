// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'

import { generateFingerprint } from '#shared/utils/browser.ts'

const useFingerprint = () => {
  const fingerprint = useLocalStorage('fingerprint', '')

  if (!fingerprint.value) {
    fingerprint.value = generateFingerprint()
  }

  return {
    fingerprint,
  }
}

export default useFingerprint
