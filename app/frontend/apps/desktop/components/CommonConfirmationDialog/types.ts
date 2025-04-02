// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { Props as ActionFooterProps } from '../CommonDialog/CommonDialogActionFooter.vue'

export interface ConfirmationVariantOptions {
  headerTitle: string
  headerIcon?: string
  content: string
  footerActionOptions: Pick<
    ActionFooterProps,
    'actionLabel' | 'actionButton' | 'cancelLabel' | 'hideCancelButton'
  >
}
