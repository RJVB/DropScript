#!/bin/sh

##
# Export a Subversion repository
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

do_export ()
{
  local Destination="$1";

  "$(dirname "${Program}")/terminal" --activate --textsize 90x15 --title "Subversion Export" -e "
    sh -c '
      clear;

      cd \"${Destination}\" || exit;

      echo \"Destination directory is: ${Destination}\";

      while [ -z \"\${repository}\" ]; do
        echo -n \"Enter repository: \"; read repository;
      done;

      echo -n \"Enter module name [\$(basename \"\${repository}\")]: \"; read module;
      if [ -z \"\${module}\" ]; then module=\$(basename \"\${repository}\"); fi;

      echo \"Exporting ${module}...\";
      svn export \"\${repository}\" \"\${module}\";

      ' && exit;
        echo \"Export failed.\"; cd \"${Destination}\";
    ";
}

##
# Handle arguments
##

    Program="$0";
Destination="$1";

if [ ! -d "${Destination}" ]; then
  echo "Invalid source: ${Destination}";
  exit 1;
fi;

##
# Do The Right Thing
##

do_export "${Destination}";
