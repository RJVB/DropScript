#!/bin/sh

##
# View diffs in a CVS working copy
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
# SERVICEMENU : CVS/Show Changes (diff)

##
# Functions
##

do_diff ()
{
  local Target="$1";

  DiffFile=$(mktemp -t "CVSDiff-$(basename "${Target}")");

  if cvs diff "${Target}" >> "${DiffFile}"; then
    open -e "${DiffFile}";
    (sleep 10 && rm -f "${DiffFile}";) &
  else
    echo "Diff failed.";
    rm -f "${DiffFile}";
  fi;
}

##
# Handle arguments
##

Targets="$@";

for Target in ${Targets}; do
  if [ ! -e "${Target}" ]; then
    echo "Invalid target: ${Target}";
    exit 1;
  fi;
done;

##
# Do The Right Thing
##

# Note that we process each target separately.
# This is a lot slower, since we invoke cvs separately for each
#  target, but it means that each target will have its own diff
#  file to view, which is somewhat nice.
# More importantly, it means that an error processing one target
#  (eg. a file not managed by CVS) won't cause the whole batch
#  to abort.  This may be common if a user selects a bunch of
#  files to process and expects The Right Ones to get processed.

for Target in ${Targets}; do
  do_diff "${Target}";
done;

exit 0;
