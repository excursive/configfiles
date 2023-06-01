#!/bin/bash

printf '\e[35mmagenta: buffers/files/windows/tabs
\e[32mgreen: actions\e[0m
\e[36mcyan: movement
\e[34mblue: visual mode
\e[33myellow: insert
\e[31mred: delete/copy/paste\e[0m
can put numbers in front of nearly any command, e.g. \e[1;36m5h\e[0m to move 5 chars left

vim \e[1;35m-R\e[0;35m [files...]\e[0m open files in read-only mode
\e[1;35m:e[dit]\e[0;35m[!] [file]\e[0m open file (! discards changes to current file)
\e[1;35m:sav[eas]\e[0m save as         \e[1;35mCtrl-^\e[0m swap to last edited file
 \e[1;35m:n[ext]\e[0m /  \e[1;35m:prev[ious]\e[0m / \e[1;35m:fir[st]\e[0m  / \e[1;35m:la[st]\e[0m  switch files in \e[1margs\e[0m list
\e[1;35m:bn[ext]\e[0m / \e[1;35m:bp[revious]\e[0m / \e[1;35m:bf[irst]\e[0m / \e[1;35m:bl[ast]\e[0m switch buffer in \e[1mbuffer\e[0m list
 \e[1;35m:n[ext]\e[0m /  \e[1;35m:prev[ious]\e[0m [save current and] go to next/prev file in \e[1margs\e[0m list
\e[1;35m:args\e[0;35m [file1.txt] [file2.txt] [*.txt]\e[0m open new list of files
\e[1;35m:buffers\e[0;35m[!]\e[0m / \e[1;35m:files\e[0;35m[!]\e[0m / \e[1;35m:ls\e[0;35m[!]\e[0m list all [include unlisted] files in buffer list

\e[0;35m:[N]\e[1;35m[v]sp[lit]\e[0m \e[35m[file.txt]\e[0m / \e[0;35m:[N]\e[1;35m[v]new\e[0m split window [N lines high/wide]
\e[1;35mCtrl-W h\e[0m/\e[1;35mj\e[0m/\e[1;35mk\e[0m/\e[1;35ml\e[0m switch windows    \e[1;35mCtrl-W H\e[0m/\e[1;35mJ\e[0m/\e[1;35mK\e[0m/\e[1;35mL\e[0m move window to far left/bottom/...
\e[1;35mCtrl-W [+/-/_]\e[0m increase/decrease/set size of window
\e[1;35m:clo[se]\e[0m / \e[1;35mCtrl-W c\e[0m close window    \e[1;35m:on[ly]\e[0m / \e[1;35mCtrl-W o\e[0m close all other windows
\e[1;35m:\e[0;35m[w]\e[1;35mqa[ll]\e[0;35m[!]\e[0m close all windows and quit

vim \e[1;35m-p[N]\e[0m [files...] open up to N tab pages, one for each file
\e[1;35m:tabe[dit]\e[0;35m [file]\e[0m / \e[1;35m:tabnew\e[0m edit file/create new file in a new tab page
\e[1;35mgt\e[0m / \e[1;35mgT\e[0m go to next/previous tab        \e[1;35m:tabs\e[0m list tabs


  \e[1;32mu\e[0m  undo        \e[1;32mCtrl-R\e[0m  redo
  \e[1;32m.\e[0m  repeat last command

go to line:   \e[1;36mgg\e[0m line 1         \e[1;36m:n\e[0m / \e[1;36mnG\e[0m line n    \e[1;36mG\e[0m last line
\e[1;36mCtrl-U\e[0m up half screen of text   \e[1;36mCtrl-D\e[0m down half screen of text
\e[1;36mzz\e[0m center cursor line  \e[1;36mzt\e[0m cursor line at top  \e[1;36mzb\e[0m cursor line at bottom
\e[1;36m{\e[0m / \e[1;36m}\e[0m code block
\e[1;36m0\e[0m        \e[1;36m^\e[0mmove to first/first non-blank/last char in line\e[1;36m$\e[0m
\e[1;36mgm\e[0m/\e[1;36mgM\e[0m to middle of line / screen line
\e[1;36mf\e[0m/\e[1;36mF{char}\e[0m to [N]th occurrence of {char} to the right/left
\e[1;36mt\e[0m/\e[1;36mT{char}\e[0m till before/after the [N]th occurrence of {char} to the right/left
\e[1;36m``\e[0m previous cursor position    \e[1;36m`.\e[0m position of last change
\e[1;36m`"\e[0m cursor position when last editing file
\e[1;36mm[a-zA-Z]\e[0m place mark  \e[1;36m`[a-zA-Z]\e[0m jump  \e[1;36m'\''[a-zA-Z]\e[0m beginning of line with mark
  capital letter marks are global and can be used to jump to different a file
\e[1;36m:marks\e[0m list marks

\e[1;36m/string\e[0m search (must escape \^.*[]%%~/?$ chars)     \e[1;36mn\e[0m next / \e[1;36mN\e[0m previous match
  \e[1;36m^\e[0mline\e[1;36m$\e[0m    \e[1;36m\<\e[0mword\e[1;36m\>\e[0m    \e[1;36m(\e[0mgroup as atom\e[1;36m)\e[0m    any#\e[1;36m*\e[0m    0or1\e[1;36m\?\e[0m    NtoM\e[1;36m\{n,m}\e[0m
  \e[1;36m\zs\e[0mset start/end of match\e[1;36m\ze\e[0m
  \e[1;36m.\e[0m char(no EOL)  \e[1;36m\_.\e[0m char    \e[1;36m\s\e[0m whitespace    \e[1;36m\S\e[0m non-ws    \e[1;36m\d\e[0m digit    \e[1;36m[\e[0mchar set\e[1;36m]\e[0m
\e[1;36m*\e[0m / \e[1;36m#\e[0m shortcut to search forward/backward for word under cursor


visual mode:  \e[1;34mv\e[0m character       \e[1;34mV\e[0m line            \e[1;34mCtrl-V\e[0m block

  \e[1;31mdd\e[0m  cut line        \e[1;31myy\e[0m  copy line
\e[1;33mp\e[0m  paste        \e[1;33mP\e[0m  paste before

delete: \e[1;31md\e[0m[\e[1;36mmotion\e[0m]\n'
