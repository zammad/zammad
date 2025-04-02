// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

const defaultSoundFile = 'Xylo.mp3'

export const useOnlineNotificationSound = () => {
  const { user } = storeToRefs(useSessionStore())

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

  const play = () =>
    audio.value?.play().catch(() => {
      console.error('Failed to play notification sound')
    })

  return {
    isEnabled,
    play,
  }
}
