import asyncdispatch
import std/json
import ws
import terminal
import os
from times import cpuTime

type
  Connection = object
    sock:Websocket
    closed:bool=false
    token:string

  RawDiscordPacket = object
    op:int = -1
    s:int
    t:string
    d:JsonNode
  
  Opcodes = enum
    Hello
  DiscordPacket = object
    raw:RawDiscordPacket
    case opcode: Opcodes
    of Hello:
      heartbeat_interval:int=45000 #in milliseconds

    

  User = object
    discard

  Guild = object
    case unavailable:bool
    of true:
      id:string
    of false:
      discard


  HelloEvent = object
    heartbeat_interval:int=45000

  ReadyEvent = object
    v:int
    user:User
    guilds:seq[Guild]
    session_id:string
    resume_gateway_url:string

#  DiscordPacketData = object
#    case 


let args = commandLineParams()
let ARG_DEBUG=4
for i in 0..args.len:
  case args[i]:
    of "--debug":
      let ARG_DEBUG=args[i+1]
    of "-h", "--help":
      echo """
              --debug: sets the debug level(everything of higher importance level than the parameter is shown)
                0: verbose, filters nothing
                1: skimming, filters trivial info
                2: warnings only, filters warnings that don't really matter
                3: errors, filters warnings, leaving just big errors that arent catastrophic
                (IE: you would already know because the client crashed lol)

              --help, -h: shows this message"""
      quit()
    else:
      echo "failure in reading arguments, try using --help?"
      quit()


var connections:seq[Connection]

proc log(importance:int,text:string)=
    if ARG_DEBUG>importance:
      let f=open("log.txt",fmAppend)
      f.writeLine("[" & $cpuTime() & "]: " & text)
#proc send(con:Connection,data:string)

proc recvPacket(ws:Websocket):Future[DiscordPacket] {.async.}=
  let bare_pack = parseJson(await ws.receiveStrPacket())
  let raw = to(bare_pack,RawDiscordPacket)
  var pack:DiscordPacket

  pack.raw=raw
  case raw.op:
    of 10:
      pack.opcode=Opcodes.Hello
      pack.heartbeat_interval=raw.d["heartbeat_interval"].getInt(-1)
      if pack.heartbeat_interval == -1:
        log 3, "Error collecting heartbeat interval"
        pack.heartbeat_interval=45000
    else:
      log 3, "Invalid opcode found(" & $raw.op & ")"
      return

  return pack

proc newConnection(token:string):Future[Websocket] {.async.}=
  var ws = await newWebSocket("wss://gateway.discord.gg/?v=9&encoding=json")
  log(0,"Began new websocket")
  let ping_time = (await ws.recvPacket()).heartbeat_interval
  if ping_time != 45000:
    log(1,"Ping loop started with abnormal delay(" & $ping_time & ")")
  else:
    log(0,"Ping loop started(" & $ping_time & ")")
  
  #ws.
