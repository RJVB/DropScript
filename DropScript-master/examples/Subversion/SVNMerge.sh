#!/bin/sh

##
# Merge changes between revisions in a Subversion repository into a working copy
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
# SERVICEMENU : Subversion/Merge Changes

##
# Functions
##

do_merge ()
{
  local Target="$1";

  TargetURL=$(svn info "${Target}" | grep '^Url: ' | sed 's/^Url: //');

  if [ -z "${TargetURL}" ]; then
    echo "${Target} does not appear to be a Subversion working copy.";
    exit 1;
  fi;

  "$(dirname "${Program}")/terminal" --activate --textsize 90x30 --title "Subversion Merge" -e "
    sh -c '
      clear;

      echo -n \"Enter left repository [${TargetURL}]: \"; read left_path;
      if [ -z \"\${left_path}\" ]; then left_path=\"${TargetURL}\"; fi;

      echo -n \"Enter left revision [HEAD]: \"; read left_revision;
      if [ -z \"\${left_revision}\" ]; then left_revision="HEAD"; fi;

      echo -n \"Enter right repository [\"\${left_path}\"]: \"; read right_path;
      if [ -z \"\${right_path}\" ]; then right_path=\"\${left_path}\"; fi;

      echo -n \"Enter right revision [HEAD]: \"; read right_revision;
      if [ -z \"\${right_revision}\" ]; then right_revision="HEAD"; fi;

      svn merge \"\${left_path}@\${left_revision}\" \"\${right_path}@\${right_revision}\" \"${Target}\";

      ' && exit;
        echo \"Merge failed.\"; cd \"$(dirname "${Target}")\";
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

do_merge "${Target}";
