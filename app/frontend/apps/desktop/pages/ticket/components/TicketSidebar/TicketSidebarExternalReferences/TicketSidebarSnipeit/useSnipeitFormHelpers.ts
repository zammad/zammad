// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'

import type { FormRef } from '#shared/components/Form/types.ts'
import type { SnipeitAssetAttributesFragment } from '#shared/graphql/types.ts'

import type { ExternalReferencesFormValues } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/types.ts'

import type { Ref } from 'vue'

export const useSnipeitFormHelpers = (form: Ref<FormRef | undefined>) => {
  const addAssetIdsToForm = (assets?: SnipeitAssetAttributesFragment[] | null) => {
    if (!assets) return

    const assetIds = assets.map((asset) => asset.snipeitAssetId)

    const externalReferences = form.value?.findNodeByName('externalReferences')

    if (!externalReferences) return

    let existingReferences = cloneDeep(
      externalReferences.value,
    ) as ExternalReferencesFormValues['externalReferences']

    existingReferences ||= {}
    existingReferences.snipeit = [...(existingReferences.snipeit || []), ...assetIds]

    externalReferences?.input(existingReferences, false)
  }

  const removeAssetFromForm = async (id: number) => {
    const externalReferences = form.value?.findNodeByName('externalReferences')

    const { values } = form.value as { values: ExternalReferencesFormValues }

    if (!externalReferences?.value || !values.externalReferences?.snipeit) return

    let existingReferences = cloneDeep(
      externalReferences.value,
    ) as ExternalReferencesFormValues['externalReferences']

    existingReferences ||= {}

    existingReferences.snipeit = existingReferences.snipeit!.filter((assetId) => assetId !== id)

    return externalReferences?.input(existingReferences, false)
  }

  return {
    addAssetIdsToForm,
    removeAssetFromForm,
  }
}
