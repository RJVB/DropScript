#!/bin/sh
##
# Shove.sh - part of the ShoveIt Deluxe (tm) Suite.
# Package a set of files into a POSIX tar archive and compress the result
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

# EXTENSIONS  : "*"				# Accepted file extentions
# OSTYPES     : "****"				# Accepted file types
# ROLE        : Editor				# Role (Editor, Viewer, None)
# SERVICEMENU : ShoveIt/Make Archive		# Name of Service menu item

tarfile=$(mktemp -t "ShoveIt");

for file; do
    member=$(basename "$file")
  location=$( dirname "$file")
  if [ -f "${tarfile}" ] && [ -s "${tarfile}" ]; then flag="r"; else flag="c"; fi
  tar -C "${location}" -"${flag}" -f "${tarfile}" "${member}"
done

gzip -9 "${tarfile}"

mv "${tarfile}.gz" "$1.tar.gz"
