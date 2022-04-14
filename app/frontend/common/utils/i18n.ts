// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import * as dates from '@common/utils/i18n/dates'
import { TranslationMap, Translator } from '@common/utils/i18n/translator'
import { reactive, ref } from 'vue'

const reactiveNow = ref(new Date())

window.setInterval(() => {
  reactiveNow.value = new Date()
}, 1000)

export class I18N {
  private translator = new Translator()

  t(source: string | undefined, ...args: Array<string | number>): string {
    if (typeof source === 'undefined') return ''

    return this.translator.translate(source, ...args)
  }

  date(dateString: string): string {
    const template = this.translator.lookup('FORMAT_DATE') || 'yyyy-mm-dd'
    return dates.absoluteDateTime(dateString, template)
  }

  dateTime(dateTimeString: string): string {
    const template =
      this.translator.lookup('FORMAT_DATETIME') || 'yyyy-mm-dd HH:MM'
    return dates.absoluteDateTime(dateTimeString, template)
  }

  relativeDateTime(dateTimeString: string, baseDate?: Date): string {
    return dates.relativeDateTime(
      dateTimeString,
      baseDate || reactiveNow.value,
      this.translator,
    )
  }

  setTranslationMap(map: TranslationMap): void {
    this.translator.setTranslationMap(map)
  }
}

export const i18n = reactive(new I18N())

declare module '@vue/runtime-core' {
  export interface ComponentCustomProperties {
    i18n: I18N
  }
}
