// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const loadSvg = (symbols: [string, string][]) => {
  const { body } = document
  let svgDom = document.getElementById('__svg__icons__dom__') as unknown as
    | SVGSVGElement
    | undefined
  if (!svgDom) {
    svgDom = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
    svgDom.style.position = 'absolute'
    svgDom.style.width = '0'
    svgDom.style.height = '0'
    svgDom.id = '__svg__icons__dom__'
    svgDom.setAttribute('xmlns', 'http://www.w3.org/2000/svg')
    svgDom.setAttribute('xmlns:link', 'http://www.w3.org/1999/xlink')
  }
  const html = symbols.map((symb) => symb[1]).join('\n')
  svgDom.innerHTML = html
  body.insertBefore(svgDom, body.lastChild)
}

export const injectSvgIcons = (symbols: [string, string][]) => {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => loadSvg(symbols))
  } else {
    loadSvg(symbols)
  }
}
