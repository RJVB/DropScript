#!/bin/sh

##
# Commit items to a CVS repository
#
# Wilfredo Sanchez | wsanchez@wsanchez.net
# Copyright (c) 2002 Wilfredo Sanchez Vega.
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software for
# any purpose with or without fee is hereby granted, provided that the
# above copyright notice and this permission notice appear in all
# copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHORS DISCLAIM ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHORS BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
# CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
# WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
##

# EXTENSIONS  : "*"
# OSTYPES     :	"****"
# ROLE        : Editor
# SERVICEMENU : CVS/Commit to Repository

##
# Functions
##

do_commit ()
{
  local Targets="$@";
  local   First="$1";

  if [ -z "${Targets}" ]; then return; fi;

  # Logic below is complicated by CVS's lame inability to deal with full paths to working
  #  copy files. We need to record the log ourselves, then commit files individually.

  Message=$(mktemp -t cvs.log);

  "$(dirname "${Program}")/terminal" --activate --textsize 90x30 --title "CVS Commit" -e "
    sh -c '
      clear;

      \"\${CVSEDITOR:=\${EDITOR:=vi}}\" \"${Message}\";

      if [ ! -s \"${Message}\" ]; then
        echo \"Empty log message.  Aborting.\";
        exit 1;
      fi;

      for Target in ${Targets}; do
        cd \$(dirname \"\${Target}\") && cvs commit -F \"${Message}\" \$(basename \"\${Target}\");
      done;

      ' && exit;
        echo \"Commit failed.\"; cd \"$(dirname "${First}")\";
    ";
}

##
# Handle arguments
##

Program="$0";
Targets="$@";

##
# Do The Right Thing
##

do_commit ${Targets};
