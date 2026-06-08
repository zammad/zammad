// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { noop } from 'lodash-es'
import { computed, toRef } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

const defaultSoundFile = 'Xylo.mp3'

export const useOnlineNotificationSound = () => {
  const user = toRef(useSessionStore(), 'user')

  const isEnabled = computed(
    () => Boolean(user.value?.preferences?.notification_sound?.enabled ?? true), // it is enabled by default for new users
  )

  const audioPath = computed(() => {
    const fileName = user.value?.preferences?.notification_sound?.file
    return `/assets/sounds/${fileName ?? defaultSoundFile}`
  })

  const getPreloadedAudio = (path: string) => {
    const sound = new Audio(path)
    sound.preload = 'auto'
    return sound
  }

  const audio = computed(() => getPreloadedAudio(audioPath.value))

  const play = () => audio.value?.play().catch(noop)

  return {
    isEnabled,
    play,
  }
}
