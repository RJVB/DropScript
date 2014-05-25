##
# Makefile for DropScript examples
# Wilfredo Sanchez | wsanchez@wsanchez.net
##

# When invoked by XCode, these should be set
ifndef BUILT_PRODUCTS_DIR
BUILT_PRODUCTS_DIR := ../build
endif
ifndef INSTALL_PATH
INSTALL_PATH := /tmp/dst
endif

DROP_SCRIPT = $(BUILT_PRODUCTS_DIR)/DropScript.app/Contents/Resources/drop_script.py

DROPLETS_DIR = Drop Applications
EXAMPLES_DIR = Example Scripts

#SH_SCRIPTS := $(find . -name '*.sh')

#SCRIPTS = $(SH_SCRIPTS)

#DOCS = README

.PHONY: all build
all: $(SH_SCRIPTS)
	@echo "Installing example scripts and drop applications...";
	@rm -rf "$(BUILT_PRODUCTS_DIR)/$(EXAMPLES_DIR)" "$(BUILT_PRODUCTS_DIR)/$(DROPLETS_DIR)";
	@install -d -m 755 "$(BUILT_PRODUCTS_DIR)/$(EXAMPLES_DIR)" "$(BUILT_PRODUCTS_DIR)/$(DROPLETS_DIR)";
	@find . -type d \! -name . -prune \! -name .svn | {				\
	  while read dir; do								\
	    echo "Installing $$(basename "$${dir}") examples...";			\
	    example_dst="$(BUILT_PRODUCTS_DIR)/$(EXAMPLES_DIR)/$${dir}";		\
	    droplet_dst="$(BUILT_PRODUCTS_DIR)/$(DROPLETS_DIR)/$${dir}";		\
	    install -d -m 755 "$${example_dst}" "$${droplet_dst}";			\
	    find "$${dir}" \! \( -type d -name .svn -prune \) -type f -name '*.sh' | {	\
	      while read file; do							\
	        base="$$(basename "$${file}")";						\
	        echo "... $${base}";							\
	        install -c -m 555 "$${file}" "$${example_dst}/$${base}"; 		\
	        file_dst="$${droplet_dst}/$${base}";					\
	        cp "$${file}" "$${file_dst}";						\
	        $(DROP_SCRIPT) "$${file_dst}";						\
	        rm "$${file_dst}";							\
	      done;									\
	    }										\
	  done;										\
	}
build: all

.PHONY: clean
clean:
	rm -rf "$(BUILT_PRODUCTS_DIR)/$(EXAMPLES_DIR)";

.PHONY: install
install: all
	install -d "$(DSTROOT)$(INSTALL_PATH)/$(EXAMPLES_DIR)" "$(DSTROOT)$(INSTALL_PATH)/$(DROPLETS_DIR)";
	cd "$(BUILT_PRODUCTS_DIR)" && pax -rw "$(EXAMPLES_DIR)" "$(DSTROOT)$(INSTALL_PATH)";
	cd "$(BUILT_PRODUCTS_DIR)" && pax -rw "$(DROPLETS_DIR)" "$(DSTROOT)$(INSTALL_PATH)";
