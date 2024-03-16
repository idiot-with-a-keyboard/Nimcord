import asyncdispatch
import std/json
import ws
import terminal
import os
from times import cpuTime

import strutils

const read_notices:bool=false

#  DiscordPacketData = object
#    case 


let args = commandLineParams()
var ARG_DEBUG:int=4
echo args
echo 0..args.len-1
for i in 0..args.len-1:
  try:
    discard parseInt(args[i])
  except
    case args[i]:
      of "--debug":
        try:
          ARG_DEBUG=parseInt(args[i+1])
          if ARG_DEBUG notin 0..4:
            echo "debug level " & $ARG_DEBUG & " not in 0..4"
            quit()
        except:
          echo "parameter passed to --debug is not an int"

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
        try:
          discard parseInt(args[i])
        except:
          echo "failure in reading arguments, try using --help?"
          quit()

echo "DEBUG=" & $ARG_DEBUG
var connections:seq[Connection]

proc send(con:Connection,data:string)

log(0,"Basic messages")
log(1,"Inconsequential warning")
log(2,"Warning")
log(3,"Error")

if not read_notices:
  echo """
       This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

    If you would like to silence this message change the const "read_notices" to true in the code and recompile with 'nim c -d:ssl nimcord.nim'"""

