// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export type TranslationMap = Map<string, string>

export class Translator {
  private translationMap: TranslationMap = new Map()

  setTranslationMap(translationMap: TranslationMap) {
    this.translationMap = translationMap
  }

  translate(source: string, ...args: Array<number | string>): string {
    let target = this.translationMap.get(source) || source

    args.forEach((arg) => {
      if (arg != null) target = target.replace('%s', arg.toString())
    })

    return target
  }

  lookup(source: string): string | undefined {
    return this.translationMap.get(source)
  }
}
