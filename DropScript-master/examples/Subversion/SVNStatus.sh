#!/bin/sh

##
# View status for items in a Subversion working copy
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
# ROLE        : Viewer
# SERVICEMENU : Subversion/View Status

##
# Functions
##

do_status ()
{
  local Target="$1";

  StatusFile=$(mktemp -t "SVN Status : $(basename "${Target}")");

  if svn status "${Target}" >> "${StatusFile}" 2>/dev/null && [ -s "${StatusFile}" ]; then
    open -e "${StatusFile}";
    (sleep 10 && rm -f "${StatusFile}";) &
  else
    echo "Can't get status: ${Target}";
    rm -f "${StatusFile}";
  fi;
}

##
# Handle arguments
##

Targets="$@";

##
# Do The Right Thing
##

for Target in ${Targets}; do
  do_status "${Target}";
done;
