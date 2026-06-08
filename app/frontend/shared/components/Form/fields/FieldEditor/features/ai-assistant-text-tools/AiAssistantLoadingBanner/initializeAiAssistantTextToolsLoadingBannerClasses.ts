// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

let aiAssistantTextToolsLoadingBanner = {
  icon: '',
  label: '',
  button: '',
}

export const initializeAiAssistantTextToolsLoadingBannerClasses = (
  classes: typeof aiAssistantTextToolsLoadingBanner,
) => {
  aiAssistantTextToolsLoadingBanner = classes
}

export const getAiAssistantTextToolsLoadingBannerClasses = () => aiAssistantTextToolsLoadingBanner
