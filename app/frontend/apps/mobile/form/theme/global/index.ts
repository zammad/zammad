// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormThemeClasses, FormThemeExtension } from '@common/types/form'

type Classes = Record<string, string>

const addFloatingLabel = (classes: Classes): Classes => {
  return {
    outer: `${classes.outer} floating-input`,
    wrapper: `${classes.wrapper} relative`,
    input: `${classes.input} w-full h-14 text-sm bg-gray-500 rounded-xl border-none focus:outline-none placeholder:text-transparent focus-within:pt-8 formkit-populated:pt-8`,
    label: `${classes.label} absolute top-0 left-0 py-5 px-3 h-full text-base transition-all duration-100 ease-in-out origin-left pointer-events-none formkit-populated:-translate-y3 formkit-populated:translate-x-1 formkit-populated:scale-75 formkit-populated:opacity-75`,
  }
}

const getCoreClasses: FormThemeExtension = (classes: FormThemeClasses) => {
  return {
    global: {},
    text: addFloatingLabel(classes.text),
    email: addFloatingLabel(classes.email),
    number: addFloatingLabel(classes.number),
    search: addFloatingLabel(classes.search),
    tel: addFloatingLabel(classes.tel),
    time: addFloatingLabel(classes.time),
    date: addFloatingLabel(classes.date),
    'datetime-local': addFloatingLabel(classes['datetime-local']),
    textarea: addFloatingLabel(classes.textarea),
    password: addFloatingLabel(classes.password),
  }
}

export default getCoreClasses
