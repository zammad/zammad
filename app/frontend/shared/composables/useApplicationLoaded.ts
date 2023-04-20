// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

const loaded = ref(false)

export const useApplicationLoaded = () => {
  return {
    loaded,
  }
}
