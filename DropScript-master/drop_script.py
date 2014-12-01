#!/usr/bin/python
# -*- coding: UTF-8 -*-

##
# drop_script
# DropScript droplet generation script
#
# Created by Wilfredo Sánchez on Sun May 02 2004.
# Copyright (c) 2004 Wilfredo Sánchez Vega. All rights reserved.
##

# FIXME: Bob suggests I use plistlib

import sys
import os
import re
import shutil

debug = False

##
# Handle command line
##

source_script = sys.argv[0]

import Tkinter, tkMessageBox

if len(sys.argv) < 2 or len(sys.argv) > 4:
    try:
        import Tkinter, tkMessageBox
        top = Tkinter.Tk()
        B1 = Tkinter.Button(top, text="OK", command=dir)
        B1.pack()
        tkMessageBox.showinfo( (os.path.basename(source_script)), "error: DropScript should be invoked by dropping a shell script onto us" )
    except:
        print "%s takes one or two arguments" % (os.path.basename(source_script))
    sys.exit(1)

new_script  = sys.argv[1]

source_app         = os.path.dirname(os.path.dirname(os.path.dirname(source_script)))
source_name        = os.path.splitext(os.path.basename(source_app))[0]
if (len(sys.argv) >= 3) and (len(sys.argv[2]) > 0):
    destination    = sys.argv[2]
else:
    destination    = os.path.dirname(new_script)
if len(sys.argv) >= 4:
    iconName       = sys.argv[3]
else:
    iconName       = "DropScript.icns"
base_name          = os.path.basename(os.path.splitext(new_script)[0])
# droplet_name       = "Drop" + base_name
droplet_name       = base_name
droplet_path       = os.path.join(destination, droplet_name + ".app")
droplet_contents   = os.path.join(droplet_path, "Contents")
droplet_bindir     = os.path.join(droplet_contents, "MacOS")
droplet_executable = os.path.join(droplet_bindir, droplet_name)
droplet_resources  = os.path.join(droplet_contents, "Resources")
#droplet_script     = os.path.join(droplet_resources, "drop_script")
droplet_script     = os.path.join(droplet_resources, base_name)
droplet_plist      = os.path.join(droplet_contents, "Info.plist")

i = 0
if (os.path.exists(droplet_path)):
    # RJVB: rather than creating a new droplet with a number in its name,
    # move the current droplet to a numbered "previous copy".
    prev_path = os.path.join(destination, base_name + "-prev.app")
    while (os.path.exists(prev_path)):
        i += 1
        prev_name = base_name + "-prev-" + str(i)
        prev_path = os.path.join(destination, prev_name + ".app")
    shutil.move(droplet_path, prev_path)

##
# Functions
##

def parse_script_options(script_filename):
    """
    Read the specified script and pull out DropScript options.
    Options are specified on a line that begins with '# ' as the first two
    characters, followed by the option name, followed by ':', followed by
    the option value.
    Note that this assumes that one can do this without breaking the syntax
    of the script.  Since most scripting languages use '#' as to denote a
    comment, this generally seems like a reasonable choice.
    See the DropScript docs for information about avaliable options.
    """
    options = {}

    regex_option = re.compile(r'^#[ \t]*([A-Z]+)[ \t]*:[ \t]*(.*)$')

    script_file = open(script_filename)

    regex_comment = r'([ \t]*#.*)?$'

    for line in script_file:
        match = regex_option.search(line)
        if match:
            option = match.group(1)
            value  = match.group(2)

            warning = "%s: WARNING: Invalid %s: %r" % (source_script, option, value)

            if option == "EXTENSIONS" or option == "OSTYPES":
                regex_extensions = re.compile(r'^("[^"]*")+' + regex_comment)
                if regex_extensions.search(value):
                    extensions = regex_extensions.sub(r'\1', value)
                    options[option] = extensions
                elif re.search(regex_comment, value): pass
                else: print warning

            elif option == "ROLE":
                match = re.search(r'^([A-Za-z]+)' + regex_comment, value)
                if match: options[option] = match.group(1)
                else: print warning

            elif option == "SERVICEMENU":
                match = re.search(r'^(.+?)' + regex_comment, value)
                if match: options[option] = match.group(1)
                else: print warning

    script_file.close()

    if not ("ROLE" in options and options["ROLE"]):
        options["ROLE"] = "Editor"

    if not ("SERVICEMENU" in options and options["SERVICEMENU"]):
        options["SERVICEMENU"] = "DropScript/" + base_name

    if (not ("EXTENSIONS" in options and options["EXTENSIONS"]) and
        not ("OSTYPES"    in options and options["OSTYPES"   ]) ):
        options["EXTENSIONS"] = '"*"'
        options["OSTYPES"   ] = '"****"'
    else:
        if not "EXTENSIONS" in options: options["EXTENSIONS"] = ""
        if not "OSTYPES"    in options: options["OSTYPES"   ] = ""

    return options

def write_plist(plist_filename, options):
    """
    Write an Info.plist file with the given options.
    """
    def expand_tokens(tokens):
        """
        Replace: "x" "y" ...
        With: <string>x</string> <string>y</string> ...
        """
        result = ""
        state = False
        for c in tokens:
            if c == '"':
                if state: result = result + "</string>"
                else:     result = result + "<string>"
                state = not state
            else:
                result = result + c
        if state: raise RuntimeError("mismatched quotes in token list")
        return result

    plist_file = open(plist_filename, "w")
    plist_file.write("""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>WrapperClosesStdIO</key>
    <false/>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleDocumentTypes</key>
    <array>
      <dict>
        <key>CFBundleTypeExtensions</key>
        <array>
          """ + expand_tokens(options["EXTENSIONS"]) + """
        </array>
        <key>CFBundleTypeName</key>
        <string>NSStringPboardType</string>
        <key>CFBundleTypeOSTypes</key>
        <array>
          """ + expand_tokens(options["OSTYPES"]) + """
        </array>
        <key>CFBundleTypeRole</key>
        <string>""" + options["ROLE"] + """</string>
      </dict>
    </array>
    <key>CFBundleExecutable</key>
    <string>""" + droplet_name + """</string>
    <key>CFBundleIconFile</key>
    <string>""" + iconName + """</string>
    <key>CFBundleName</key>
    <string>""" + droplet_name + """</string>
    <key>CFBundleIdentifier</key>
    <string>net.wsanchez.DropScript.""" + droplet_name + """</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>DScr</string>
    <key>CFBundleVersion</key>
    <string>0.0</string>
    <key>NSMainNibFile</key>
    <string>MainMenu</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSServices</key>
    <array>
      <dict>
        <key>NSMenuItem</key>
        <dict>
          <key>default</key>
          <string>""" + options["SERVICEMENU"] + """</string>
        </dict>
        <key>NSMessage</key>
        <string>dropService</string>
        <key>NSPortName</key>
        <string>DropScript</string>
        <key>NSSendTypes</key>
        <array>
          <string>NSFilenamesPboardType</string>
        </array>
      </dict>
    </array>
  </dict>
</plist>
""")
    plist_file.close()

##
# Do The Right Thing
##

try:
    if debug: print "source_name:    %s" % source_name
    if debug: print "source_app:     %s" % source_app
    if debug: print "source_script:      %s" % source_script
    if debug: print "new_script:     %s" % new_script
    if debug: print "destination:    %s" % destination
    if debug: print "droplet_name:       %s" % droplet_name
    if debug: print "droplet_path:       %s" % droplet_path
    if debug: print "droplet_script:     %s" % droplet_script
    if debug: print "droplet_plist:      %s" % droplet_plist
    if debug: print "droplet_executable: %s" % droplet_executable

    # Get application options from script
    options = parse_script_options(new_script)

    if debug: print "options: %s" % options

    # Copy the primordial applet to the new applet's location
    shutil.copytree(source_app, droplet_path)

    # Move Contents/MacOS/DropScript to Contents/MacOS/<droplet_name>
    if debug: print "Moving %s to %s..." % (os.path.join(droplet_bindir, source_name), droplet_executable)
    os.rename(os.path.join(droplet_bindir, source_name), droplet_executable)

    # Replace Contents/Resources/drop_script
    if debug: print "Removing %s and %s..." % (droplet_script, droplet_script+".py")
    try:
        # this one shouldn't really be there ...
        os.remove(droplet_script)
    except:
        pass
    try:
        os.remove(droplet_script+".py")
    except:
        pass
    try:
        os.remove(os.path.join(droplet_resources, "drop_script.py"))
    except:
        pass
    if debug: print "Copying %s to %s..." % (new_script, droplet_script)
    shutil.copyfile(new_script, droplet_script)
    os.chmod(droplet_script, 0755)

    # Edit Info.plist
    if debug: print "Editing plist %s..." % droplet_plist
    write_plist(droplet_plist, options)

    if debug: print "Created new drop application %s." % droplet_path

except Exception, e:
    raise

    # Delete new droplet on error
    pass

    # Show error panel on error
    pass
    exit(1);
