// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { generateFingerprint } from '@shared/utils/browser'

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
