init = (Bacon) ->
  Bacon.HTML = {}

  Bacon.HTML.ajax = ajax = ({method, url, async, body, user, password, headers}, abort=true) ->
    Bacon.fromBinder (handler) ->
      async = !!async ? true
      method ?= "GET"
      headers ?= {}
      body ?= null

      xhr = new XMLHttpRequest()
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

  Bacon.HTML.ajaxGet = ajaxGet = (url) -> ajax({url})

  Bacon.HTML.ajaxPost = (url, body) -> ajax({url, body, method: "POST"})

  Bacon.HTML.ajaxGetJSON = (url) -> 
    ajaxGet(url).map (xhr) -> JSON.parse xhr.responseText

  Bacon.HTML.lazyAjax = (params) -> Bacon.once(params).flatMap(ajax)

  Bacon.HTML

if module?
  Bacon = require("baconjs")
  module.exports = init(Bacon)
else
  if typeof define == "function" and define.amd
    define ["bacon"], init
  else
    init(this.Bacon)