Q               = require('q')
util            = require('util')
{EventEmitter}  = require('events')

request         = require('request')
WebSocketClient = require('websocket').client;


class TlkIOClient extends EventEmitter
  version : '0.0.1'

  constructor : (config) ->
    requestCsrfToken(config).then (tlkio) =>
      initWebSocketClient(tlkio, @).then =>
        @connection = tlkio
        @emit 'init', tlkio


  say : (message) ->
    @connection.send message

  socketHost = 'ws.tlk.io'
  host       = 'http://tlk.io'

  postRequest = (options, callback) =>
    request (
      method : 'POST'
      uri : options.uri
      jar : true
      headers :
        Origin : host
        Referer: host + '/' + options.room,
        'X-CSRF-Token' : options.csrf,
        'X-Requested-With':'XMLHttpRequest',
        'Content-Type':'application/json',
        'Accept':'application/json, text/javascript, */*; q=0.01'
      body : JSON.stringify options.data
    ) , callback;

  requestCsrfToken = (config) =>
    deferred = Q.defer()

    # Current room
    room = config.room

    request (
      method : 'GET'
      uri : host + '/' + config.room
      jar : true
    ), (error, response, body) =>
      # I know regex is bad, but it gets shit done...
      matchCsrf   = /<meta content="(.*?)" name="csrf-token" \/>/.exec body # Extract CSRF Token
      matchChatId = /chat_id: '(.*?)'/.exec body                            # Extract chat_id

      # talkio obj
      tlkio =
        csrf    : matchCsrf[1]
        chatid  : matchChatId[1]
        room    : room


      postRequest (
        uri  : host + '/api/participant'
        room : room
        csrf : tlkio.csrf
        data : config.user
      ), (error, response, body) =>
          tlkio.user        = JSON.parse body
          tlkio.user.avatar = config.user.avatar

          messagesRequest =
            uri   : host + '/' + room + '/messages'
            room  : room
            csrf  : tlkio.csrf

          tlkio.send = (message) ->
            messagesRequest.data = {body : message}
            postRequest(messagesRequest)

          deferred.resolve tlkio

    deferred.promise

  initWebSocketClient = (tlkio, tlkioClient) =>
    deferred  = Q.defer()
    client    = new WebSocketClient()

    # on Connect
    client.on 'connect', (connection) =>

      # Heartbeat
      beat = ->
        connection.sendUTF('2::')
        setTimeout beat, 45000
        return

      setTimeout beat, 45000

      actions =
        onInit : ->
          connection.sendUTF '5:::{"name":"subscribe","args":[{"chat_id":"'+tlkio.chatid+'","user_info":null}]}'
          connection.sendUTF '5:::{"name":"authenticate","args":['+JSON.stringify(tlkio.user)+']}'
          deferred.resolve();
          return
        message : (args) ->
          data = args.data
          type = args.type.toLowerCase()

          if type is 'message' and data.user_token isnt tlkio.user.token
            user =
              id      : data.user_token
              room    : tlkio.room
              name    : data.nickname
              details : data.user

            html    = data.body.trim()
            message = html.replace /(<([^>]+)>)/ig, ''

            tlkioClient.emit 'message', (
              id      : data.id
              text    : message
              html    : html
              fromUser: user
            )
          else if type is 'user_joined' or type is 'user_left'
            user =
              id    : data.token
              room  : tlkio.room
              name  : data.nickname
              details :
                avatar  : data.avatar
                twitter : data.twitter

            tlkioClient.emit type, user

          else if type is 'online_participants'

            users = data.users.map (user) -> (
              id    : user.token
              room  : tlkio.room
              name  : user.nickname
              details :
                avatar  : user.avatar
                twitter : user.twitter
            )

            tlkioClient.emit type, users, data.guests_count

      connection.on 'message', (message) ->
        messageData = message.utf8Data
        if messageData.indexOf('1::') is 0
          actions.onInit()
        else if (messageData.indexOf('5:::') is 0)
          json = JSON.parse messageData.substr 4
          func = actions[json.name]

          if func?
            json.args = json.args.map (i) -> return JSON.parse(i)
            func.apply actions, json.args
        return

      connection.on 'error', (error) =>
        console.log "Connection Error: #{error}"
        return

    client.on 'connectFailed',  (error) ->
        console.log "Connect Failed: #{error}"
        return

    request (
      method : 'GET',
      uri    : 'http://' + socketHost + '/socket.io/1',
      headers :
        origin : host
    ), (error, response, body) =>
      parts = body.split ':'
      client.connect 'ws://' + socketHost + '/socket.io/1/websocket/'+parts[0], undefined, host
      return

    deferred.promise;

module.exports = TlkIOClient