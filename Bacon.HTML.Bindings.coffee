init = (Bacon) ->
  Bacon.HTML = {}

  Bacon.HTML.ajax = ajax = ({method, url, async, body, user, password, headers, withCredentials}, abort=true) ->
    Bacon.fromBinder (handler) ->
      async = if async is false then false else true
      method ?= "GET"
      headers ?= {}
      body ?= null

      xhr = new XMLHttpRequest()
      
      if withCredentials
        xhr.withCredentials = true
        
      xhr.open(method, url, async, user,password,headers)

      for own header, headerData of headers
        xhr.setRequestHeader header, headerData

      
      Bacon.fromEventTarget(xhr, "readystatechange")
      .map(".target")
      .doAction((x)->
        x.readyState = if x.status > 0 then 4 else 0
      )
      .filter((x) ->
        x.readyState is 4 && x.status >= 200 && x.status < 300 || x.status is 304
      )
      .take(1)
      .assign((x)->
        handler(xhr)
        xhr = null
      )
    
      Bacon.fromEventTarget(xhr, "error")
      .map(".target")
      .take(1)
      .assign((x)->
        handler new Bacon.Error(xhr)
        xhr = null
      )

      xhr.send(body)
      
      (->
        if xhr && abort
          xhr.abort()
          xhr = null
      )
    , (value) -> [value, new Bacon.End()]

  Bacon.HTML.ajaxGet = ajaxGet = (url, abort) -> ajax({url}, abort)

  Bacon.HTML.ajaxPost = (url, body, abort) -> ajax({url, body, method: "POST"}, abort)

  Bacon.HTML.ajaxGetJSON = (url, abort) -> 
    ajaxGet(url, abort).map (xhr) -> JSON.parse xhr.responseText

  Bacon.HTML.lazyAjax = (params,abort) -> Bacon.once(params).flatMap((x) -> ajax(x, abort))

  # asEventStream method (IE8+)

  element = if typeof HTMLElement isnt "undefined"
    HTMLElement #w3c DOM, ie 9+
  else
    Element #ie8  
  
  element::asEventStream = (eventName, eventTransformer) ->
    Bacon.fromEventTarget(@, eventName, eventTransformer)

  Bacon.HTML.fromOnEvent = (target, eventName) ->
    Bacon.fromBinder (handler) ->
      target[eventName] = (args...) -> handler(args...)
      (-> target[eventName] = null)

  Bacon.HTML.fromOnEventCallback = (target, eventName) ->
    Bacon.fromCallback (handler) ->
      target[eventName] = (args...) -> handler(args...)
      (-> target[eventName] = null)

      
    # Request Animation Frame
  cancelRequestAnimFrame = do ->
    window.cancelAnimationFrame or
    window.webkitCancelRequestAnimationFrame or
    window.mozCancelRequestAnimationFrame or
    window.oCancelRequestAnimationFrame or
    window.msCancelRequestAnimationFrame or
    clearTimeout
   
   
  requestAnimFrame = do ->
    window.requestAnimationFrame or
    window.webkitRequestAnimationFrame or
    window.mozRequestAnimationFrame or
    window.oRequestAnimationFrame or
    window.msRequestAnimationFrame or
    (cb) -> setTimeout(cb, 1000 / 60)
   
   
  scheduleFrame = (cb) ->
    id = -1
    animLoop = (x) -> 
      cb(x)
      id = requestAnimFrame(-> animLoop(id))
   
    animLoop(id)    
   
  Bacon.HTML.animFrame = ->
    Bacon.fromBinder (handler) ->
      id = scheduleFrame(handler)
      ->  cancelRequestAnimFrame(id)
  
  
  Bacon.HTML

if module?
  Bacon = require("baconjs")
  module.exports = init(Bacon)
else
  if typeof define == "function" and define.amd
    define ["bacon"], init
  else
    init(this.Bacon)