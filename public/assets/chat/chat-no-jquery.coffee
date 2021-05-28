do(window) ->

  scripts = document.getElementsByTagName('script')

  # search for script to get protocol and hostname for ws connection
  myScript = scripts[scripts.length - 1]
  scriptProtocol = window.location.protocol.replace(':', '') # set default protocol
  if myScript && myScript.src
    scriptHost = myScript.src.match('.*://([^:/]*).*')[1]
    scriptProtocol = myScript.src.match('(.*)://[^:/]*.*')[1]

  # Define the plugin class
  class Core
    defaults:
      debug: false

    constructor: (options) ->
      @options = {}

      for key, value of @defaults
        @options[key] = value

      for key, value of options
        @options[key] = value

  class Base extends Core
    constructor: (options) ->
      super(options)

      @log = new Log(debug: @options.debug, logPrefix: @options.logPrefix || @logPrefix)

  class Log extends Core
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
      element = document.querySelector('.js-chatLogDisplay')
      if element
        element.innerHTML = '<div>' + logString + '</div>' + element.innerHTML

  class Timeout extends Base
    timeoutStartedAt: null
    logPrefix: 'timeout'
    defaults:
      debug: false
      timeout: 4
      timeoutIntervallCheck: 0.5

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
      target: document.querySelector('body')
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
    inputTimeout: null
    isTyping: false
    state: 'offline'
    initialQueueDelay: 10000
    translations:
      'da':
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> med os!'
        'Scroll down to see new messages': 'Scroll ned for at se nye beskeder'
        'Online': 'Online'
        'Offline': 'Offline'
        'Connecting': 'Forbinder'
        'Connection re-established': 'Forbindelse genoprettet'
        'Today': 'I dag'
        'Send': 'Send'
        'Chat closed by %s': 'Chat lukket af %s'
        'Compose your message...': 'Skriv en besked...'
        'All colleagues are busy.': 'Alle kollegaer er optaget.'
        'You are on waiting list position <strong>%s</strong>.': 'Du er i venteliste som nummer <strong>%s</strong>.'
        'Start new conversation': 'Start en ny samtale'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Da du ikke har svaret i de sidste %s minutter er din samtale med <strong>%s</strong> blevet lukket.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Da du ikke har svaret i de sidste %s minutter er din samtale blevet lukket.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Vi beklager, det tager længere end forventet at få en ledig plads. Prøv venligst igen senere eller send os en e-mail. På forhånd tak!'
      'de':
        '<strong>Chat</strong> with us!': '<strong>Chatte</strong> mit uns!'
        'Scroll down to see new messages': 'Scrolle nach unten um neue Nachrichten zu sehen'
        'Online': 'Online'
        'Offline': 'Offline'
        'Connecting': 'Verbinden'
        'Connection re-established': 'Verbindung wiederhergestellt'
        'Today': 'Heute'
        'Send': 'Senden'
        'Chat closed by %s': 'Chat beendet von %s'
        'Compose your message...': 'Ihre Nachricht...'
        'All colleagues are busy.': 'Alle Kollegen sind belegt.'
        'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste an der Position <strong>%s</strong>.'
        'Start new conversation': 'Neue Konversation starten'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Da Sie in den letzten %s Minuten nichts geschrieben haben wurde Ihre Konversation mit <strong>%s</strong> geschlossen.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Da Sie in den letzten %s Minuten nichts geschrieben haben wurde Ihre Konversation geschlossen.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Es tut uns leid, es dauert länger als erwartet, um einen freien Platz zu erhalten. Bitte versuchen Sie es zu einem späteren Zeitpunkt noch einmal oder schicken Sie uns eine E-Mail. Vielen Dank!'
      'es':
        '<strong>Chat</strong> with us!': '<strong>Chatee</strong> con nosotros!'
        'Scroll down to see new messages': 'Haga scroll hacia abajo para ver nuevos mensajes'
        'Online': 'En linea'
        'Offline': 'Desconectado'
        'Connecting': 'Conectando'
        'Connection re-established': 'Conexión restablecida'
        'Today': 'Hoy'
        'Send': 'Enviar'
        'Chat closed by %s': 'Chat cerrado por %s'
        'Compose your message...': 'Escriba su mensaje...'
        'All colleagues are busy.': 'Todos los agentes están ocupados.'
        'You are on waiting list position <strong>%s</strong>.': 'Usted está en la posición <strong>%s</strong> de la lista de espera.'
        'Start new conversation': 'Iniciar nueva conversación'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Puesto que usted no respondió en los últimos %s minutos su conversación con <strong>%s</strong> se ha cerrado.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Puesto que usted no respondió en los últimos %s minutos su conversación se ha cerrado.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Lo sentimos, se tarda más tiempo de lo esperado para ser atendido por un agente. Inténtelo de nuevo más tarde o envíenos un correo electrónico. ¡Gracias!'
      'fi':
        '<strong>Chat</strong> with us!': '<strong>Keskustele</strong> kanssamme!'
        'Scroll down to see new messages': 'Rullaa alas nähdäksesi uudet viestit'
        'Online': 'Paikalla'
        'Offline': 'Poissa'
        'Connecting': 'Yhdistetään'
        'Connection re-established': 'Yhteys muodostettu uudelleen'
        'Today': 'Tänään'
        'Send': 'Lähetä'
        'Chat closed by %s': '%s sulki keskustelun'
        'Compose your message...': 'Luo viestisi...'
        'All colleagues are busy.': 'Kaikki kollegat ovat varattuja.'
        'You are on waiting list position <strong>%s</strong>.': 'Olet odotuslistalla sijalla <strong>%s</strong>.'
        'Start new conversation': 'Aloita uusi keskustelu'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Koska et vastannut viimeiseen %s minuuttiin, keskustelusi <strong>%s</strong> kanssa suljettiin.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Koska et vastannut viimeiseen %s minuuttiin, keskustelusi suljettiin.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Olemme pahoillamme, tyhjän paikan vapautumisessa kestää odotettua pidempään. Ole hyvä ja yritä myöhemmin uudestaan tai lähetä meille sähköpostia. Kiitos!'
      'fr':
        '<strong>Chat</strong> with us!': '<strong>Chattez</strong> avec nous!'
        'Scroll down to see new messages': 'Faites défiler pour lire les nouveaux messages'
        'Online': 'En-ligne'
        'Offline': 'Hors-ligne'
        'Connecting': 'Connexion en cours'
        'Connection re-established': 'Connexion rétablie'
        'Today': 'Aujourdhui'
        'Send': 'Envoyer'
        'Chat closed by %s': 'Chat fermé par %s'
        'Compose your message...': 'Composez votre message...'
        'All colleagues are busy.': 'Tous les collaborateurs sont occupés actuellement.'
        'You are on waiting list position <strong>%s</strong>.': 'Vous êtes actuellement en position <strong>%s</strong> dans la file d\'attente.'
        'Start new conversation': 'Démarrer une nouvelle conversation'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Si vous ne répondez pas dans les <strong>%s</strong> minutes, votre conversation avec %s sera fermée.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Si vous ne répondez pas dans les %s minutes, votre conversation va être fermée.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Nous sommes désolés, il faut plus de temps que prévu pour obtenir un emplacement vide. Veuillez réessayer ultérieurement ou nous envoyer un courriel. Nous vous remercions!'
      'he':
        '<strong>Chat</strong> with us!': '<strong>שוחח</strong>איתנו!'
        'Scroll down to see new messages': 'גלול מטה כדי לראות הודעות חדשות'
        'Online': 'מחובר'
        'Offline': 'מנותק'
        'Connecting': 'מתחבר'
        'Connection re-established': 'החיבור שוחזר'
        'Today': 'היום'
        'Send': 'שלח'
        'Chat closed by %s': 'הצאט נסגר ע"י %s'
        'Compose your message...': 'כתוב את ההודעה שלך ...'
        'All colleagues are busy.': 'כל הנציגים תפוסים'
        'You are on waiting list position <strong>%s</strong>.': 'מיקומך בתור <strong>%s</strong>.'
        'Start new conversation': 'התחל שיחה חדשה'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'מכיוון שלא הגבת במהלך %s דקות השיחה שלך עם <strong>%s</strong> נסגרה.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'מכיוון שלא הגבת במהלך %s הדקות האחרונות השיחה שלך נסגרה.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'מצטערים, הזמן לקבלת נציג ארוך מהרגיל. נסה שוב מאוחר יותר או שלח לנו דוא"ל. תודה!'
      'hu':
        '<strong>Chat</strong> with us!': '<strong>Chatelj</strong> velünk!'
        'Scroll down to see new messages': 'Görgess lejjebb az újabb üzenetekért'
        'Online': 'Online'
        'Offline': 'Offline'
        'Connecting': 'Csatlakozás'
        'Connection re-established': 'Újracsatlakozás'
        'Today': 'Ma'
        'Send': 'Küldés'
        'Chat closed by %s': 'A beszélgetést lezárta %s'
        'Compose your message...': 'Írj üzenetet...'
        'All colleagues are busy.': 'Jelenleg minden kollégánk elfoglalt.'
        'You are on waiting list position <strong>%s</strong>.': 'A várólistán a <strong>%s</strong>. pozícióban várakozol.'
        'Start new conversation': 'Új beszélgetés indítása'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Mivel %s perce nem érkezett újabb üzenet, ezért a <strong>%s</strong> kollégával folytatott beszéletést lezártuk.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Mivel %s perce nem érkezett válasz, a beszélgetés lezárult.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Sajnáljuk, de a várakozási idő hosszabb a szokásosnál. Kérlek próbáld újra, vagy írd meg kérdésed emailben. Köszönjük!'
      'nl':
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> met ons!'
        'Scroll down to see new messages': 'Scrol naar beneden om nieuwe berichten te zien'
        'Online': 'Online'
        'Offline': 'Offline'
        'Connecting': 'Verbinden'
        'Connection re-established': 'Verbinding herstelt'
        'Today': 'Vandaag'
        'Send': 'Verzenden'
        'Chat closed by %s': 'Chat gesloten door %s'
        'Compose your message...': 'Typ uw bericht...'
        'All colleagues are busy.': 'Alle medewerkers zijn bezet.'
        'You are on waiting list position <strong>%s</strong>.': 'U bent <strong>%s</strong> in de wachtrij.'
        'Start new conversation': 'Nieuwe conversatie starten'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Omdat u in de laatste %s minuten niets geschreven heeft wordt de conversatie met <strong>%s</strong> gesloten.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Omdat u in de laatste %s minuten niets geschreven heeft is de conversatie gesloten.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Het spijt ons, het duurt langer dan verwacht om te antwoorden. Alstublieft probeer het later nogmaals of stuur ons een email. Hartelijk dank!'
      'it':
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> con noi!'
        'Scroll down to see new messages': 'Scorrere verso il basso per vedere i nuovi messaggi'
        'Online': 'Online'
        'Offline': 'Offline'
        'Connecting': 'Collegamento'
        'Connection re-established': 'Collegamento ristabilito'
        'Today': 'Oggi'
        'Send': 'Invio'
        'Chat closed by %s': 'Conversazione chiusa da %s'
        'Compose your message...': 'Comporre il tuo messaggio...'
        'All colleagues are busy.': 'Tutti i colleghi sono occupati.'
        'You are on waiting list position <strong>%s</strong>.': 'Siete in posizione lista d\' attesa <strong>%s</strong>.'
        'Start new conversation': 'Avviare una nuova conversazione'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Dal momento che non hai risposto negli ultimi %s minuti la tua conversazione con <strong>%s</strong> si è chiusa.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Dal momento che non hai risposto negli ultimi %s minuti la tua conversazione si è chiusa.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Ci dispiace, ci vuole più tempo come previsto per ottenere uno slot vuoto. Per favore riprova più tardi o inviaci un\' e-mail. Grazie!'
      'pl':
        '<strong>Chat</strong> with us!': '<strong>Czatuj</strong> z nami!'
        'Scroll down to see new messages': 'Przewiń w dół, aby wyświetlić nowe wiadomości'
        'Online': 'Online'
        'Offline': 'Offline'
        'Connecting': 'Łączenie'
        'Connection re-established': 'Ponowne nawiązanie połączenia'
        'Today': 'dzisiejszy'
        'Send': 'Wyślij'
        'Chat closed by %s': 'Czat zamknięty przez %s'
        'Compose your message...': 'Utwórz swoją wiadomość...'
        'All colleagues are busy.': 'Wszyscy koledzy są zajęci.'
        'You are on waiting list position <strong>%s</strong>.': 'Na liście oczekujących znajduje się pozycja <strong>%s</strong>.'
        'Start new conversation': 'Rozpoczęcie nowej konwersacji'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Ponieważ w ciągu ostatnich %s minut nie odpowiedziałeś, Twoja rozmowa z <strong>%s</strong> została zamknięta.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa została zamknięta.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Przykro nam, ale to trwa dłużej niż się spodziewamy. Spróbuj ponownie później lub wyślij nam wiadomość e-mail. Dziękuję!'
      'pt-br': {
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> fale conosco!',
        'Scroll down to see new messages': 'Role para baixo, para ver nosvas mensagens',
        'Online': 'Online',
        'Offline': 'Desconectado',
        'Connecting': 'Conectando',
        'Connection re-established': 'Conexão restabelecida',
        'Today': 'Hoje',
        'Send': 'Enviar',
        'Chat closed by %s': 'Chat encerrado por %s',
        'Compose your message...': 'Escreva sua mensagem...',
        'All colleagues are busy.': 'Todos os agentes estão ocupados.',
        'You are on waiting list position <strong>%s</strong>.': 'Você está na posição <strong>%s</strong> na fila de espera.',
        'Start new conversation': 'Iniciar uma nova conversa',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Como você não respondeu nos últimos %s minutos sua conversa com <strong>%s</strong> foi encerrada.',
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Como você não respondeu nos últimos %s minutos sua conversa foi encerrada.',
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Desculpe, mas o tempo de espera por um agente foi excedido. Tente novamente mais tarde ou nós envie um email. Obrigado'
      },
      'zh-cn':
        '<strong>Chat</strong> with us!': '发起<strong>即时对话</strong>!'
        'Scroll down to see new messages': '向下滚动以查看新消息'
        'Online': '在线'
        'Offline': '离线'
        'Connecting': '连接中'
        'Connection re-established': '正在重新建立连接'
        'Today': '今天'
        'Send': '发送'
        'Chat closed by %s': 'Chat closed by %s'
        'Compose your message...': '正在输入信息...'
        'All colleagues are busy.': '所有工作人员都在忙碌中.'
        'You are on waiting list position <strong>%s</strong>.': '您目前的等候位置是第 <strong>%s</strong> 位.'
        'Start new conversation': '开始新的会话'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': '由于您超过 %s 分钟没有回复, 您与 <strong>%s</strong> 的会话已被关闭.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': '由于您超过 %s 分钟没有任何回复, 该对话已被关闭.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': '非常抱歉, 目前需要等候更长的时间才能接入对话, 请稍后重试或向我们发送电子邮件. 谢谢!'
      'zh-tw':
        '<strong>Chat</strong> with us!': '開始<strong>即時對话</strong>!'
        'Scroll down to see new messages': '向下滑動以查看新訊息'
        'Online': '線上'
        'Offline': '离线'
        'Connecting': '連線中'
        'Connection re-established': '正在重新建立連線中'
        'Today': '今天'
        'Send': '發送'
        'Chat closed by %s': 'Chat closed by %s'
        'Compose your message...': '正在輸入訊息...'
        'All colleagues are busy.': '所有服務人員都在忙碌中.'
        'You are on waiting list position <strong>%s</strong>.': '你目前的等候位置是第 <strong>%s</strong> 順位.'
        'Start new conversation': '開始新的對話'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': '由於你超過 %s 分鐘沒有回應, 你與 <strong>%s</strong> 的對話已被關閉.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': '由於你超過 %s 分鐘沒有任何回應, 該對話已被關閉.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': '非常抱歉, 當前需要等候更長的時間方可排入對話程序, 請稍後重試或向我們寄送電子郵件. 謝謝!'
      'ru':
        '<strong>Chat</strong> with us!': 'Напишите нам!'
        'Scroll down to see new messages': 'Прокрутите, чтобы увидеть новые сообщения'
        'Online': 'Онлайн'
        'Offline': 'Оффлайн'
        'Connecting': 'Подключение'
        'Connection re-established': 'Подключение восстановлено'
        'Today': 'Сегодня'
        'Send': 'Отправить'
        'Chat closed by %s': '%s закрыл чат'
        'Compose your message...': 'Напишите сообщение...'
        'All colleagues are busy.': 'Все сотрудники заняты'
        'You are on waiting list position %s.': 'Вы в списке ожидания под номером %s'
        'Start new conversation': 'Начать новую переписку.'
        'Since you didn\'t respond in the last %s minutes your conversation with %s got closed.': 'Поскольку вы не отвечали в течение последних %s минут, ваш разговор с %s был закрыт.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Поскольку вы не отвечали в течение последних %s минут, ваш разговор был закрыт.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'К сожалению, ожидание свободного места требует больше времени. Повторите попытку позже или отправьте нам электронное письмо. Спасибо!'
      'sv':
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> med oss!'
        'Scroll down to see new messages': 'Rulla ner för att se nya meddelanden'
        'Online': 'Online'
        'Offline': 'Offline'
        'Connecting': 'Ansluter'
        'Connection re-established': 'Anslutningen återupprättas'
        'Today': 'I dag'
        'Send': 'Skicka'
        'Chat closed by %s': 'Chatt stängd av %s'
        'Compose your message...': 'Skriv ditt meddelande...'
        'All colleagues are busy.': 'Alla kollegor är upptagna.'
        'You are on waiting list position <strong>%s</strong>.': 'Du är på väntelistan som position <strong>%s</strong>.'
        'Start new conversation': 'Starta ny konversation'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Eftersom du inte svarat inom %s minuterna i din konversation med <strong>%s</strong> så stängdes chatten.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Då du inte svarat inom de senaste %s minuterna så avslutades din chatt.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Vi är ledsna, det tar längre tid som förväntat att få en ledig plats. Försök igen senare eller skicka ett e-postmeddelande till oss. Tack!'
      'no':
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> med oss!'
        'Scroll down to see new messages': 'Bla ned for å se nye meldinger'
        'Online': 'Pålogget'
        'Offline': 'Avlogget'
        'Connecting': 'Koble til'
        'Connection re-established': 'Tilkoblingen er gjenopprettet'
        'Today': 'I dag'
        'Send': 'Send'
        'Chat closed by %s': 'Chat avsluttes om %s'
        'Compose your message...': 'Skriv din melding...'
        'All colleagues are busy.': 'Alle våre kolleger er for øyeblikket opptatt.'
        'You are on waiting list position <strong>%s</strong>.': 'Du står nå i kø og er nr. <strong>%s</strong> på ventelisten.'
        'Start new conversation': 'Start en ny samtale'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Ettersom du ikke har respondert i løpet av de siste %s minuttene av samtalen, vil samtalen med  <strong>%s</strong> nå avsluttes.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Ettersom du ikke har respondert i løpet av de siste %s minuttene, har samtalen nå blitt avsluttet.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Vi beklager, men det tar lengre tid enn vanlig å få en ledig plass i vår chat. Vennligst prøv igjen på et senere tidspunkt eller send oss en e-post. Tusen takk!'
      'nb':
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> med oss!'
        'Scroll down to see new messages': 'Bla ned for å se nye meldinger'
        'Online': 'Pålogget'
        'Offline': 'Avlogget'
        'Connecting': 'Koble til'
        'Connection re-established': 'Tilkoblingen er gjenopprettet'
        'Today': 'I dag'
        'Send': 'Send'
        'Chat closed by %s': 'Chat avsluttes om %s'
        'Compose your message...': 'Skriv din melding...'
        'All colleagues are busy.': 'Alle våre kolleger er for øyeblikket opptatt.'
        'You are on waiting list position <strong>%s</strong>.': 'Du står nå i kø og er nr. <strong>%s</strong> på ventelisten.'
        'Start new conversation': 'Start en ny samtale'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Ettersom du ikke har respondert i løpet av de siste %s minuttene av samtalen, vil samtalen med  <strong>%s</strong> nå avsluttes.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Ettersom du ikke har respondert i løpet av de siste %s minuttene, har samtalen nå blitt avsluttet.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Vi beklager, men det tar lengre tid enn vanlig å få en ledig plass i vår chat. Vennligst prøv igjen på et senere tidspunkt eller send oss en e-post. Tusen takk!'
      'el':
        '<strong>Chat</strong> with us!': '<strong>Επικοινωνήστε</strong> μαζί μας!'
        'Scroll down to see new messages': 'Μεταβείτε κάτω για να δείτε τα νέα μηνύματα'
        'Online': 'Σε σύνδεση'
        'Offline': 'Αποσυνδεμένος'
        'Connecting': 'Σύνδεση'
        'Connection re-established': 'Η σύνδεση αποκαταστάθηκε'
        'Today': 'Σήμερα'
        'Send': 'Αποστολή'
        'Chat closed by %s': 'Η συνομιλία έκλεισε από τον/την %s'
        'Compose your message...': 'Γράψτε το μήνυμα σας...'
        'All colleagues are busy.': 'Όλοι οι συνάδελφοι μας είναι απασχολημένοι.'
        'You are on waiting list position <strong>%s</strong>.': 'Βρίσκεστε σε λίστα αναμονής στη θέση <strong>%s</strong>.'
        'Start new conversation': 'Έναρξη νέας συνομιλίας'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> got closed.': 'Από τη στιγμή που δεν απαντήσατε τα τελευταία %s λεπτά η συνομιλία σας με τον/την <strong>%s</strong> έκλεισε.'
        'Since you didn\'t respond in the last %s minutes your conversation got closed.': 'Από τη στιγμή που δεν απαντήσατε τα τελευταία %s λεπτά η συνομιλία σας έκλεισε.'
        'We are sorry, it takes longer as expected to get an empty slot. Please try again later or send us an email. Thank you!': 'Λυπούμαστε που χρειάζεται περισσότερος χρόνος από τον αναμενόμενο για να βρεθεί μία κενή θέση. Παρακαλούμε δοκιμάστε ξανά αργότερα ή στείλτε μας ένα email. Ευχαριστούμε!'
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
      super(options)

      # jQuery migration
      if typeof jQuery != 'undefined' && @options.target instanceof jQuery
        @log.notice 'Chat: target option is a jQuery object. jQuery is not a requirement for the chat any more.'
        @options.target = @options.target.get(0)

      # fullscreen
      @isFullscreen = (window.matchMedia and window.matchMedia('(max-width: 768px)').matches)
      @scrollRoot = @getScrollRoot()

      # check prerequisites
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
        @options.lang = document.documentElement.getAttribute('lang')
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
      start = parseInt(html.pageYOffset, 10)
      html.pageYOffset = start + 1
      end = parseInt(html.pageYOffset, 10)
      html.pageYOffset = start
      return if end > start then html else document.body

    render: =>
      if !@el || !document.querySelector('.zammad-chat')
        @renderBase()

      # disable open button
      btn = document.querySelector(".#{ @options.buttonClass }")
      if btn
        btn.classList.add @options.inactiveClass

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
      @el.remove() if @el
      @options.target.insertAdjacentHTML('beforeend', @view('chat')(
        title: @options.title,
        scrollHint: @options.scrollHint
      ))
      @el = @options.target.querySelector('.zammad-chat')
      @input = @el.querySelector('.zammad-chat-input')
      @body = @el.querySelector('.zammad-chat-body')

      # start bindings
      @el.querySelector('.js-chat-open').addEventListener('click', @open)
      @el.querySelector('.js-chat-toggle').addEventListener('click', @toggle)
      @el.querySelector('.js-chat-status').addEventListener('click', @stopPropagation)
      @el.querySelector('.zammad-chat-controls').addEventListener('submit', @onSubmit)
      @body.addEventListener('scroll', @detectScrolledtoBottom)
      @el.querySelector('.zammad-scroll-hint').addEventListener('click', @onScrollHintClick)
      @input.addEventListener('keydown', @onKeydown)
      @input.addEventListener('input', @onInput)
      @input.addEventListener('paste', @onPaste)
      @input.addEventListener('drop', @onDrop)

      window.addEventListener('beforeunload', @onLeaveTemporary)
      window.addEventListener('hashchange', =>
        if @isOpen
          if @sessionId
            @send 'chat_session_notice',
              session_id: @sessionId
              message: window.location.href
          return
        @idleTimeout.start()
      )

    stopPropagation: (event) ->
      event.stopPropagation()

    onDrop: (e) =>
      e.stopPropagation()
      e.preventDefault()

      if window.dataTransfer # ie
        dataTransfer = window.dataTransfer
      else if e.dataTransfer # other browsers
        dataTransfer = e.dataTransfer
      else
        throw 'No clipboardData support'

      x = e.clientX
      y = e.clientY
      file = dataTransfer.files[0]

      # look for images
      if file.type.match('image.*')
        reader = new FileReader()
        reader.onload = (e) =>
          # Insert the image at the carat
          insert = (dataUrl, width) =>

            # adapt image if we are on retina devices
            if @isRetina()
              width = width / 2

            result = dataUrl
            img = new Image()
            img.style.width = '100%'
            img.style.maxWidth = width + 'px'
            img.src = result

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
          @resizeImage(e.target.result, 460, 'auto', 2, 'image/jpeg', 'auto', insert)
        reader.readAsDataURL(file)

    onPaste: (e) =>
      e.stopPropagation()
      e.preventDefault()

      if e.clipboardData
        clipboardData = e.clipboardData
      else if window.clipboardData
        clipboardData = window.clipboardData
      else if e.clipboardData
        clipboardData = e.clipboardData
      else
        throw 'No clipboardData support'

      imageInserted = false
      if clipboardData && clipboardData.items && clipboardData.items[0]
        item = clipboardData.items[0]
        if item.kind == 'file' && (item.type == 'image/png' || item.type == 'image/jpeg')
          imageFile = item.getAsFile()
          reader = new FileReader()

          reader.onload = (e) =>
            insert = (dataUrl, width) =>

              # adapt image if we are on retina devices
              if @isRetina()
                width = width / 2

              img = new Image()
              img.style.width = '100%'
              img.style.maxWidth = width + 'px'
              img.src = dataUrl
              document.execCommand('insertHTML', false, img)

            # resize if to big
            @resizeImage(e.target.result, 460, 'auto', 2, 'image/jpeg', 'auto', insert)

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
        html = document.createElement('div')
        html.innerHTML = text
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

        for node in html.childNodes
          if node.nodeType == 8
            node.remove()

        # remove tags, keep content
        for node in html.querySelectorAll('a, font, small, time, form, label')
          node.outerHTML = node.innerHTML

        # replace tags with generic div
        # New type of the tag
        replacementTag = 'div';

        # Replace all x tags with the type of replacementTag
        for node in html.querySelectorAll('textarea')
          outer = node.outerHTML

          # Replace opening tag
          regex = new RegExp('<' + node.tagName, 'i')
          newTag = outer.replace(regex, '<' + replacementTag)

          # Replace closing tag
          regex = new RegExp('</' + node.tagName, 'i')
          newTag = newTag.replace(regex, '</' + replacementTag)

          node.outerHTML = newTag

        # remove tags & content
        for node in html.querySelectorAll('font, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset')
          node.remove()

        @removeAttributes(html)

        text = html.innerHTML

      # as fallback, insert html via pasteHtmlAtCaret (for IE 11 and lower)
      if docType is 'text3'
        @pasteHtmlAtCaret(text)
      else
        document.execCommand('insertHTML', false, text)
      true

    onKeydown: (e) =>
      # check for enter
      if not e.shiftKey and e.keyCode is 13
        e.preventDefault()
        @sendMessage()

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
      btn = document.querySelector(".#{ @options.buttonClass }")
      if btn
        btn.addEventListener('click', @open)
        btn.classList.remove(@options.inactiveClass)

      @options.onReady?()

      if @options.show
        @show()

    onError: (message) =>
      @log.debug message
      @addStatus(message)
      btn = document.querySelector(".#{ @options.buttonClass }")
      if btn
        btn.classList.add('zammad-chat-is-hidden')

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
          @input.innerHTML = unfinishedMessage

      # show wait list
      if data.position
        @onQueue data

      @show()
      @open()
      @scrollToBottom()

      if unfinishedMessage
        @input.focus()

    onInput: =>
      # remove unread-state from messages
      for message in @el.querySelectorAll('.zammad-chat-message--unread')
        message.classList.remove 'zammad-chat-message--unread'

      sessionStorage.setItem 'unfinished_message', @input.innerHTML

      @onTyping()

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
      message = @input.innerHTML
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
      if @el.querySelector('.zammad-chat-message--typing')
        @lastAddedType = 'typing-placeholder'
        @el.querySelector('.zammad-chat-message--typing').insertAdjacentHTML('beforebegin', messageElement)
      else
        @lastAddedType = 'message--customer'
        @body.insertAdjacentHTML('beforeend', messageElement)

      @input.innerHTML = ''
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
      @body.insertAdjacentHTML('beforeend', @view('message')(data))

    open: =>
      if @isOpen
        @log.debug 'widget already open, block'
        return

      @isOpen = true
      @log.debug 'open widget'
      @show()

      if !@sessionId
        @showLoader()

      @el.classList.add 'zammad-chat-is-open'
      remainerHeight = @el.clientHeight - @el.querySelector('.zammad-chat-header').offsetHeight
      @el.style.transform = "translateY(#{remainerHeight}px)"
      # force redraw
      @el.clientHeight

      if !@sessionId
        @el.addEventListener 'transitionend', @onOpenAnimationEnd
        @el.classList.add 'zammad-chat--animate'
        # force redraw
        @el.clientHeight
        # start animation
        @el.style.transform = ''

        @send('chat_session_init'
          url: window.location.href
        )
      else
        @el.style.transform = ''
        @onOpenAnimationEnd()

    onOpenAnimationEnd: =>
      @el.removeEventListener 'transitionend', @onOpenAnimationEnd
      @el.classList.remove 'zammad-chat--animate'
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
      if !@sessionId
        @log.debug 'can\'t close widget without sessionId'
        return

      @log.debug 'close widget'

      event.stopPropagation() if event

      @sessionClose()

      if @isFullscreen
        @enableScrollOnRoot()

      # close window
      remainerHeight = @el.clientHeight - @el.querySelector('.zammad-chat-header').offsetHeight
      @el.addEventListener 'transitionend', @onCloseAnimationEnd
      @el.classList.add 'zammad-chat--animate'
      # force redraw
      document.offsetHeight
      # animate out
      @el.style.transform = "translateY(#{remainerHeight}px)"

    onCloseAnimationEnd: =>
      @el.removeEventListener 'transitionend', @onCloseAnimationEnd
      @el.classList.remove 'zammad-chat-is-open', 'zammad-chat--animate'
      @el.style.transform = ''

      @showLoader()
      @el.querySelector('.zammad-chat-welcome').classList.remove('zammad-chat-is-hidden')
      @el.querySelector('.zammad-chat-agent').classList.add('zammad-chat-is-hidden')
      @el.querySelector('.zammad-chat-agent-status').classList.add('zammad-chat-is-hidden')

      @isOpen = false
      @options.onCloseAnimationEnd?()

      @io.reconnect()

    onWebSocketClose: =>
      return if @isOpen
      if @el
        @el.classList.remove('zammad-chat-is-shown')
        @el.classList.remove('zammad-chat-is-loaded')

    show: ->
      return if @state is 'offline'

      @el.classList.add('zammad-chat-is-loaded')
      @el.classList.add('zammad-chat-is-shown')

    disableInput: ->
      @input.disabled = true
      @el.querySelector('.zammad-chat-send').disabled = true

    enableInput: ->
      @input.disabled = false
      @el.querySelector('.zammad-chat-send').disabled = false

    hideModal: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = ''

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

      @el.querySelector('.zammad-chat-modal').innerHTML = @view('waiting')
        position: data.position

    onAgentTypingStart: =>
      if @stopTypingId
        clearTimeout(@stopTypingId)
      @stopTypingId = setTimeout(@onAgentTypingEnd, 3000)

      # never display two typing indicators
      return if @el.querySelector('.zammad-chat-message--typing')

      @maybeAddTimestamp()

      @body.insertAdjacentHTML('beforeend', @view('typingIndicator')())

      # only if typing indicator is shown
      return if !@isVisible(@el.querySelector('.zammad-chat-message--typing'), true)
      @scrollToBottom()

    onAgentTypingEnd: =>
      @el.querySelector('.zammad-chat-message--typing').remove() if @el.querySelector('.zammad-chat-message--typing')

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
          @body.insertAdjacentHTML 'beforeend', @view('timestamp')
            label: label
            time: time
          @lastTimestamp = timestamp
          @lastAddedType = 'timestamp'
          @scrollToBottom()

    updateLastTimestamp: (label, time) ->
      return if !@el
      timestamps = @el.querySelectorAll('.zammad-chat-body .zammad-chat-timestamp')
      return if !timestamps
      timestamps[timestamps.length - 1].outerHTML = @view('timestamp')
        label: label
        time: time

    addStatus: (status) ->
      return if !@el
      @maybeAddTimestamp()

      @body.insertAdjacentHTML 'beforeend', @view('status')
        status: status

      @scrollToBottom()

    detectScrolledtoBottom: =>
      scrollBottom = @body.scrollTop + @body.offsetHeight
      @scrolledToBottom = Math.abs(scrollBottom - @body.scrollHeight) <= @scrollSnapTolerance
      @el.querySelector('.zammad-scroll-hint').classList.add('is-hidden') if @scrolledToBottom

    showScrollHint: ->
      @el.querySelector('.zammad-scroll-hint').classList.remove('is-hidden')
      # compensate scroll
      @body.scrollTop = @body.scrollTop + @el.querySelector('.zammad-scroll-hint').offsetHeight

    onScrollHintClick: =>
      # animate scroll
      @body.scrollTo
        top: @body.scrollHeight
        behavior: 'smooth'

    scrollToBottom: ({ showHint } = { showHint: false }) ->
      if @scrolledToBottom
        @body.scrollTop = @body.scrollHeight
      else if showHint
        @showScrollHint()

    destroy: (params = {}) =>
      @log.debug 'destroy widget', params

      @setAgentOnlineState 'offline'

      if params.remove && @el
        @el.remove()

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
      @body.innerHTML = ''

      @el.querySelector('.zammad-chat-agent').innerHTML = @view('agent')
        agent: @agent

      @enableInput()

      @hideModal()
      @el.querySelector('.zammad-chat-welcome').classList.add('zammad-chat-is-hidden')
      @el.querySelector('.zammad-chat-agent').classList.remove('zammad-chat-is-hidden')
      @el.querySelector('.zammad-chat-agent-status').classList.remove('zammad-chat-is-hidden')

      @input.focus() if not @isFullscreen

      @setAgentOnlineState 'online'

      @waitingListTimeout.stop()
      @idleTimeout.stop()
      @inactiveTimeout.start()
      @options.onConnectionEstablished?(data)

    showCustomerTimeout: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('customer_timeout')
        agent: @agent.name
        delay: @options.inactiveTimeout
      @el.querySelector('.js-restart').addEventListener 'click', -> location.reload()
      @sessionClose()

    showWaitingListTimeout: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('waiting_list_timeout')
        delay: @options.watingListTimeout
      @el.querySelector('.js-restart').addEventListener 'click', -> location.reload()
      @sessionClose()

    showLoader: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('loader')()

    setAgentOnlineState: (state) =>
      @state = state
      return if !@el
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1)
      @el.querySelector('.zammad-chat-agent-status').dataset.status = state
      @el.querySelector('.zammad-chat-agent-status').textContent = @T(capitalizedState)

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
          .replace(/\/ws/i, '')
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
      @rootScrollOffset = @scrollRoot.scrollTop
      @scrollRoot.style.overflow = 'hidden'
      @scrollRoot.style.position = 'fixed'

    enableScrollOnRoot: ->
      @scrollRoot.scrollTop = @rootScrollOffset
      @scrollRoot.style.overflow = ''
      @scrollRoot.style.position = ''

    # based on https://github.com/customd/jquery-visible/blob/master/jquery.visible.js
    # to have not dependency, port to coffeescript
    isVisible: (el, partial, hidden, direction) ->
      return if el.length < 1

      vpWidth    = window.innerWidth
      vpHeight   = window.innerHeight
      direction  = if direction then direction else 'both'
      clientSize = if hidden is true then t.offsetWidth * t.offsetHeight else true

      rec      = el.getBoundingClientRect()
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

      editor.innerHTML = content

      # Parse out list indent level for lists
      for p in editor.querySelectorAll('p')
        str = p.getAttribute('style')
        matches = /mso-list:\w+ \w+([0-9]+)/.exec(str)
        if matches
          p.dataset._listLevel = parseInt(matches[1], 10)

      # Parse Lists
      last_level = 0
      pnt = null
      for p in editor.querySelectorAll('p')
        cur_level = p.dataset._listLevel
        if cur_level != undefined
          txt = p.textContent
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
              p.insertAdjacentHTML 'beforebegin', list_tag
              pnt = p.previousElementSibling
            else
            pnt.insertAdjacentHTML 'beforeend', list_tag

          if cur_level < last_level
            for i in [i..last_level-cur_level]
              pnt = pnt.parentNode

          p.querySelector('span:first').remove() if p.querySelector('span:first')
          pnt.insertAdjacentHTML 'beforeend', '<li>' + p.innerHTML + '</li>'
          p.remove()
          last_level = cur_level
        else
          last_level = 0

      el.removeAttribute('style') for el in editor.querySelectorAll('[style]')
      el.removeAttribute('align') for el in editor.querySelectorAll('[align]')
      el.outerHTML = el.innerHTML for el in editor.querySelectorAll('span')
      el.remove() for el in editor.querySelectorAll('span:empty')
      el.removeAttribute('class') for el in editor.querySelectorAll("[class^='Mso']")
      el.remove() for el in editor.querySelectorAll('p:empty')
      editor

    removeAttribute: (element) ->
      return if !element
      for att in element.attributes
        element.removeAttribute(att.name)

    removeAttributes: (html) =>
      for node in html.querySelectorAll('*')
        @removeAttribute node
      html

  window.ZammadChat = ZammadChat
