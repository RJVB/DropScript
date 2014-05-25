#!/bin/sh

##
# View changes in a Subversion working copy
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
# SERVICEMENU : Subversion/View Changes (FileMerge)

####
## Outstanding questions:
## - How do we get to the base text correctly?
##   (Rather than referencing .svn/text-base/ here.)
## - How do we deal with moved files?
## - How do we deal with property changes?
####

##
# Functions
##

svn_base ()
{
  for File; do
    echo "$(dirname "${File}")/.svn/text-base/$(basename "${File}").svn-base";
  done;
}

do_diff ()
{
  local Target="$1";
  local  Files="";

  # Note that we process each file separately.  That is, if the target is
  #  a directory, we open each changed file individually.
  # This is required because we would otherwise have to re-create each
  #  directory's structure and copy the base text of each file into the
  #  clone, even for unchanged files. (Though we could use hard links if
  #  the clone is on the same filesystem, but that's hard to guarantee.)
  #  And we can't clean up the clone when we're done, because we don't
  #  know when FileMerge will be done using it.

  # FIXME: In sh, failure of the first program in a pipe doesn't give
  # you it's bad error status.  The error case here never happens.
  if ! Files=$(svn status "${Target}" 2>/dev/null | grep '^M' | sed 's/.......//'); then
    echo "Can't view changes for file: ${Target}";
    return 1;
  fi;

  for File in ${Files}; do
    if [ -f "${File}" ]; then
      opendiff $(svn_base "${File}") "${File}"
    fi;
  done;
}

##
# Handle arguments
##

Targets="$@";

##
# Do The Right Thing
##

for Target in ${Targets}; do
  do_diff "${Target}";
done;

exit 0;
