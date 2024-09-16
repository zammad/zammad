// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { defineStore } from 'pinia'
import { computed } from 'vue'

import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { useSystemSetupUnlockMutation } from '../graphql/mutations/systemSetupUnlock.api.ts'
import { useSystemSetupInfoLazyQuery } from '../graphql/queries/systemSetupInfo.api.ts'

import type { SystemSetupInfoStorage } from '../types/setup-info.ts'

export const useSystemSetupInfoStore = defineStore('systemSetupInfo', () => {
  const systemSetupInfo = useLocalStorage<SystemSetupInfoStorage>(
    'systemSetupInfo',
    {},
  )

  const systemSetupInfoQuery = new QueryHandler(
    useSystemSetupInfoLazyQuery({
      fetchPolicy: 'network-only',
    }),
  )

  const setSystemSetupInfo = async () => {
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

  const getImportPath = () => {
    const pathPrefix = '/guided-setup/import'
    let importBackend = application.config.import_backend

    if (application.config.import_mode) {
      return `${pathPrefix}/${importBackend}/status`
    }

    if (systemSetupInfo.value.importSource) {
      importBackend = systemSetupInfo.value.importSource
    }

    const importBackendRoute = importBackend ? `/${importBackend}` : ''

    return `${pathPrefix}${importBackendRoute}`
  }

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
        return '/guided-setup'
      }

      if (type === EnumSystemSetupInfoType.Import) {
        return getImportPath()
      }
    }

    return '/guided-setup'
  }

  const redirectPath = computed(() => {
    const { status, type, lockValue } = systemSetupInfo.value

    return getSystemSetupInfoRedirectPath(status, type || '', lockValue)
  })

  const redirectNeeded = (currentRoutePath: string) => {
    // Allow sub-paths for auto wizard execution + imports
    if (
      systemSetupInfo.value.status === EnumSystemSetupInfoStatus.Automated ||
      (systemSetupInfo.value.type === EnumSystemSetupInfoType.Import &&
        systemSetupInfo.value.importSource)
    ) {
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
