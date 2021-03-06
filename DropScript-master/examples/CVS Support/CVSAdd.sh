#!/bin/sh

##
# Add items to a CVS working copy
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
# SERVICEMENU : CVS/Add to Working Copy

##
# Functions
##

do_add ()
{
  local Targets="$@";

  if [ -z "${Targets}" ]; then return; fi;

  # CVS is rather dumb; it expects your working directory to be
  #  in the working copy. So we have to add each file singly to
  #  prevent errors. Even assuming that all targets are in the
  #  same working copy, CVS _still_ barfs if you pass in a full
  #  path to a file. Eit.
  for target in ${Targets}; do
    cd $(dirname "${target}") && cvs add $(basename "${target}");
  done;
}

##
# Handle arguments
##

Targets="$@";

##
# Do The Right Thing
##

do_add ${Targets};
