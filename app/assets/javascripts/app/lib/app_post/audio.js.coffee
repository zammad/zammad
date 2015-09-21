class App.Audio
  @play: ( url, volume = 0.1 ) ->
    return if !window.Audio
    audio = new window.Audio()
    return if !audio.canPlayType
    canPlay = audio.canPlayType('audio/mp3')
    return if canPlay isnt 'maybe' and canPlay isnt 'probably'
    $(audio).prop( 'src', url )
    audio.load()
    audio.preload = 'auto'
    audio.volume = volume
    audio.play()
