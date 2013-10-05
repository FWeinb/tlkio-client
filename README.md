tlkio-client
===

Kinda `low-level` tlkio-client used by the hubot adapter [hubot-tlkio](https://github.com/FWeinb/hubot-tlkio) and my own little Bot [tlkio-bot](https://github.com/FWeinb/tlkio-bot).

# Getting Started

  To install just use:

  `npm install tlkio-client --save`

# Sample

  ```
    TlkIoClient = require 'tlkio-client'

    settings =
      room : process.argv[2] or 'tlkio-client-test'
      user :
        nickname : 'Bot'

    client = new TlkIoClient(settings)
  ```

  Just create a config object an pass it in the TlkIoClient constructor.
  Than you can listen to events like this:

  ```
    client.on 'init', (tlkio) ->
      console.log 'Init Done'
      client.say 'I am online'

    client.on 'message', (message) ->
      console.log "#{message.text} from #{message.fromUser.name}"

    client.on 'user_joined', (user) ->
      console.log "user_joined, #{user.id} #{user.name}"x

    client.on 'user_left', (user) ->
      console.log "user_left, #{user.id}"
  ```



# Events

  `init`    - Will be invoked when the connection is established. The tlkio object will hold some metadata


  `message` - Some user wrote a message.  The `message` object which is passed

  ```
    text  : 'Raw text'
    html  : '<b>Raw</b> text'
    fromUser:
      id   : 'UID'
      name : 'username'
      deteils :
        twitter : true|false
        avatar  : 'url to Avatar'
  ```


  `user_joind` - a user joined the room. The `user` object:

  ```
    id : 'UID'
    name : 'username'
    details :
      twitter : true|false
      avatar  : 'url'
  ```

  `ùser_left` - a user left the room. The `user` object:

  ```
    id : 'uid'
  ```
