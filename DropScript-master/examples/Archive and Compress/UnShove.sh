#!/bin/sh
##
# UnShove.sh - part of the ShoveIt Deluxe (tm) Suite.
# Uncompress and unpack file archives of various formats
#
# Wilfredo Sanchez | wsanchez@wsanchez.net
# Copyright (c) 2001-2002 Wilfredo Sanchez Vega.
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

# EXTENSIONS  : "tgz" "tar" "gz" "Z" "zip"	# Accepted file extentions
# OSTYPES     :					# Accepted file types
# ROLE        : Editor				# Role (Editor, Viewer, None)
# SERVICEMENU : ShoveIt/Unpack Archive		# Name of Service menu item

for file; do
  location=$(dirname "$file")
  case $file in
    *.tgz | *.tar.gz)
      tar -C "${location}" -x -z -f "${file}"
      ;;
    *.tar)
      tar -C "${location}" -x -f "${file}"
      ;;
    *.gz)
      cd "${location}" && gunzip "${file}"
      ;;
    *.Z)
      cd "${location}" && uncompress "${file}"
      ;;
    *.zip)
      cd "${location}" && unzip "${file}"
      ;;
    *)
      echo "Unknown file extension: ${file}"
      ;;
  esac
done
