// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { TranslationMap, Translator } from '@common/utils/i18n/translator'

export class I18N {
  private translator = new Translator()

  t(source: string, ...args: Array<string | number>): string {
    return this.translator.translate(source, ...args)
  }

  setTranslationMap(map: TranslationMap): void {
    this.translator.setTranslationMap(map)
  }
}

export const i18n = new I18N()

declare module '@vue/runtime-core' {
  export interface ComponentCustomProperties {
    i18n: I18N
  }
}

// Add global __() method for marking translatable strings.

// eslint-disable-next-line no-underscore-dangle
window.__ = function __(source: string): string {
  return source
}
