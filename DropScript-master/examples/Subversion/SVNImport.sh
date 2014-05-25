#!/bin/sh

##
# Import to a Subversion repository
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

# EXTENSIONS  : 
# OSTYPES     :	"fold"
# ROLE        : Editor
# SERVICEMENU : Subversion/Import to Repository

##
# Functions
##

do_import ()
{
  local Source="$1";

  "$(dirname "${Program}")/terminal" --activate --textsize 90x15 --title "Subversion Import" -e "
    sh -c '
      clear;

      echo \"Source directory: ${Source}\";

      while [ -z \"\${repository}\" ]; do
        echo -n \"Enter repository: \"; read repository;
      done;

      echo -n \"Enter path in repository []: \"; read entry;

      echo \"Importing ${Source}...\";
      svn import \"\${repository}\" \"${Source}\" \"\${entry}\";

      ' && exit;
        echo \"Import failed.\"; cd \"${Source}\";
    ";
}

##
# Handle arguments
##

Program="$0";
 Source="$1";

if [ ! -d "${Source}" ]; then
  echo "Invalid source: ${Source}";
  exit 1;
fi;

##
# Do The Right Thing
##

do_import "${Source}";
