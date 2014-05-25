#!/bin/sh

##
# Switch between repositories in a Subversion in a working copy
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
# SERVICEMENU : Subversion/Switch Repositories

##
# Functions
##

do_switch ()
{
  local Target="$1";

  if ! svn status "${Target}" > /dev/null; then
    echo "${Target} does not appear to be a Subversion working copy.";
    exit 1;
  fi;

  "$(dirname "${Program}")/terminal" --activate --textsize 90x30 --title "Subversion Merge" -e "
    sh -c '
      clear;

      while [ -z \"\${repository}\" ]; do
        echo -n \"Enter new repository: \"; read repository;
      done;

      svn switch \"\${repository}\" \"${Target}\";

      ' && exit;
        echo \"Switch failed.\"; cd \"$(dirname "${Target}")\";
    ";
}

##
# Handle arguments
##

Program="$0";
 Target="$1"; shift;

if [ $# != 0 ]; then echo "Too many arguments."; exit 1; fi;

##
# Do The Right Thing
##

do_switch "${Target}";
