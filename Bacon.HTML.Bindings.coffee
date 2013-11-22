init = (Bacon) ->
  Bacon.HTML = {}

  Bacon.HTML.ajax = ajax = ({method, url, async, body, user, password, headers, withCredentials}, abort=true) ->
    Bacon.fromBinder (handler) ->
      async = if async is false then false else true
      method ?= "GET"
      headers ?= {}
      body ?= null

      xhr = new XMLHttpRequest()
      xhr.withCredentials = !!withCredentials
      xhr.open(method, url, async, user,password,headers)

      for own header, headerData of headers
        xhr.setRequestHeader header, headerData

      unsub =
        Bacon.fromEventTarget(xhr, "readystatechange")
        .map(".target")
        .filter((x) -> x.readyState is 4)
        .map(".status")
        .assign((status)->
          if (status >= 200 and status <= 300) or status is 0 or status is ""
            handler(xhr)
          else  
            handler(new Bacon.Error(xhr))
        )
      
      unsubError = 
        Bacon.fromEventTarget(xhr, "error").assign(->new Bacon.Error(xhr))

      xhr.send(body)
      
      (->
        unsub()
        unsubError()
        if abort then xhr.abort()
      )

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
  
  Bacon.HTML

if module?
  Bacon = require("baconjs")
  module.exports = init(Bacon)
else
  if typeof define == "function" and define.amd
    define ["bacon"], init
  else
    init(this.Bacon)