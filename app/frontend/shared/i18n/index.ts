// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { reactive, shallowRef } from 'vue'
import type { TranslationMap } from './translator'
import { Translator } from './translator'
import * as dates from './dates'

const reactiveNow = shallowRef(new Date())

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

  timeFormat() {
    const datetimeFormat =
      this.translator.lookup('FORMAT_DATETIME') || 'yyyy-mm-dd HH:MM'
    const time24hour = !datetimeFormat.includes('P') // P means AM/PM
    return time24hour ? '24hour' : '12hour'
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
    $t: I18N['t']
    __(source: string): string
  }
}
