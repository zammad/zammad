// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

let aiAssistantTextTools = {
  popover: {
    base: '',
    item: '',
    button: '',
  },
}

export const initializeAiAssistantTextToolsClasses = (classes: typeof aiAssistantTextTools) => {
  aiAssistantTextTools = classes
}

export const getAiAssistantTextToolsClasses = () => aiAssistantTextTools
