TlkIoClient = require '../src/tlkio-client.coffee'


config =
  room : process.argv[2] or 'tlkio-client-test'
  user :
    nickname : 'Bot'

client = new TlkIoClient config

client.on 'init', (tlkio) ->
  console.log 'Init Done'
  client.say 'I am online'

client.on 'message', (message) ->
  console.log "#{message.text} from #{message.fromUser.name}"


client.on 'user_joined', (user) ->
  console.log "user_joined, #{user.id} #{user.name}"

client.on 'user_left', (user) ->
  console.log "user_left, #{user.id}"
