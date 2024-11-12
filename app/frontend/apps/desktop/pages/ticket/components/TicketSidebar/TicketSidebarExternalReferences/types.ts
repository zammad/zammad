// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { EnumTicketExternalReferencesIssueTrackerType } from '#shared/graphql/types.ts'

export type SubmitData = FormSubmitData<Record<'link', string>>

export interface ExternalReferencesFormValues {
  externalReferences?: {
    [EnumTicketExternalReferencesIssueTrackerType.Github]?: string[]
    [EnumTicketExternalReferencesIssueTrackerType.Gitlab]?: string[]
    idoit?: number[] // :TODO check for key type
  }
}
