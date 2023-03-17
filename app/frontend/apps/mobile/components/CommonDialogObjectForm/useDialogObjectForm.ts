// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldValue } from '@shared/components/Form/types'
import { useDialog } from '@shared/composables/useDialog'
import type { EnumObjectManagerObjects } from '@shared/graphql/types'
import type { Props } from './CommonDialogObjectForm.vue'

interface ObjectDescription extends Omit<Props, 'name' | 'type'> {
  onSuccess?(data: unknown): void
  onError?(): void
  onChangedField?(
    fieldName: string,
    newValue: FormFieldValue,
    oldValue: FormFieldValue,
  ): void
}

export const useDialogObjectForm = (
  name: string,
  type: EnumObjectManagerObjects,
) => {
  const dialog = useDialog({
    name,
    component: () => import('./CommonDialogObjectForm.vue'),
  })

  const openDialog = async (props: ObjectDescription) => {
    dialog.open({
      name,
      type,
      ...props,
    })
  }

  return { openDialog }
}
