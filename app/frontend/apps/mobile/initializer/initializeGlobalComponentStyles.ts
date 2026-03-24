// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { initializeAiAssistantTextToolsLoadingBannerClasses } from '#shared/components/Form/fields/FieldEditor/features/ai-assistant-text-tools/AiAssistantLoadingBanner/initializeAiAssistantTextToolsLoadingBannerClasses.ts'
import { initializeAiAssistantTextToolsClasses } from '#shared/components/Form/fields/FieldEditor/features/ai-assistant-text-tools/AiAssistantTextTools/initializeAiAssistantTextToolsClasses.ts'
import { initializeEditorColorMenuClasses } from '#shared/components/Form/fields/FieldEditor/features/color-picker/initializeEditorColorMenuClasses.ts'
import { initializeAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'
import { initializeAvatarClasses } from '#shared/initializer/initializeAvatarClasses.ts'
import { initializeFilePreviewClasses } from '#shared/initializer/initializeFilePreviewClasses.ts'
import { initializeLinkClasses } from '#shared/initializer/initializeLinkClasses.ts'
import { initializeNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'
import { initializeOrganizationAvatarClasses } from '#shared/initializer/initializeOrganizationAvatarClasses.ts'
import { initializePopoverClasses } from '#shared/initializer/initializePopover.ts'
import { initializeUserAvatarClasses } from '#shared/initializer/initializeUserAvatarClasses.ts'

export const initializeGlobalComponentStyles = () => {
  initializeLinkClasses({
    base: '',
    internal: '',
  })

  initializeAlertClasses({
    base: 'grid w-full content-start items-center justify-items-center text-center grid-flow-col grid-cols-[auto_minmax(auto,1fr)] justify-items-start text-start border w-auto text-sm',
    success: 'alert-success bg-green text-white',
    info: 'alert-info bg-white text-black',
    warning: 'alert-warning bg-yellow text-black',
    danger: 'alert-error bg-red/60 text-white',
    dismissButton: '',
  })

  initializeAvatarClasses({
    base: 'text-black',
    vipUser: 'text-yellow',
    vipOrganization: 'text-gray-100',
  })

  initializeUserAvatarClasses({
    backgroundColors: [
      'bg-gray',
      'bg-red-bright',
      'bg-yellow',
      'bg-blue',
      'bg-green',
      'bg-pink',
      'bg-orange',
    ],
  })

  initializeOrganizationAvatarClasses({
    base: 'bg-gray-200 text-black',
    inactive: 'opacity-30',
  })

  initializeNotificationClasses({
    base: 'rounded px-4 py-2',
    baseContainer: 'mx-auto max-w-full min-w-xs',
    error: 'bg-red/60 text-white',
    info: 'bg-white text-black',
    message: 'ltr:ml-2 rtl:mr-2',
    success: 'bg-green text-white',
    warn: 'bg-yellow text-black',
  })

  initializePopoverClasses({
    base: 'min-h-9 rounded-xl max-w-[calc(100vw-8px)] text-white top-0 border border-gray-500 bg-gray-400 antialiased',
    arrow: 'hidden',
  })

  initializeEditorColorMenuClasses({
    colorSchemeList: {
      base: 'gap-2',
      button: '',
      autoButton: 'bg-gray-500 text-white',
      autoButtonIcon: 'min-[200px]:scale-150 min-[300px]:scale-200 min-[400px]:scale-250',
    },
  })

  initializeFilePreviewClasses({
    base: 'leading-4',
    wrapper:
      'focus-within:bg-blue-highlight mb-2 gap-2 rounded-2xl border p-3 outline-hidden last:mb-0 border-gray-300',
    preview: '',
    link: '',
    size: 'text-white/80',
    icon: 'border-gray-300',
  })

  initializeAiAssistantTextToolsClasses({
    popover: {
      base: '',
      item: 'border-b border-gray-300 last:border-0',
      button: 'py-4 px-3 w-full',
    },
  })

  initializeAiAssistantTextToolsLoadingBannerClasses({
    icon: 'text-blue',
    label: 'text-white',
    button: 'text-blue',
  })
}
