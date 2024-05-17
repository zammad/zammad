// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useRouter } from 'vue-router'

import { EnumSystemImportSource } from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useSystemImportConfigurationMutation } from '../graphql/mutations/systemImportConfiguration.api.ts'

import { useImportSource } from './useImportSource.ts'

import type { ImportSourceConfigurationBase } from '../types/setup-import.ts'

export const useImportSourceConfiguration = <
  T extends ImportSourceConfigurationBase,
>(
  source: EnumSystemImportSource,
) => {
  const router = useRouter()
  const { loading } = useImportSource()

  const configureSystemImportSource = (data: T) => {
    loading.value = true

    const systemImportConfigurationMutation = new MutationHandler(
      useSystemImportConfigurationMutation(),
    )

    let tlsVerify = true
    if (data.sslVerify !== undefined) {
      tlsVerify = data.sslVerify
      delete data.sslVerify
    }

    return systemImportConfigurationMutation
      .send({
        configuration: {
          ...data,
          source,
          tlsVerify,
        },
      })
      .then((result) => {
        if (result?.systemImportConfiguration?.success) {
          // TODO: For OTRS we need to remember some stuff (maybe with importSource-Date or something in the route?)
          router.push(`/guided-setup/import/${source}/start`)
        }
      })
      .finally(() => {
        loading.value = false
      })
  }

  return {
    configureSystemImportSource,
  }
}
