{.experimental: "codeReordering".}
import std/json
import logger
import ws
import asyncdispatch
import std/options
import strutils

#[     This file is part of Nimcord.

    Nimcord is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    Nimcord is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with Nimcord. If not, see <https://www.gnu.org/licenses/>. ]#

type

  RawDiscordPacket = object
    op:int
    s:Option[int]
    t:Option[string]
    d:JsonNode
  
  Opcodes* = enum
    Hello, Heartbeat, ACK, Identify, Invalid_Session, Ready, Error
  DiscordPacket* = object
    raw:RawDiscordPacket
    case opcode: Opcodes
    of Hello:
      heartbeat_interval:int=45000 #in milliseconds
    of Ready:
      user:User
      #user_settings:
      user_settings_proto:string
      guilds:seq[GateGuild]
      #relationships:seq[Relationship]
      private_channels:seq[Channel]
      #connected_accounts:seq[ConnectedDevice]
      #notes:
      #presences:seq[Presence]
      #merged_presences:
      users:seq[User]
      session_id:string
      required_action:string
      resume_gateway_url:string
    else:
      discard
  User* = object
    id:string
    username:string
    discriminator:string
    global_name:string
    avatar:string
    bot:Option[bool]
    system:Option[bool]
    pronouns:Option[string]
    bio:string
    locale:Option[string]
    flags:int
    public_flags:Option[int]

  Channel* = object
    id:string
    `type`:int
    guild_id:string
    position:int
    #permission_overwrites
    name:string
    topic:string
    last_message_id:string
    nsfw:bool
    rate_limit_per_user:int
    recipients:seq[User]
    icon:string
    owner:GuildMember
    parent_id:string
    message_count:int
    member_count:int
  Guild* = object
    case unavailable:bool
    of true:
      id:string
    of false:
      discard
  GuildMember* = object
    user:User
    nick:string
    avatar:string
    roles:seq[string]
    deaf:bool
    mute:bool
    permissions:string
    flags:int

  GateGuild = object
    member_count:int
    members:seq[GuildMember]
    channels:seq[Channel]
    #threads
    #presences
    #guild_scheduled_events
    data_mode:string
    properties:Guild
    #stickers
    #roles
    #emojis
    #premium_subscription_count

proc recvPacket(ws:Websocket):Future[DiscordPacket] {.async.}=
  var packet:(Opcode,string)
  var data:JsonNode
  while true:
    packet = await ws.receivePacket()
    case packet[0]:
      of Binary,Cont:
        log 3,"HUH???"
      of Text:
        data=parseJson(packet[1])
        break
      of Ping:
        await ws.send(packet[1],Pong)
      of Pong:
        log 0, "heartbeat returned"
      else:
        log 3, $packet

  let bare_pack = data
  let raw = to(bare_pack,RawDiscordPacket)
  var pack:DiscordPacket
  case raw.op:
    of 10:
      pack = DiscordPacket(opcode:Opcodes.Hello,raw:raw)
      pack.heartbeat_interval=raw.d["heartbeat_interval"].getInt(-1)
      if pack.heartbeat_interval == -1:
        log 3, "Error collecting heartbeat interval"
        pack.heartbeat_interval=45000
      return pack

    of 11:
      pack = DiscordPacket(opcode:Opcodes.ACK,raw:raw)
      return pack

    of 9:
      pack = DiscordPacket(opcode:Opcodes.Invalid_Session,raw:raw)
      log 3, $pack
      return pack

    of 0:
      case raw.t.get:
        of "READY":
          pack = DiscordPacket(opcode:Opcodes.Ready,raw:raw)
          pack.user=to(raw.d{"user"},User)
          pack.user_settings_proto=raw.d{"user_settings_proto"}.getStr()
          #pack.guilds=to(raw.d{"guilds"},seq[GateGuild])
      return pack

    else:
      pack = DiscordPacket(opcode:Opcodes.Error,raw:raw)
      log 3, "Can't find opcode " & $raw.op
      log(3, $raw)
      return
  

proc newConnection(identify:string):Future[Websocket] {.async.}=
  var ws = await newWebSocket("wss://gateway.discord.gg/?v=9&encoding=json")
  log(0,"Began new websocket")
  let ping_time = (await ws.recvPacket()).heartbeat_interval
  if ping_time != 45000:
    log(1,"Ping loop started with abnormal delay(" & $ping_time & ")")
  else:
    log(0,"Ping loop started(" & $ping_time & ")")
  ws.setupPings(ping_time / 1000)

  await ws.send("{\"op\": 2, \"d\": " & identify & "}")
  return ws

proc run() {.async.} =
  let testcon = await newConnection(readFile("config.json"))
  while testcon.readyState==Open:
    echo (await testcon.recvPacket())

waitFor run()
