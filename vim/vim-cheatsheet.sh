#!/bin/bash

printf '\e[35mmagenta: buffers/files/windows/tabs
\e[32mgreen: actions\e[0m
\e[36mcyan: movement
\e[34mblue: visual mode
\e[33myellow: insert
\e[31mred: delete/copy/paste\e[0m
can put numbers in front of nearly any command, e.g. \e[1;36m5h\e[0m to move 5 chars left

vim \e[1;35m-R\e[0;35m [files...]\e[0m open files in read-only mode
\e[1;35m:edit\e[0;35m[!] [file]\e[0m open file (! discards changes to current file)
\e[1;35m:saveas\e[0m save as
\e[1;35m:\e[0;35m[w]\e[1mn[ext]\e[0m [save changes to current file and] go to next file
\e[1;35m:\e[0;35m[w]\e[1mprev[ious]\e[0m [save changes to current file and] go to previous file
\e[1;35m:fir[st]\e[0m / \e[1;35m:la[st]\e[0m go to first/last file in list
\e[1;35m:args\e[0;35m [file1.txt] [file2.txt] [*.txt]\e[0m open new list of files
\e[1;35mCtrl-^\e[0m swap to "alternate" file and back without changing position in list
\e[1;35m:buffers\e[0m / \e[1;35m:files\e[0m / \e[1;35m:ls\e[0m \e[35m[!]\e[0m list all [include unlisted] files in buffer list

\e[1;35m:[n][v]sp[lit]\e[0m \e[35m[file.txt]\e[0m split window, window will be n lines high/wide
\e[1;35m:[n][v]new\e[0m split window on new file, window will be n lines high/wide
\e[1;35m:[vert[ical]] ter[minal]\e[0m \e[35m[options] [command]\e[0m open a new terminal window
\e[1;35mCtrl-W h\e[0m/\e[1;35mj\e[0m/\e[1;35mk\e[0m/\e[1;35ml\e[0m go N windows left/down/up/right
\e[1;35mCtrl-W H\e[0m/\e[1;35mJ\e[0m/\e[1;35mK\e[0m/\e[1;35mL\e[0m move window to the far left/bottom/top/right
\e[1;35m:clo[se]\e[0m / \e[1;35mCtrl-W c\e[0m close current window
\e[1;35m:on[ly]\e[0m / \e[1;35mCtrl-W o\e[0m close all other windows
\e[1;35m:\e[0;35m[w]\e[1;35mqa[ll]\e[0;35m[!]\e[0m close all windows and quit
\e[1;35m[n] Ctrl-W [+/-/_]\e[0m increase/decrease/set size of window

vim \e[1;35m-p[n]\e[0m [files...] open up to N (or tabpagemax) tab pages, one for each file
\e[1;35m:tabe[dit]\e[0;35m [file]\e[0m / \e[1;35m:tabnew\e[0m edit file/create new file in a new tab page
\e[1;35mgt\e[0m / \e[1;35mgT\e[0m go to next/previous tab
\e[1;35m:tabs\e[0m list tab pages

  \e[1;32mu\e[0m  undo        \e[1;32mCtrl-R\e[0m  redo
  \e[1;32m.\e[0m  repeat last command

go to line:   \e[1;36mgg\e[0m line 1         \e[1;36m:n\e[0m / \e[1;36mnG\e[0m line n    \e[1;36mG\e[0m last line
\e[1;36mCtrl-U\e[0m up half screen of text   \e[1;36mCtrl-D\e[0m down half screen of text
\e[1;36mzz\e[0m center cursor line  \e[1;36mzt\e[0m cursor line at top  \e[1;36mzb\e[0m cursor line at bottom
\e[1;36m{\e[0m / \e[1;36m}\e[0m code block
\e[1;36m0\e[0m        \e[1;36m^\e[0mmove to first/first non-blank/last char in line\e[1;36m$\e[0m
\e[1;36mgm\e[0m/\e[1;36mgM\e[0m to middle of line / screen line
\e[1;36m[n]f\e[0m/\e[1;36mF{char}\e[0m to nth occurrence of {char} to the right/left
\e[1;36m[n]t\e[0m/\e[1;36mT{char}\e[0m till before the nth occurrence of {char} to the right/left
\e[1;36m``\e[0m previous cursor position    \e[1;36m`.\e[0m position of last change
\e[1;36m`"\e[0m cursor position when last editing file
\e[1;36mm[a-zA-Z]\e[0m place mark  \e[1;36m`[a-zA-Z]\e[0m jump  \e[1;36m'\''[a-zA-Z]\e[0m beginning of line with mark
  capital letter marks are global and can be used to jump to different a file
\e[1;36m:marks\e[0m list marks
\e[1;36m/string\e[0m search for text (must escape .*[]^%%/\?~$ chars)
\e[1;36m/\<word\>\e[0m (\< and \> match beginning and end of a word)
  \e[1;36mn\e[0m next / \e[1;36mN\e[0m previous occurrence of string
\e[1;36m*\e[0m / \e[1;36m#\e[0m shortcut to search forward/backward for word under cursor


visual mode:  \e[1;34mv\e[0m character       \e[1;34mV\e[0m line            \e[1;34mCtrl-V\e[0m block

  \e[1;31mdd\e[0m  cut line        \e[1;31myy\e[0m  copy line
\e[1;33mp\e[0m  paste        \e[1;33mP\e[0m  paste before

delete: \e[1;31md\e[0m[\e[1;36mmotion\e[0m]\n'
