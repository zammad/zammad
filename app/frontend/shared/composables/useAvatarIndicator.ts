// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useDateFormat } from '@vueuse/shared'
import { computed, toValue, type MaybeRef } from 'vue'

import type {
  AvatarUser,
  AvatarUserAccess,
  AvatarUserLive,
} from '#shared/components/CommonUserAvatar/types.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import { useAppName } from './useAppName.ts'
import { useReactiveNow } from './useReactiveNow.ts'

export const useAvatarIndicator = (
  entity: MaybeRef<AvatarUser>,
  personal?: MaybeRef<boolean>,
  live?: MaybeRef<AvatarUserLive | undefined>,
  access?: MaybeRef<AvatarUserAccess | undefined>,
) => {
  const appName = useAppName()
  const currentDate = useReactiveNow()

  const isOutOfOffice = computed(() => {
    const user = toValue(entity)

    if (user.outOfOffice && user.outOfOfficeStartAt && user.outOfOfficeEndAt) {
      const today = useDateFormat(currentDate.value, 'YYYY-MM-DD')
      const startDate = user.outOfOfficeStartAt
      const endDate = user.outOfOfficeEndAt

      return startDate <= today.value && endDate >= today.value // Today is between start and end date
    }
    return false
  })

  const isInactive = computed(() => toValue(entity).active === false)

  const isWithoutAccess = computed(
    () => toValue(access)?.agentReadAccess === false,
  )

  const isLiveUserIdle = computed(() => toValue(live)?.isIdle)
  const isLiveUserEditing = computed(() => toValue(live)?.editing)

  const isLiveUserDesktop = computed(
    () => toValue(live)?.app === EnumTaskbarApp.Desktop,
  )

  const isLiveUserMobile = computed(
    () => toValue(live)?.app === EnumTaskbarApp.Mobile,
  )

  const indicatorIcon = computed(() => {
    if (isInactive.value) return 'avatar-indicator-inactive'
    if (isWithoutAccess.value) return 'avatar-indicator-without-access'
    if (isOutOfOffice.value) return 'avatar-indicator-out-of-office'

    if (isLiveUserEditing.value && isLiveUserDesktop.value)
      return 'avatar-indicator-editing-desktop'

    if (isLiveUserEditing.value && isLiveUserMobile.value)
      return 'avatar-indicator-editing-mobile'

    if (isLiveUserDesktop.value && appName !== 'desktop')
      return 'avatar-indicator-desktop'

    if (isLiveUserMobile.value && appName !== 'mobile')
      return 'avatar-indicator-mobile'

    if (isLiveUserIdle.value) return 'avatar-indicator-idle'
    return null
  })

  const indicatorLabel = computed(() => {
    if (isInactive.value) return i18n.t('User is inactive')
    if (isWithoutAccess.value) return i18n.t('User has no access')

    if (isOutOfOffice.value && toValue(personal))
      return i18n.t('Out of office active')

    if (isOutOfOffice.value) return i18n.t('User is out of office')

    if (isLiveUserEditing.value && isLiveUserDesktop.value)
      return i18n.t('User is editing on desktop')

    if (isLiveUserEditing.value && isLiveUserMobile.value)
      return i18n.t('User is editing on mobile')

    if (isLiveUserEditing.value) return i18n.t('User is editing')

    if (isLiveUserDesktop.value && appName !== 'desktop')
      return i18n.t('User is on desktop')

    if (isLiveUserMobile.value && appName !== 'mobile')
      return i18n.t('User is on mobile')

    if (isLiveUserIdle.value) return i18n.t('User is idle')

    return undefined
  })

  const indicatorIsIdle = computed(
    () =>
      isInactive.value ||
      isOutOfOffice.value ||
      isWithoutAccess.value ||
      isLiveUserIdle.value,
  )

  return {
    isInactive,
    isLiveUserDesktop,
    isLiveUserEditing,
    isLiveUserIdle,
    isLiveUserMobile,
    isOutOfOffice,
    isWithoutAccess,
    indicatorIcon,
    indicatorLabel,
    indicatorIsIdle,
  }
}
