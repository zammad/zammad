do($ = window.jQuery, window) ->

  scripts = document.getElementsByTagName('script')

  # search for script to get protocol and hostname for ws connection
  myScript = scripts[scripts.length - 1]
  scriptProtocol = window.location.protocol.replace(':', '') # set default protocol
  if myScript && myScript.src
    scriptHost = myScript.src.match('.*://([^:/]*).*')[1]
    scriptProtocol = myScript.src.match('(.*)://[^:/]*.*')[1]

  # Define the plugin class
  class Base
    defaults:
      debug: false

    constructor: (options) ->
      @options = $.extend {}, @defaults, options
      @log = new Log(debug: @options.debug, logPrefix: @options.logPrefix || @logPrefix)

  class Log
    defaults:
      debug: false

    constructor: (options) ->
      @options = $.extend {}, @defaults, options

    debug: (items...) =>
      return if !@options.debug
      @log('debug', items)

    notice: (items...) =>
      @log('notice', items)

    error: (items...) =>
      @log('error', items)

    log: (level, items) =>
      items.unshift('||')
      items.unshift(level)
      items.unshift(@options.logPrefix)
      console.log.apply console, items

      return if !@options.debug
      logString = ''
      for item in items
        logString += ' '
        if typeof item is 'object'
          logString += JSON.stringify(item)
        else if item && item.toString
          logString += item.toString()
        else
          logString += item
      $('.js-chatLogDisplay').prepend('<div>' + logString + '</div>')

  class Timeout extends Base
    timeoutStartedAt: null
    logPrefix: 'timeout'
    defaults:
      debug: false
      timeout: 4
      timeoutIntervallCheck: 0.5

    constructor: (options) ->
      super(options)

    start: =>
      @stop()
      timeoutStartedAt = new Date
      check = =>
        timeLeft = new Date - new Date(timeoutStartedAt.getTime() + @options.timeout * 1000 * 60)
        @log.debug "Timeout check for #{@options.timeout} minutes (left #{timeLeft/1000} sec.)"#, new Date
        return if timeLeft < 0
        @stop()
        @options.callback()
      @log.debug "Start timeout in #{@options.timeout} minutes"#, new Date
      @intervallId = setInterval(check, @options.timeoutIntervallCheck * 1000 * 60)

    stop: =>
      return if !@intervallId
      @log.debug "Stop timeout of #{@options.timeout} minutes"#, new Date
      clearInterval(@intervallId)

  class Io extends Base
    logPrefix: 'io'
    constructor: (options) ->
      super(options)

    set: (params) =>
      for key, value of params
        @options[key] = value

    connect: =>
      @log.debug "Connecting to #{@options.host}"
      @ws = new window.WebSocket("#{@options.host}")
      @ws.onopen = (e) =>
        @log.debug 'onOpen', e
        @options.onOpen(e)
        @ping()

      @ws.onmessage = (e) =>
        pipes = JSON.parse(e.data)
        @log.debug 'onMessage', e.data
        for pipe in pipes
          if pipe.event is 'pong'
            @ping()
        if @options.onMessage
          @options.onMessage(pipes)

      @ws.onclose = (e) =>
        @log.debug 'close websocket connection', e
        if @pingDelayId
          clearTimeout(@pingDelayId)
        if @manualClose
          @log.debug 'manual close, onClose callback'
          @manualClose = false
          if @options.onClose
            @options.onClose(e)
        else
          @log.debug 'error close, onError callback'
          if @options.onError
            @options.onError('Connection lost...')

      @ws.onerror = (e) =>
        @log.debug 'onError', e
        if @options.onError
          @options.onError(e)

    close: =>
      @log.debug 'close websocket manually'
      @manualClose = true
      @ws.close()

    reconnect: =>
      @log.debug 'reconnect'
      @close()
      @connect()

    send: (event, data = {}) =>
      @log.debug 'send', event, data
      msg = JSON.stringify
        event: event
        data: data
      @ws.send msg

    ping: =>
      localPing = =>
        @send('ping')
      @pingDelayId = setTimeout(localPing, 29000)

  class ZammadChat extends Base
    defaults:
      chatId: undefined
      show: true
      target: $('body')
      host: ''
      debug: false
      flat: false
      lang: undefined
      cssAutoload: true
      cssUrl: undefined
      fontSize: undefined
      buttonClass: 'open-zammad-chat'
      inactiveClass: 'is-inactive'
      title: '<strong>Chat</strong> with us!'
      scrollHint: 'Scroll down to see new messages'
      idleTimeout: 6
      idleTimeoutIntervallCheck: 0.5
      inactiveTimeout: 8
      inactiveTimeoutIntervallCheck: 0.5
      waitingListTimeout: 4
      waitingListTimeoutIntervallCheck: 0.5
      # Callbacks
      onReady: undefined
      onCloseAnimationEnd: undefined
      onError: undefined
      onOpenAnimationEnd: undefined
      onConnectionReestablished: undefined
      onSessionClosed: undefined
      onConnectionEstablished: undefined
      onCssLoaded: undefined

    logPrefix: 'chat'
    _messageCount: 0
    isOpen: false
    blinkOnlineInterval: null
    stopBlinOnlineStateTimeout: null
    showTimeEveryXMinutes: 2
    lastTimestamp: null
    lastAddedType: null
    inputDisabled: false
    inputTimeout: null
    isTyping: false
    state: 'offline'
    initialQueueDelay: 10000
    translations:
    # ZAMMAD_TRANSLATIONS_START
      'cs':
        '<strong>Chat</strong> with us!': '<strong>Chatujte</strong> s námi!'
        'All colleagues are busy.': 'Všichni kolegové jsou vytíženi.'
        'Chat closed by %s': '%s ukončil konverzaci'
        'Compose your message…': 'Napište svou zprávu…'
        'Connecting': 'Připojování'
        'Connection lost': 'Připojení ztraceno'
        'Connection re-established': 'Připojení obnoveno'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Srolujte dolů pro zobrazení nových zpráv'
        'Send': 'Odeslat'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': ''
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': ''
        'Start new conversation': 'Zahájit novou konverzaci'
        'Today': 'Dnes'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': ''
        'You are on waiting list position <strong>%s</strong>.': 'Jste <strong>%s</strong>. v pořadí na čekací listině.'
      'de':
        '<strong>Chat</strong> with us!': '<strong>Chatte</strong> mit uns!'
        'All colleagues are busy.': 'Alle Kollegen sind beschäftigt.'
        'Chat closed by %s': 'Chat von %s geschlossen'
        'Compose your message…': 'Verfassen Sie Ihre Nachricht…'
        'Connecting': 'Verbinde'
        'Connection lost': 'Verbindung verloren'
        'Connection re-established': 'Verbindung wieder aufgebaut'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Nach unten scrollen um neue Nachrichten zu sehen'
        'Send': 'Senden'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Da Sie innerhalb der letzten %s Minuten nicht reagiert haben, wurde Ihre Unterhaltung geschlossen.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Da Sie innerhalb der letzten %s Minuten nicht reagiert haben, wurde Ihre Unterhaltung mit <strong>%s</strong> geschlossen.'
        'Start new conversation': 'Neue Unterhaltung starten'
        'Today': 'Heute'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Entschuldigung, es dauert länger als erwartet einen freien Platz zu bekommen. Versuchen Sie es später erneut oder senden Sie uns eine E-Mail. Vielen Dank!'
        'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste auf Position <strong>%s</strong>.'
      'es':
        '<strong>Chat</strong> with us!': '<strong>Chatee</strong> con nosotros!'
        'All colleagues are busy.': 'Todos los colegas están ocupados.'
        'Chat closed by %s': 'Chat cerrado por %s'
        'Compose your message…': 'Escribe tu mensaje…'
        'Connecting': 'Conectando'
        'Connection lost': 'Conexión perdida'
        'Connection re-established': 'Conexión reestablecida'
        'Offline': 'Desconectado'
        'Online': 'En línea'
        'Scroll down to see new messages': 'Desplace hacia abajo para ver nuevos mensajes'
        'Send': 'Enviar'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Debido a que usted no ha respondido en los últimos %s minutos, su conversación se ha cerrado.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Debido a que usted no ha respondido en los últimos %s minutos, su conversación con <strong>%s</strong> se ha cerrado.'
        'Start new conversation': 'Iniciar nueva conversación'
        'Today': 'Hoy'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Lo sentimos, estamos tardando más de lo esperado para asignar un agente. Inténtelo de nuevo más tarde o envíenos un correo electrónico. ¡Gracias!'
        'You are on waiting list position <strong>%s</strong>.': 'Usted está en la posición <strong>%s</strong> de la lista de espera.'
      'fr':
        '<strong>Chat</strong> with us!': '<strong>Chattez</strong> avec nous !'
        'All colleagues are busy.': 'Tout les agents sont occupés.'
        'Chat closed by %s': 'Chat fermé par %s'
        'Compose your message…': 'Ecrivez votre message…'
        'Connecting': 'Connexion'
        'Connection lost': 'Connexion perdue'
        'Connection re-established': 'Connexion ré-établie'
        'Offline': 'Hors-ligne'
        'Online': 'En ligne'
        'Scroll down to see new messages': 'Défiler vers le bas pour voir les nouveaux messages'
        'Send': 'Envoyer'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': ''
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': ''
        'Start new conversation': 'Démarrer une nouvelle conversation'
        'Today': 'Aujourd\'hui'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': ''
        'You are on waiting list position <strong>%s</strong>.': 'Vous êtes actuellement en position <strong>%s</strong> dans la file d\'attente.'
      'hr':
        '<strong>Chat</strong> with us!': '<strong>Čavrljajte</strong> sa nama!'
        'All colleagues are busy.': 'Svi kolege su zauzeti.'
        'Chat closed by %s': '%s zatvara chat'
        'Compose your message…': 'Sastavite poruku…'
        'Connecting': 'Povezivanje'
        'Connection lost': 'Veza prekinuta'
        'Connection re-established': 'Veza je ponovno uspostavljena'
        'Offline': 'Odsutan'
        'Online': 'Dostupan(a)'
        'Scroll down to see new messages': 'Pomaknite se prema dolje da biste vidjeli nove poruke'
        'Send': 'Šalji'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Budući da niste odgovorili u posljednjih %s minuta, Vaš je razgovor zatvoren.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Budući da niste odgovorili u posljednjih %s minuta, Vaš je razgovor s <strong>%</strong>s zatvoren.'
        'Start new conversation': 'Započni novi razgovor'
        'Today': 'Danas'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Oprostite, proces traje duže nego što se očekivalo da biste dobili slobodan termin. Molimo, pokušajte ponovno kasnije ili nam pošaljite e-mail. Hvala!'
        'You are on waiting list position <strong>%s</strong>.': 'Nalazite se u redu čekanja na poziciji <strong>%s</strong>.'
      'hu':
        '<strong>Chat</strong> with us!': '<strong>Csevegjen</strong> velünk!'
        'All colleagues are busy.': 'Minden munkatársunk foglalt.'
        'Chat closed by %s': 'A csevegés %s által lezárva'
        'Compose your message…': 'Fogalmazza meg üzenetét…'
        'Connecting': 'Csatlakozás'
        'Connection lost': 'A kapcsolat megszakadt'
        'Connection re-established': 'A kapcsolat helyreállt'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Görgessen lefelé az új üzenetek megtekintéséhez'
        'Send': 'Küldés'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Mivel az elmúlt %s percben nem válaszolt, a beszélgetése lezárásra került.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Mivel az elmúlt %s percben nem válaszolt, <strong>%s</strong> munkatársunkkal folytatott beszélgetését lezártuk.'
        'Start new conversation': 'Új beszélgetés indítása'
        'Today': 'Ma'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Sajnáljuk, hogy a vártnál hosszabb ideig tart a helyfoglalás. Kérjük, próbálja meg később újra, vagy küldjön nekünk egy e-mailt. Köszönjük!'
        'You are on waiting list position <strong>%s</strong>.': 'Ön a várólistán a <strong>%s</strong> helyen szerepel.'
      'it':
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> con noi!'
        'All colleagues are busy.': 'Tutti i colleghi sono occupati.'
        'Chat closed by %s': 'Chat chiusa da %s'
        'Compose your message…': 'Scrivi il tuo messaggio…'
        'Connecting': 'Connessione in corso'
        'Connection lost': 'Connessione persa'
        'Connection re-established': 'Connessione ristabilita'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Scorri verso il basso per vedere i nuovi messaggi'
        'Send': 'Invia'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': ''
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': ''
        'Start new conversation': 'Avvia una nuova chat'
        'Today': 'Oggi'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': ''
        'You are on waiting list position <strong>%s</strong>.': 'Sei alla posizione <strong>%s</strong> della lista di attesa.'
      'nl':
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> met ons!'
        'All colleagues are busy.': 'Alle collega\'s zijn bezet.'
        'Chat closed by %s': 'Chat gesloten door %s'
        'Compose your message…': 'Stel je bericht op…'
        'Connecting': 'Verbinden'
        'Connection lost': 'Verbinding verbroken'
        'Connection re-established': 'Verbinding hersteld'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Scroll naar beneden om nieuwe tickets te bekijken'
        'Send': 'Verstuur'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'De chat is afgesloten omdat je de laatste %s minuten niet hebt gereageerd.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Je chat met <strong>%s</strong> is afgesloten omdat je niet hebt gereageerd in de laatste %s minuten.'
        'Start new conversation': 'Nieuw gesprek starten'
        'Today': 'Vandaag'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Het spijt ons, het duurt langer dan verwacht om een chat te starten. Probeer het later nog eens of stuur ons een e-mail. Bedankt!'
        'You are on waiting list position <strong>%s</strong>.': 'U bevindt zich op wachtlijstpositie <strong>%s</strong>.'
      'pl':
        '<strong>Chat</strong> with us!': '<strong>Czatuj</strong> z nami!'
        'All colleagues are busy.': 'Wszyscy agenci są zajęci.'
        'Chat closed by %s': 'Chat zamknięty przez %s'
        'Compose your message…': 'Skomponuj swoją wiadomość…'
        'Connecting': 'Łączenie'
        'Connection lost': 'Utracono połączenie'
        'Connection re-established': 'Ponowne nawiązanie połączenia'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Skroluj w dół, aby zobaczyć wiadomości'
        'Send': 'Wyślij'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa została zamknięta.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa z <strong>%s</strong> została zamknięta.'
        'Start new conversation': 'Rozpocznij nową rozmowę'
        'Today': 'Dzisiaj'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Przepraszamy, znalezienie wolnego konsultanta zajmuje więcej czasu niż oczekiwano. Spróbuj ponownie później lub wyślij nam e-mail. Dziękujemy!'
        'You are on waiting list position <strong>%s</strong>.': 'Jesteś na pozycji listy oczekujących <strong>%s</strong>.'
      'pt-br':
        '<strong>Chat</strong> with us!': '<strong>Converse</strong> conosco!'
        'All colleagues are busy.': 'Nossos atendentes estão ocupados.'
        'Chat closed by %s': 'Chat encerrado por %s'
        'Compose your message…': 'Escreva sua mensagem…'
        'Connecting': 'Conectando'
        'Connection lost': 'Conexão perdida'
        'Connection re-established': 'Conexão restabelecida'
        'Offline': 'Desconectado'
        'Online': 'Online'
        'Scroll down to see new messages': 'Rolar para baixo para ver novas mensagems'
        'Send': 'Enviar'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': ''
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': ''
        'Start new conversation': 'Iniciar uma nova conversa'
        'Today': 'Hoje'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': ''
        'You are on waiting list position <strong>%s</strong>.': 'Você está na posição <strong>%s</strong> da lista de espera.'
      'ru':
        '<strong>Chat</strong> with us!': '<strong>Напишите</strong> нам!'
        'All colleagues are busy.': 'Все коллеги заняты.'
        'Chat closed by %s': 'Чат закрыт %s'
        'Compose your message…': 'Составьте сообщение…'
        'Connecting': 'Подключение'
        'Connection lost': 'Подключение потеряно'
        'Connection re-established': 'Подключение восстановлено'
        'Offline': 'Оффлайн'
        'Online': 'В сети'
        'Scroll down to see new messages': 'Прокрутите вниз, чтобы увидеть новые сообщения'
        'Send': 'Отправить'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': ''
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': ''
        'Start new conversation': 'Начать новую беседу'
        'Today': 'Сегодня'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': ''
        'You are on waiting list position <strong>%s</strong>.': 'Вы находитесь в списке ожидания <strong>%s</strong>.'
      'sr':
        '<strong>Chat</strong> with us!': '<strong>Ћаскајте</strong> са нама!'
        'All colleagues are busy.': 'Све колеге су заузете.'
        'Chat closed by %s': 'Ћаскање затворено од стране %s'
        'Compose your message…': 'Напишите поруку…'
        'Connecting': 'Повезивање'
        'Connection lost': 'Веза је изгубљена'
        'Connection re-established': 'Веза је поново успостављена'
        'Offline': 'Одсутан(а)'
        'Online': 'Доступан(а)'
        'Scroll down to see new messages': 'Скролујте на доле за нове поруке'
        'Send': 'Пошаљи'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Пошто нисте одговорили у последњих %s минут(a), ваш разговор је завршен.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Пошто нисте одговорили у последњих %s минут(a), ваш разговор са <strong>%s</strong> је завршен.'
        'Start new conversation': 'Започни нови разговор'
        'Today': 'Данас'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Жао нам је, добијање празног термина траје дуже од очекиваног. Молимо покушајте поново касније или нам пошаљите имејл поруку. Хвала вам!'
        'You are on waiting list position <strong>%s</strong>.': 'Ви сте тренутно <strong>%s.</strong> у реду за чекање.'
      'sr-latn-rs':
        '<strong>Chat</strong> with us!': '<strong>Ćaskajte</strong> sa nama!'
        'All colleagues are busy.': 'Sve kolege su zauzete.'
        'Chat closed by %s': 'Ćaskanje zatvoreno od strane %s'
        'Compose your message…': 'Napišite poruku…'
        'Connecting': 'Povezivanje'
        'Connection lost': 'Veza je izgubljena'
        'Connection re-established': 'Veza je ponovo uspostavljena'
        'Offline': 'Odsutan(a)'
        'Online': 'Dostupan(a)'
        'Scroll down to see new messages': 'Skrolujte na dole za nove poruke'
        'Send': 'Pošalji'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Pošto niste odgovorili u poslednjih %s minut(a), vaš razgovor je završen.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Pošto niste odgovorili u poslednjih %s minut(a), vaš razgovor sa <strong>%s</strong> je završen.'
        'Start new conversation': 'Započni novi razgovor'
        'Today': 'Danas'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Žao nam je, dobijanje praznog termina traje duže od očekivanog. Molimo pokušajte ponovo kasnije ili nam pošaljite imejl poruku. Hvala vam!'
        'You are on waiting list position <strong>%s</strong>.': 'Vi ste trenutno <strong>%s.</strong> u redu za čekanje.'
      'sv':
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> med oss!'
        'All colleagues are busy.': 'Alla kollegor är upptagna.'
        'Chat closed by %s': 'Chatt stängd av %s'
        'Compose your message…': 'Skriv ditt meddelande …'
        'Connecting': 'Ansluter'
        'Connection lost': 'Anslutningen försvann'
        'Connection re-established': 'Anslutningen återupprättas'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Bläddra ner för att se nya meddelanden'
        'Send': 'Skicka'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': ''
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': ''
        'Start new conversation': 'Starta ny konversation'
        'Today': 'Idag'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Det tar tyvärr längre tid än förväntat att få en ledig plats. Försök igen senare eller skicka ett mejl till oss. Tack!'
        'You are on waiting list position <strong>%s</strong>.': 'Du är på väntelistan som position <strong>%s</strong>.'
    # ZAMMAD_TRANSLATIONS_END
    sessionId: undefined
    scrolledToBottom: true
    scrollSnapTolerance: 10
    richTextFormatKey:
      66: true # b
      73: true # i
      85: true # u
      83: true # s

    T: (string, items...) =>
      if @options.lang && @options.lang isnt 'en'
        if !@translations[@options.lang]
          @log.notice "Translation '#{@options.lang}' needed!"
        else
          translations = @translations[@options.lang]
          if !translations[string]
            @log.notice "Translation needed for '#{string}'"
          string = translations[string] || string
      if items
        for item in items
          string = string.replace(/%s/, item)
      string

    view: (name) =>
      return (options) =>
        if !options
          options = {}

        options.T = @T
        options.background = @options.background
        options.flat = @options.flat
        options.fontSize = @options.fontSize
        return window.zammadChatTemplates[name](options)

    constructor: (options) ->
      @options = $.extend {}, @defaults, options
      super(@options)

      # fullscreen
      @isFullscreen = (window.matchMedia and window.matchMedia('(max-width: 768px)').matches)
      @scrollRoot = $(@getScrollRoot())

      # check prerequisites
      if !$
        @state = 'unsupported'
        @log.notice 'Chat: no jquery found!'
        return
      if !window.WebSocket or !sessionStorage
        @state = 'unsupported'
        @log.notice 'Chat: Browser not supported!'
        return
      if !@options.chatId
        @state = 'unsupported'
        @log.error 'Chat: need chatId as option!'
        return

      # detect language
      if !@options.lang
        @options.lang = $('html').attr('lang')
      if @options.lang
        if !@translations[@options.lang]
          @log.debug "lang: No #{@options.lang} found, try first two letters"
          @options.lang = @options.lang.replace(/-.+?$/, '') # replace "-xx" of xx-xx
        @log.debug "lang: #{@options.lang}"

      # detect host
      @detectHost() if !@options.host

      @loadCss()

      @io = new Io(@options)
      @io.set(
        onOpen: @render
        onClose: @onWebSocketClose
        onMessage: @onWebSocketMessage
        onError: @onError
      )

      @io.connect()

    getScrollRoot: ->
      return document.scrollingElement if 'scrollingElement' of document
      html = document.documentElement
      start = html.scrollTop
      html.scrollTop = start + 1
      end = html.scrollTop
      html.scrollTop = start
      return if end > start then html else document.body

    render: =>
      if !@el || !$('.zammad-chat').get(0)
        @renderBase()

      # disable open button
      $(".#{ @options.buttonClass }").addClass @options.inactiveClass

      @setAgentOnlineState 'online'

      @log.debug 'widget rendered'

      @startTimeoutObservers()
      @idleTimeout.start()

      # get current chat status
      @sessionId = sessionStorage.getItem('sessionId')
      @send 'chat_status_customer',
        session_id: @sessionId
        url: window.location.href

    renderBase: ->
      @el = $(@view('chat')(
        title: @options.title,
        scrollHint: @options.scrollHint
      ))
      @options.target.append @el

      @input = @el.find('.zammad-chat-input')

      # start bindings
      @el.find('.js-chat-open').on 'click', @open
      @el.find('.js-chat-toggle').on 'click', @toggle
      @el.find('.js-chat-status').on 'click', @stopPropagation
      @el.find('.zammad-chat-controls').on 'submit', @onSubmit
      @el.find('.zammad-chat-body').on 'scroll', @detectScrolledtoBottom
      @el.find('.zammad-scroll-hint').on 'click', @onScrollHintClick
      @input.on(
        keydown: @checkForEnter
        input: @onInput
      )
      @input.on('keydown', (e) =>
        richtTextControl = false
        if !e.altKey && !e.ctrlKey && e.metaKey
          richtTextControl = true
        else if !e.altKey && e.ctrlKey && !e.metaKey
          richtTextControl = true

        if richtTextControl && @richTextFormatKey[ e.keyCode ]
          e.preventDefault()
          if e.keyCode is 66
            document.execCommand('bold')
            return true
          if e.keyCode is 73
            document.execCommand('italic')
            return true
          if e.keyCode is 85
            document.execCommand('underline')
            return true
          if e.keyCode is 83
            document.execCommand('strikeThrough')
            return true
      )
      @input.on('paste', (e) =>
        e.stopPropagation()
        e.preventDefault()

        clipboardData
        if e.clipboardData
          clipboardData = e.clipboardData
        else if window.clipboardData
          clipboardData = window.clipboardData
        else if e.originalEvent.clipboardData
          clipboardData = e.originalEvent.clipboardData
        else
          throw 'No clipboardData support'

        imageInserted = false
        if clipboardData && clipboardData.items && clipboardData.items[0]
          item = clipboardData.items[0]
          if item.kind == 'file' && (item.type == 'image/png' || item.type == 'image/jpeg')
            imageFile = item.getAsFile()
            reader = new FileReader()

            reader.onload = (e) =>
              result = e.target.result
              img = document.createElement('img')
              img.src = result

              insert = (dataUrl, width, height, isRetina) =>

                # adapt image if we are on retina devices
                if @isRetina()
                  width = width / 2
                  height = height / 2
                result = dataUrl
                img = "<img style=\"width: 100%; max-width: #{width}px;\" src=\"#{result}\">"
                document.execCommand('insertHTML', false, img)

              # resize if to big
              @resizeImage(img.src, 460, 'auto', 2, 'image/jpeg', 'auto', insert)

            reader.readAsDataURL(imageFile)
            imageInserted = true

        return if imageInserted

        # check existing + paste text for limit
        text = undefined
        docType = undefined
        try
          text = clipboardData.getData('text/html')
          docType = 'html'
          if !text || text.length is 0
            docType = 'text'
            text = clipboardData.getData('text/plain')
          if !text || text.length is 0
            docType = 'text2'
            text = clipboardData.getData('text')
        catch e
          console.log('Sorry, can\'t insert markup because browser is not supporting it.')
          docType = 'text3'
          text = clipboardData.getData('text')

        if docType is 'text' || docType is 'text2' || docType is 'text3'
          text = '<div>' + text.replace(/\n/g, '</div><div>') + '</div>'
          text = text.replace(/<div><\/div>/g, '<div><br></div>')
        console.log('p', docType, text)
        if docType is 'html'
          sanitized = DOMPurify.sanitize(text)
          @log.debug 'sanitized HTML clipboard', sanitized
          html = $("<div>#{sanitized}</div>")
          match = false
          htmlTmp = text
          regex = new RegExp('<(/w|w)\:[A-Za-z]')
          if htmlTmp.match(regex)
            match = true
            htmlTmp = htmlTmp.replace(regex, '')
          regex = new RegExp('<(/o|o)\:[A-Za-z]')
          if htmlTmp.match(regex)
            match = true
            htmlTmp = htmlTmp.replace(regex, '')
          if match
            html = @wordFilter(html)
          #html

          html = $(html)

          html.contents().each( ->
            if @nodeType == 8
              $(@).remove()
          )

          # remove tags, keep content
          html.find('a, font, small, time, form, label').replaceWith( ->
            $(@).contents()
          )

          # replace tags with generic div
          # New type of the tag
          replacementTag = 'div';

          # Replace all x tags with the type of replacementTag
          html.find('textarea').each( ->
            outer = @outerHTML

            # Replace opening tag
            regex = new RegExp('<' + @tagName, 'i')
            newTag = outer.replace(regex, '<' + replacementTag)

            # Replace closing tag
            regex = new RegExp('</' + @tagName, 'i')
            newTag = newTag.replace(regex, '</' + replacementTag)

            $(@).replaceWith(newTag)
          )

          # remove tags & content
          html.find('font, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset').remove()

          @removeAttributes(html)

          text = html.html()

        # as fallback, insert html via pasteHtmlAtCaret (for IE 11 and lower)
        if docType is 'text3'
          @pasteHtmlAtCaret(text)
        else
          document.execCommand('insertHTML', false, text)
        true
      )
      @input.on('drop', (e) =>
        e.stopPropagation()
        e.preventDefault()

        dataTransfer
        if window.dataTransfer # ie
          dataTransfer = window.dataTransfer
        else if e.originalEvent.dataTransfer # other browsers
          dataTransfer = e.originalEvent.dataTransfer
        else
          throw 'No clipboardData support'

        x = e.clientX
        y = e.clientY
        file = dataTransfer.files[0]

        # look for images
        if file.type.match('image.*')
          reader = new FileReader()
          reader.onload = (e) =>
            result = e.target.result
            img = document.createElement('img')
            img.src = result

            # Insert the image at the carat
            insert = (dataUrl, width, height, isRetina) =>

              # adapt image if we are on retina devices
              if @isRetina()
                width = width / 2
                height = height / 2

              result = dataUrl
              img = $("<img style=\"width: 100%; max-width: #{width}px;\" src=\"#{result}\">")
              img = img.get(0)

              if document.caretPositionFromPoint
                pos = document.caretPositionFromPoint(x, y)
                range = document.createRange()
                range.setStart(pos.offsetNode, pos.offset)
                range.collapse()
                range.insertNode(img)
              else if document.caretRangeFromPoint
                range = document.caretRangeFromPoint(x, y)
                range.insertNode(img)
              else
                console.log('could not find carat')

            # resize if to big
            @resizeImage(img.src, 460, 'auto', 2, 'image/jpeg', 'auto', insert)
          reader.readAsDataURL(file)
      )

      $(window).on('beforeunload', =>
        @onLeaveTemporary()
      )
      $(window).on('hashchange', =>
        if @isOpen
          if @sessionId
            @send 'chat_session_notice',
              session_id: @sessionId
              message: window.location.href
          return
        @idleTimeout.start()
      )

      if @isFullscreen
        @input.on
          focus: @onFocus
          focusout: @onFocusOut

    stopPropagation: (event) ->
      event.stopPropagation()

    checkForEnter: (event) =>
      if not @inputDisabled and not event.shiftKey and event.keyCode is 13
        event.preventDefault()
        @sendMessage()

    send: (event, data = {}) =>
      data.chat_id = @options.chatId
      @io.send(event, data)

    onWebSocketMessage: (pipes) =>
      for pipe in pipes
        @log.debug 'ws:onmessage', pipe
        switch pipe.event
          when 'chat_error'
            @log.notice pipe.data
            if pipe.data && pipe.data.state is 'chat_disabled'
              @destroy(remove: true)
          when 'chat_session_message'
            return if pipe.data.self_written
            @receiveMessage pipe.data
          when 'chat_session_typing'
            return if pipe.data.self_written
            @onAgentTypingStart()
          when 'chat_session_start'
            @onConnectionEstablished pipe.data
          when 'chat_session_queue'
            @onQueueScreen pipe.data
          when 'chat_session_closed'
            @onSessionClosed pipe.data
          when 'chat_session_left'
            @onSessionClosed pipe.data
          when 'chat_session_notice'
            @addStatus @T(pipe.data.message)
          when 'chat_status_customer'
            switch pipe.data.state
              when 'online'
                @sessionId = undefined

                if !@options.cssAutoload || @cssLoaded
                  @onReady()
                else
                  @socketReady = true
              when 'offline'
                @onError 'Zammad Chat: No agent online'
              when 'chat_disabled'
                @onError 'Zammad Chat: Chat is disabled'
              when 'no_seats_available'
                @onError "Zammad Chat: Too many clients in queue. Clients in queue: #{pipe.data.queue}"
              when 'reconnect'
                @onReopenSession pipe.data

    onReady: ->
      @log.debug 'widget ready for use'
      $(".#{ @options.buttonClass }").on('click', @open).removeClass(@options.inactiveClass)

      @options.onReady?()

      if @options.show
        @show()

    onError: (message) =>
      @log.debug message
      @addStatus(message)
      $(".#{ @options.buttonClass }").hide()
      if @isOpen
        @disableInput()
        @destroy(remove: false)
      else
        @destroy(remove: true)

      @options.onError?(message)

    onReopenSession: (data) =>
      @log.debug 'old messages', data.session
      @inactiveTimeout.start()

      unfinishedMessage = sessionStorage.getItem 'unfinished_message'

      # rerender chat history
      if data.agent
        @onConnectionEstablished(data)

        for message in data.session
          @renderMessage
            message: message.content
            id: message.id
            from: if message.created_by_id then 'agent' else 'customer'

        if unfinishedMessage
          @input.html(unfinishedMessage)

      # show wait list
      if data.position
        @onQueue data

      @show()
      @open()
      @scrollToBottom()

      if unfinishedMessage
        @input.trigger('focus')

    onInput: =>
      # remove unread-state from messages
      @el.find('.zammad-chat-message--unread')
        .removeClass 'zammad-chat-message--unread'

      sessionStorage.setItem 'unfinished_message', @input.html()

      @onTyping()

    onFocus: =>
      $(window).scrollTop(10)
      keyboardShown = $(window).scrollTop() > 0
      $(window).scrollTop(0)

      if keyboardShown
        @log.notice 'virtual keyboard shown'
        # on keyboard shown
        # can't measure visible area height :(

    onFocusOut: ->
      # on keyboard hidden

    onTyping: ->

      # send typing start event only every 1.5 seconds
      return if @isTyping && @isTyping > new Date(new Date().getTime() - 1500)
      @isTyping = new Date()
      @send 'chat_session_typing',
        session_id: @sessionId
      @inactiveTimeout.start()

    onSubmit: (event) =>
      event.preventDefault()
      @sendMessage()

    sendMessage: ->
      message = @input.html()
      return if !message

      @inactiveTimeout.start()

      sessionStorage.removeItem 'unfinished_message'

      messageElement = @view('message')
        message: message
        from: 'customer'
        id: @_messageCount++
        unreadClass: ''

      @maybeAddTimestamp()

      # add message before message typing loader
      if @el.find('.zammad-chat-message--typing').get(0)
        @lastAddedType = 'typing-placeholder'
        @el.find('.zammad-chat-message--typing').before messageElement
      else
        @lastAddedType = 'message--customer'
        @el.find('.zammad-chat-body').append messageElement

      @input.html('')
      @scrollToBottom()

      # send message event
      @send 'chat_session_message',
        content: message
        id: @_messageCount
        session_id: @sessionId

    receiveMessage: (data) =>
      @inactiveTimeout.start()

      # hide writing indicator
      @onAgentTypingEnd()

      @maybeAddTimestamp()

      @renderMessage
        message: data.message.content
        id: data.id
        from: 'agent'

      @scrollToBottom showHint: true

    renderMessage: (data) =>
      @lastAddedType = "message--#{ data.from }"
      data.unreadClass = if document.hidden then ' zammad-chat-message--unread' else ''
      @el.find('.zammad-chat-body').append @view('message')(data)

    open: =>
      if @isOpen
        @log.debug 'widget already open, block'
        return

      @isOpen = true
      @log.debug 'open widget'
      @show()

      if !@sessionId
        @showLoader()

      @el.addClass('zammad-chat-is-open')

      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()

      @el.css 'bottom', -remainerHeight

      if !@sessionId
        @el.animate { bottom: 0 }, 500, @onOpenAnimationEnd
        @send('chat_session_init'
          url: window.location.href
        )
      else
        @el.css 'bottom', 0
        @onOpenAnimationEnd()

    onOpenAnimationEnd: =>
      @idleTimeout.stop()

      if @isFullscreen
        @disableScrollOnRoot()
      @options.onOpenAnimationEnd?()

    sessionClose: =>
      # send close
      @send 'chat_session_close',
        session_id: @sessionId

      # stop timer
      @inactiveTimeout.stop()
      @waitingListTimeout.stop()

      # delete input store
      sessionStorage.removeItem 'unfinished_message'

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      @setSessionId undefined

    toggle: (event) =>
      if @isOpen
        @close(event)
      else
        @open(event)

    close: (event) =>
      if !@isOpen
        @log.debug 'can\'t close widget, it\'s not open'
        return
      if @initDelayId
        clearTimeout(@initDelayId)
      if @sessionId
        @log.debug 'session close before widget close'
        @sessionClose()

      @log.debug 'close widget'

      event.stopPropagation() if event

      if @isFullscreen
        @enableScrollOnRoot()

      # close window
      remainerHeight = @el.height() - @el.find('.zammad-chat-header').outerHeight()
      @el.animate { bottom: -remainerHeight }, 500, @onCloseAnimationEnd

    onCloseAnimationEnd: =>
      @el.css 'bottom', ''
      @el.removeClass('zammad-chat-is-open')

      @showLoader()
      @el.find('.zammad-chat-welcome').removeClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent').addClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent-status').addClass('zammad-chat-is-hidden')

      @isOpen = false
      @options.onCloseAnimationEnd?()

      @io.reconnect()

    onWebSocketClose: =>
      return if @isOpen
      if @el
        @el.removeClass('zammad-chat-is-shown')
        @el.removeClass('zammad-chat-is-loaded')

    show: ->
      return if @state is 'offline'

      @el.addClass('zammad-chat-is-loaded')

      @el.addClass('zammad-chat-is-shown')

    disableInput: ->
      @inputDisabled = true
      @input.prop('contenteditable', false)
      @el.find('.zammad-chat-send').prop('disabled', true)
      @io.close()

    enableInput: ->
      @inputDisabled = false
      @input.prop('contenteditable', true)
      @el.find('.zammad-chat-send').prop('disabled', false)

    hideModal: ->
      @el.find('.zammad-chat-modal').html ''

    onQueueScreen: (data) =>
      @setSessionId data.session_id

      # delay initial queue position, show connecting first
      show = =>
        @onQueue data
        @waitingListTimeout.start()

      if @initialQueueDelay && !@onInitialQueueDelayId
        @onInitialQueueDelayId = setTimeout(show, @initialQueueDelay)
        return

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      # show queue position
      show()

    onQueue: (data) =>
      @log.notice 'onQueue', data.position
      @inQueue = true

      @el.find('.zammad-chat-modal').html @view('waiting')
        position: data.position

    onAgentTypingStart: =>
      if @stopTypingId
        clearTimeout(@stopTypingId)
      @stopTypingId = setTimeout(@onAgentTypingEnd, 3000)

      # never display two typing indicators
      return if @el.find('.zammad-chat-message--typing').get(0)

      @maybeAddTimestamp()

      @el.find('.zammad-chat-body').append @view('typingIndicator')()

      # only if typing indicator is shown
      return if !@isVisible(@el.find('.zammad-chat-message--typing'), true)
      @scrollToBottom()

    onAgentTypingEnd: =>
      @el.find('.zammad-chat-message--typing').remove()

    onLeaveTemporary: =>
      return if !@sessionId
      @send 'chat_session_leave_temporary',
        session_id: @sessionId

    maybeAddTimestamp: ->
      timestamp = Date.now()

      if !@lastTimestamp or (timestamp - @lastTimestamp) > @showTimeEveryXMinutes * 60000
        label = @T('Today')
        time = new Date().toTimeString().substr 0,5
        if @lastAddedType is 'timestamp'
          # update last time
          @updateLastTimestamp label, time
          @lastTimestamp = timestamp
        else
          # add new timestamp
          @el.find('.zammad-chat-body').append @view('timestamp')
            label: label
            time: time
          @lastTimestamp = timestamp
          @lastAddedType = 'timestamp'
          @scrollToBottom()

    updateLastTimestamp: (label, time) ->
      return if !@el
      @el.find('.zammad-chat-body')
        .find('.zammad-chat-timestamp')
        .last()
        .replaceWith @view('timestamp')
          label: label
          time: time

    addStatus: (status) ->
      return if !@el
      @maybeAddTimestamp()

      @el.find('.zammad-chat-body').append @view('status')
        status: status

      @scrollToBottom()

    detectScrolledtoBottom: =>
      scrollBottom = @el.find('.zammad-chat-body').scrollTop() + @el.find('.zammad-chat-body').outerHeight()
      @scrolledToBottom = Math.abs(scrollBottom - @el.find('.zammad-chat-body').prop('scrollHeight')) <= @scrollSnapTolerance
      @el.find('.zammad-scroll-hint').addClass('is-hidden') if @scrolledToBottom

    showScrollHint: ->
      @el.find('.zammad-scroll-hint').removeClass('is-hidden')
      # compensate scroll
      @el.find('.zammad-chat-body').scrollTop(@el.find('.zammad-chat-body').scrollTop() + @el.find('.zammad-scroll-hint').outerHeight())

    onScrollHintClick: =>
      # animate scroll
      @el.find('.zammad-chat-body').animate({scrollTop: @el.find('.zammad-chat-body').prop('scrollHeight')}, 300)

    scrollToBottom: ({ showHint } = { showHint: false }) ->
      if @scrolledToBottom
        @el.find('.zammad-chat-body').scrollTop($('.zammad-chat-body').prop('scrollHeight'))
      else if showHint
        @showScrollHint()

    destroy: (params = {}) =>
      @log.debug 'destroy widget', params

      @setAgentOnlineState 'offline'

      if params.remove && @el
        @el.remove()
        # Remove button, because it can no longer be used.
        $(".#{ @options.buttonClass }").hide()


      # stop all timer
      if @waitingListTimeout
        @waitingListTimeout.stop()
      if @inactiveTimeout
        @inactiveTimeout.stop()
      if @idleTimeout
        @idleTimeout.stop()

      # stop ws connection
      @io.close()

    reconnect: =>
      # set status to connecting
      @log.notice 'reconnecting'
      @disableInput()
      @lastAddedType = 'status'
      @setAgentOnlineState 'connecting'
      @addStatus @T('Connection lost')

    onConnectionReestablished: =>
      # set status back to online
      @lastAddedType = 'status'
      @setAgentOnlineState 'online'
      @addStatus @T('Connection re-established')
      @options.onConnectionReestablished?()

    onSessionClosed: (data) ->
      @addStatus @T('Chat closed by %s', data.realname)
      @disableInput()
      @setAgentOnlineState 'offline'
      @inactiveTimeout.stop()
      @options.onSessionClosed?(data)

    setSessionId: (id) =>
      @sessionId = id
      if id is undefined
        sessionStorage.removeItem 'sessionId'
      else
        sessionStorage.setItem 'sessionId', id

    onConnectionEstablished: (data) =>
      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout @onInitialQueueDelayId

      @inQueue = false
      if data.agent
        @agent = data.agent
      if data.session_id
        @setSessionId data.session_id

      # empty old messages
      @el.find('.zammad-chat-body').html('')

      @el.find('.zammad-chat-agent').html @view('agent')
        agent: @agent

      @enableInput()

      @hideModal()
      @el.find('.zammad-chat-welcome').addClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent').removeClass('zammad-chat-is-hidden')
      @el.find('.zammad-chat-agent-status').removeClass('zammad-chat-is-hidden')

      @input.trigger('focus') if not @isFullscreen

      @setAgentOnlineState 'online'

      @waitingListTimeout.stop()
      @idleTimeout.stop()
      @inactiveTimeout.start()
      @options.onConnectionEstablished?(data)

    showCustomerTimeout: ->
      @el.find('.zammad-chat-modal').html @view('customer_timeout')
        agent: @agent.name
        delay: @options.inactiveTimeout
      reload = ->
        location.reload()
      @el.find('.js-restart').on 'click', reload
      @sessionClose()

    showWaitingListTimeout: ->
      @el.find('.zammad-chat-modal').html @view('waiting_list_timeout')
        delay: @options.watingListTimeout
      reload = ->
        location.reload()
      @el.find('.js-restart').on 'click', reload
      @sessionClose()

    showLoader: ->
      @el.find('.zammad-chat-modal').html @view('loader')()

    setAgentOnlineState: (state) =>
      @state = state
      return if !@el
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1)
      @el
        .find('.zammad-chat-agent-status')
        .attr('data-status', state)
        .text @T(capitalizedState)  # @T('Online') @T('Offline')

    detectHost: ->
      protocol = 'ws://'
      if scriptProtocol is 'https'
        protocol = 'wss://'
      @options.host = "#{ protocol }#{ scriptHost }/ws"

    loadCss: ->
      return if !@options.cssAutoload
      url = @options.cssUrl
      if !url
        url = @options.host
          .replace(/^wss/i, 'https')
          .replace(/^ws/i, 'http')
          .replace(/\/ws$/i, '') # WebSocket may run on example.com/ws path
        url += '/assets/chat/chat.css'

      @log.debug "load css from '#{url}'"
      styles = "@import url('#{url}');"
      newSS = document.createElement('link')
      newSS.onload = @onCssLoaded
      newSS.rel = 'stylesheet'
      newSS.href = 'data:text/css,' + escape(styles)
      document.getElementsByTagName('head')[0].appendChild(newSS)

    onCssLoaded: =>
      @cssLoaded = true
      if @socketReady
        @onReady()
      @options.onCssLoaded?()

    startTimeoutObservers: =>
      @idleTimeout = new Timeout(
        logPrefix: 'idleTimeout'
        debug: @options.debug
        timeout: @options.idleTimeout
        timeoutIntervallCheck: @options.idleTimeoutIntervallCheck
        callback: =>
          @log.debug 'Idle timeout reached, hide widget', new Date
          @destroy(remove: true)
      )
      @inactiveTimeout = new Timeout(
        logPrefix: 'inactiveTimeout'
        debug: @options.debug
        timeout: @options.inactiveTimeout
        timeoutIntervallCheck: @options.inactiveTimeoutIntervallCheck
        callback: =>
          @log.debug 'Inactive timeout reached, show timeout screen.', new Date
          @showCustomerTimeout()
          @destroy(remove: false)
      )
      @waitingListTimeout = new Timeout(
        logPrefix: 'waitingListTimeout'
        debug: @options.debug
        timeout: @options.waitingListTimeout
        timeoutIntervallCheck: @options.waitingListTimeoutIntervallCheck
        callback: =>
          @log.debug 'Waiting list timeout reached, show timeout screen.', new Date
          @showWaitingListTimeout()
          @destroy(remove: false)
      )

    disableScrollOnRoot: ->
      @rootScrollOffset = @scrollRoot.scrollTop()
      @scrollRoot.css
        overflow: 'hidden'
        position: 'fixed'

    enableScrollOnRoot: ->
      @scrollRoot.scrollTop @rootScrollOffset
      @scrollRoot.css
        overflow: ''
        position: ''

    # based on https://github.com/customd/jquery-visible/blob/master/jquery.visible.js
    # to have not dependency, port to coffeescript
    isVisible: (el, partial, hidden, direction) ->
      return if el.length < 1

      $w         = $(window)
      $t         = if el.length > 1 then el.eq(0) else el
      t          = $t.get(0)
      vpWidth    = $w.width()
      vpHeight   = $w.height()
      direction  = if direction then direction else 'both'
      clientSize = if hidden is true then t.offsetWidth * t.offsetHeight else true

      if typeof t.getBoundingClientRect is 'function'

        # Use this native browser method, if available.
        rec      = t.getBoundingClientRect()
        tViz     = rec.top >= 0 && rec.top    <  vpHeight
        bViz     = rec.bottom >  0 && rec.bottom <= vpHeight
        lViz     = rec.left >= 0 && rec.left   <  vpWidth
        rViz     = rec.right  >  0 && rec.right <= vpWidth
        vVisible = if partial then tViz || bViz else tViz && bViz
        hVisible = if partial then lViz || rViz else lViz && rViz

        if direction is 'both'
          return clientSize && vVisible && hVisible
        else if direction is 'vertical'
          return clientSize && vVisible
        else if direction is 'horizontal'
          return clientSize && hVisible
      else
        viewTop         = $w.scrollTop()
        viewBottom      = viewTop + vpHeight
        viewLeft        = $w.scrollLeft()
        viewRight       = viewLeft + vpWidth
        offset          = $t.offset()
        _top            = offset.top
        _bottom         = _top + $t.height()
        _left           = offset.left
        _right          = _left + $t.width()
        compareTop      = if partial is true then _bottom else _top
        compareBottom   = if partial is true then _top else _bottom
        compareLeft     = if partial is true then _right else _left
        compareRight    = if partial is true then _left else _right

        if direction is 'both'
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop)) && ((compareRight <= viewRight) && (compareLeft >= viewLeft))
        else if direction is 'vertical'
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop))
        else if direction is 'horizontal'
          return !!clientSize && ((compareRight <= viewRight) && (compareLeft >= viewLeft))

    isRetina: ->
      if window.matchMedia
        mq = window.matchMedia('only screen and (min--moz-device-pixel-ratio: 1.3), only screen and (-o-min-device-pixel-ratio: 2.6/2), only screen and (-webkit-min-device-pixel-ratio: 1.3), only screen  and (min-device-pixel-ratio: 1.3), only screen and (min-resolution: 1.3dppx)')
        return (mq && mq.matches || (window.devicePixelRatio > 1))
      false

    resizeImage: (dataURL, x = 'auto', y = 'auto', sizeFactor = 1, type, quallity, callback, force = true) ->

      # load image from data url
      imageObject = new Image()
      imageObject.onload = ->
        imageWidth  = imageObject.width
        imageHeight = imageObject.height
        console.log('ImageService', 'current size', imageWidth, imageHeight)
        if y is 'auto' && x is 'auto'
          x = imageWidth
          y = imageHeight

        # get auto dimensions
        if y is 'auto'
          factor = imageWidth / x
          y = imageHeight / factor

        if x is 'auto'
          factor = imageWidth / y
          x = imageHeight / factor

        # check if resize is needed
        resize = false
        if x < imageWidth || y < imageHeight
          resize = true
          x = x * sizeFactor
          y = y * sizeFactor
        else
          x = imageWidth
          y = imageHeight

        # create canvas and set dimensions
        canvas        = document.createElement('canvas')
        canvas.width  = x
        canvas.height = y

        # draw image on canvas and set image dimensions
        context = canvas.getContext('2d')
        context.drawImage(imageObject, 0, 0, x, y)

        # set quallity based on image size
        if quallity == 'auto'
          if x < 200 && y < 200
            quallity = 1
          else if x < 400 && y < 400
            quallity = 0.9
          else if x < 600 && y < 600
            quallity = 0.8
          else if x < 900 && y < 900
            quallity = 0.7
          else
            quallity = 0.6

        # execute callback with resized image
        newDataUrl = canvas.toDataURL(type, quallity)
        if resize
          console.log('ImageService', 'resize', x/sizeFactor, y/sizeFactor, quallity, (newDataUrl.length * 0.75)/1024/1024, 'in mb')
          callback(newDataUrl, x/sizeFactor, y/sizeFactor, true)
          return
        console.log('ImageService', 'no resize', x, y, quallity, (newDataUrl.length * 0.75)/1024/1024, 'in mb')
        callback(newDataUrl, x, y, false)

      # load image from data url
      imageObject.src = dataURL

    # taken from https://stackoverflow.com/questions/6690752/insert-html-at-caret-in-a-contenteditable-div/6691294#6691294
    pasteHtmlAtCaret: (html) ->
      sel = undefined
      range = undefined
      if window.getSelection
        sel = window.getSelection()
        if sel.getRangeAt && sel.rangeCount
          range = sel.getRangeAt(0)
          range.deleteContents()

          el = document.createElement('div')
          el.innerHTML = html
          frag = document.createDocumentFragment(node, lastNode)
          while node = el.firstChild
            lastNode = frag.appendChild(node)
          range.insertNode(frag)

          if lastNode
            range = range.cloneRange()
            range.setStartAfter(lastNode)
            range.collapse(true)
            sel.removeAllRanges()
            sel.addRange(range)
      else if document.selection && document.selection.type != 'Control'
        document.selection.createRange().pasteHTML(html)

    # (C) sbrin - https://github.com/sbrin
    # https://gist.github.com/sbrin/6801034
    wordFilter: (editor) ->
      content = editor.html()

      # Word comments like conditional comments etc
      content = content.replace(/<!--[\s\S]+?-->/gi, '')

      # Remove comments, scripts (e.g., msoShowComment), XML tag, VML content,
      # MS Office namespaced tags, and a few other tags
      content = content.replace(/<(!|script[^>]*>.*?<\/script(?=[>\s])|\/?(\?xml(:\w+)?|img|meta|link|style|\w:\w+)(?=[\s\/>]))[^>]*>/gi, '')

      # Convert <s> into <strike> for line-though
      content = content.replace(/<(\/?)s>/gi, '<$1strike>')

      # Replace nbsp entites to char since it's easier to handle
      # content = content.replace(/&nbsp;/gi, "\u00a0")
      content = content.replace(/&nbsp;/gi, ' ')

      # Convert <span style="mso-spacerun:yes">___</span> to string of alternating
      # breaking/non-breaking spaces of same length
      #content = content.replace(/<span\s+style\s*=\s*"\s*mso-spacerun\s*:\s*yes\s*;?\s*"\s*>([\s\u00a0]*)<\/span>/gi, (str, spaces) ->
      #  return (spaces.length > 0) ? spaces.replace(/./, " ").slice(Math.floor(spaces.length/2)).split("").join("\u00a0") : ''
      #)

      editor.html(content)

      # Parse out list indent level for lists
      $('p', editor).each( ->
        str = $(@).attr('style')
        matches = /mso-list:\w+ \w+([0-9]+)/.exec(str)
        if matches
          $(@).data('_listLevel',  parseInt(matches[1], 10))
      )

      # Parse Lists
      last_level = 0
      pnt = null
      $('p', editor).each(->
        cur_level = $(@).data('_listLevel')
        if cur_level != undefined
          txt = $(@).text()
          list_tag = '<ul></ul>'
          if (/^\s*\w+\./.test(txt))
            matches = /([0-9])\./.exec(txt)
            if matches
              start = parseInt(matches[1], 10)
              list_tag = start>1 ? '<ol start="' + start + '"></ol>' : '<ol></ol>'
            else
              list_tag = '<ol></ol>'

          if cur_level > last_level
            if last_level == 0
              $(@).before(list_tag)
              pnt = $(@).prev()
            else
              pnt = $(list_tag).appendTo(pnt)

          if cur_level < last_level
            for i in [i..last_level-cur_level]
              pnt = pnt.parent()

          $('span:first', @).remove()
          pnt.append('<li>' + $(@).html() + '</li>')
          $(@).remove()
          last_level = cur_level
        else
          last_level = 0
      )

      $('[style]', editor).removeAttr('style')
      $('[align]', editor).removeAttr('align')
      $('span', editor).replaceWith(->
        $(@).contents()
      )
      $('span:empty', editor).remove()
      $("[class^='Mso']", editor).removeAttr('class')
      $('p:empty', editor).remove()
      editor

    removeAttribute: (element) ->
      return if !element
      $element = $(element)
      for att in element.attributes
        if att && att.name
          element.removeAttribute(att.name)
          #$element.removeAttr(att.name)

      $element.removeAttr('style')
        .removeAttr('class')
        .removeAttr('lang')
        .removeAttr('type')
        .removeAttr('align')
        .removeAttr('id')
        .removeAttr('wrap')
        .removeAttr('title')

    removeAttributes: (html, parent = true) =>
      if parent
        html.each((index, element) => @removeAttribute(element) )
      html.find('*').each((index, element) => @removeAttribute(element) )
      html

  window.ZammadChat = ZammadChat
