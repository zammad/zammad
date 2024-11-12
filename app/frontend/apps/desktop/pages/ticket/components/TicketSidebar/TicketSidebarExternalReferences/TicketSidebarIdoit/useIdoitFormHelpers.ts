// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'

import type { FormRef } from '#shared/components/Form/types.ts'
import type { IdoitObjectAttributesFragment } from '#shared/graphql/types.ts'

import type { ExternalReferencesFormValues } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/types.ts'

import type { Ref } from 'vue'

export const useIdoitFormHelpers = (form: Ref<FormRef | undefined>) => {
  const addObjectIdsToForm = (
    objects?: IdoitObjectAttributesFragment[] | null,
  ) => {
    if (!objects) return

    const objectIds = objects.map((object) => object.idoitObjectId)

    const externalReferences = form.value?.findNodeByName('externalReferences')

    if (!externalReferences) return

    let existingReferences = cloneDeep(
      externalReferences.value,
    ) as ExternalReferencesFormValues['externalReferences']

    existingReferences ||= {}
    existingReferences.idoit = [
      ...(existingReferences.idoit || []),
      ...objectIds,
    ]

    externalReferences?.input(existingReferences, false)
  }

  const removeObjectFromForm = async (id: number) => {
    const externalReferences = form.value?.findNodeByName('externalReferences')

    const { values } = form.value as { values: ExternalReferencesFormValues }

    if (!externalReferences?.value || !values.externalReferences?.idoit) return

    let existingReferences = cloneDeep(
      externalReferences.value,
    ) as ExternalReferencesFormValues['externalReferences']

    existingReferences ||= {}

    existingReferences.idoit = existingReferences.idoit!.filter(
      (objectId) => objectId !== id,
    )

    return externalReferences?.input(existingReferences, false)
  }

  return {
    addObjectIdsToForm,
    removeObjectFromForm,
  }
}
