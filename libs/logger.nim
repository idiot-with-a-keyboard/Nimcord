from    std/times     import getDateStr, getClockStr, cpuTime
from    std/os        import fileExists, tryRemoveFile, moveFile
from    std/envvars   import getEnv
from    std/strutils  import parseInt

#3=         show everything
#2=         show inconsequential warnings
#1=         show warnings
#0=         show errors
#-1/unset = disable
let log_level* :int = parseInt(getEnv("NIM_LOGLEVEL","-1"))
if fileExists("log-old.txt"):
  if not tryRemoveFile("log-old.txt"):
    quit("Failed to remove old log file")

if fileExists("log.txt"):
  moveFile("log.txt","log-old.txt")
else:
  if log_level != -1:
    let f=open("log.txt",fmWrite)
    defer: f.close()
    f.writeLine("Log file started on " & $getDateStr() & "|" & $getClockStr())
proc log*(importance:int,text:string)=
    if 2-log_level<importance:
      let f=open("log.txt",fmAppend)
      defer: f.close()

      f.writeLine("[" & $cpuTime() & "]: " & text)
#example=
#log(0,"test trivial")
#log(1,"misdemeanor")
#log(2,"warning")
#log(3,"error")

#[
     This file is part of Nimcord.

    Nimcord is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    Nimcord is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with Nimcord. If not, see <https://www.gnu.org/licenses/>. ]#
