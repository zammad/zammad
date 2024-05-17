// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { reactive } from 'vue'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'

import * as dates from './dates.ts'
import { Translator } from './translator.ts'

import type { TranslationMap } from './translator.ts'

const reactiveNow = useReactiveNow()

export class I18N {
  private translator = new Translator()

  t(
    source: string | undefined,
    ...args: Array<string | number | undefined | null | boolean>
  ): string {
    if (typeof source === 'undefined') return ''

    return this.translator.translate(source, ...args)
  }

  // eslint-disable-next-line class-methods-use-this
  locale() {
    return document.documentElement.getAttribute('lang') || 'en-US'
  }

  date(dateString: string): string {
    const template = dates.getDateFormat(this.translator)
    return dates.absoluteDateTime(dateString, template)
  }

  dateTime(dateTimeString: string): string {
    const template = dates.getDateTimeFormat(this.translator)
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

  getDateFormat(): string {
    return dates.getDateFormat(this.translator)
  }

  getDateTimeFormat(): string {
    return dates.getDateTimeFormat(this.translator)
  }

  getTimeFormatType() {
    const time24hour = !this.getDateTimeFormat().includes('P') // P means AM/PM
    return time24hour ? '24hour' : '12hour'
  }
}

export const i18n = reactive(new I18N()) as I18N

declare module '@vue/runtime-core' {
  export interface ComponentCustomProperties {
    i18n: I18N
    $t: I18N['t']
    __(source: string): string
  }
}
