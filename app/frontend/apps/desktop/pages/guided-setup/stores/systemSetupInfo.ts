// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import { defineStore } from 'pinia'
import { useLocalStorage } from '@vueuse/core'

import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import type { SystemSetupInfoStorage } from '../types/setup-info.ts'
import { useSystemSetupInfoLazyQuery } from '../graphql/queries/systemSetupInfo.api.ts'
import { useSystemSetupUnlockMutation } from '../graphql/mutations/systemSetupUnlock.api.ts'

export const useSystemSetupInfoStore = defineStore('systemSetupInfo', () => {
  const systemSetupInfo = useLocalStorage<SystemSetupInfoStorage>(
    'systemSetupInfo',
    {},
  )

  const setSystemSetupInfo = async () => {
    const systemSetupInfoQuery = new QueryHandler(
      useSystemSetupInfoLazyQuery({
        fetchPolicy: 'network-only',
      }),
    )

    const systemSetupInfoResult = await systemSetupInfoQuery.query()
    const newSystemSetupInfo = systemSetupInfoResult.data?.systemSetupInfo

    if (newSystemSetupInfo) {
      systemSetupInfo.value = {
        ...systemSetupInfo.value,
        type:
          systemSetupInfo.value.type === EnumSystemSetupInfoType.Import &&
          newSystemSetupInfo.type === EnumSystemSetupInfoType.Manual
            ? systemSetupInfo.value.type
            : newSystemSetupInfo.type,
        status: newSystemSetupInfo.status,
      }
    }
  }

  const application = useApplicationStore()

  const getSystemSetupInfoRedirectPath = (
    status?: string,
    type?: string,
    lockValue?: string,
  ) => {
    if (!status || status === EnumSystemSetupInfoStatus.New)
      return '/guided-setup'

    if (status === EnumSystemSetupInfoStatus.Automated) {
      return '/guided-setup/automated'
    }

    if (status === EnumSystemSetupInfoStatus.InProgress) {
      if (!type) return '/guided-setup'

      if (type === EnumSystemSetupInfoType.Manual) {
        if (lockValue && type === 'manual') {
          return '/guided-setup/manual'
        }

        // TODO: show some message on the start page instead of selection?
        return '/guided-setup'
      }

      if (type === EnumSystemSetupInfoType.Import) {
        // TODO: use real route
        // TODO: check when "import_backend" is saved, maybe we need to have some fallback...
        return `/guided-setup/import/${application.config.import_backend}`
      }
    }

    return '/guided-setup'
  }

  const redirectPath = computed(() => {
    const { status, type, lockValue } = systemSetupInfo.value

    return getSystemSetupInfoRedirectPath(status, type || '', lockValue)
  })

  const redirectNeeded = (currentRoutePath: string) => {
    // Allow sub-paths for auto wizard execution
    if (systemSetupInfo.value.status === EnumSystemSetupInfoStatus.Automated) {
      return !currentRoutePath.startsWith(redirectPath.value)
    }

    return currentRoutePath !== redirectPath.value
  }

  const systemSetupDone = computed(() => {
    const { status } = systemSetupInfo.value

    return (
      status === EnumSystemSetupInfoStatus.Done ||
      application.config.system_init_done
    )
  })

  const systemSetupAlreadyStarted = computed(() => {
    const { status, lockValue } = systemSetupInfo.value

    return status === EnumSystemSetupInfoStatus.InProgress && !lockValue
  })

  const systemSetupUnlock = (callback: () => void) => {
    const { lockValue } = systemSetupInfo.value

    if (!lockValue) return

    const unlockMutation = new MutationHandler(
      useSystemSetupUnlockMutation({
        variables: {
          value: lockValue,
        },
      }),
    )

    unlockMutation
      .send()
      .then(() => {
        systemSetupInfo.value = {}

        callback()
      })
      .catch(() => {})
  }

  return {
    redirectPath,
    redirectNeeded,
    setSystemSetupInfo,
    systemSetupUnlock,
    systemSetupInfo,
    systemSetupDone,
    systemSetupAlreadyStarted,
  }
})
