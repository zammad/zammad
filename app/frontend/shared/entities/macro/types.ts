// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormSubmitData } from '#shared/components/Form/types.ts'
import type { TicketFormData } from '#shared/entities/ticket/types.ts'
import type { Macro, TicketUpdateMetaInput } from '#shared/graphql/types.ts'

export type MacroById = Pick<Macro, 'id' | 'name' | 'uxFlowNextUp' | 'active'>

export type SubmitTicketForm = (
  formData: FormSubmitData<TicketFormData>,
  meta: TicketUpdateMetaInput,
) => Promise<boolean | undefined>
