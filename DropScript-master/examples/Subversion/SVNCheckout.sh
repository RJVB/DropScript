#!/bin/sh

##
# Check out a Subversion repository
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
# SERVICEMENU : Subversion/Check Out Repository

##
# Functions
##

do_checkout ()
{
  local Destination="$1";

  "$(dirname "${Program}")/terminal" --activate --textsize 90x15 --title "Subversion Checkout" -e "
    sh -c '
      clear;

      cd \"${Destination}\" || exit;

      echo \"Destination directory is: ${Destination}\";

      while [ -z \"\${repository}\" ]; do
        echo -n \"Enter repository: \"; read repository;
      done;

      echo -n \"Enter module name [\$(basename \"\${repository}\")]: \"; read module;
      if [ -z \"\${module}\" ]; then module=\$(basename \"\${repository}\"); fi;

      echo \"Checking out \$module...\";
      svn checkout \"\${repository}\" \"\$module\";

      ' && exit;
        echo \"Checkout failed.\"; cd \"${Destination}\";
    ";
}

##
# Handle arguments
##

# Let's make an assumption (hopefully) in favor of useability:
#  If the user has selected a file, assume the user wants to check out
#    in the directory containing the file.  Iffy? Possibly.
#  Furthermore, if multiple items are selected, assume the first one
#    is at least as interesting as any and ignore the rest.
#  We can fix this when we have a decent way to tell the user why.

    Program="$0";
Destination="$1";

if [ -f "${Destination}" ]; then
  Destination=$(dirname "${Destination}");
fi;

if [ ! -d "${Destination}" ]; then
  echo "Invalid destination: ${Destination}";
  exit 1;
fi;

##
# Do The Right Thing
##

do_checkout "${Destination}";
