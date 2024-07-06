KEYDIR = keys
KEYS = $(wildcard $(KEYDIR)/*)
STAMP := $(shell date +%Y%m%d-%H:%M:%S)
AUTHKEYS = authorized_keys

all: update

cookies:
	@mkdir cookies

# just to make sure we always have the file
$(AUTHKEYS):
	@if [ ! -f $@ ]; then \
		touch $@; \
		chmod 600 $@; \
	fi

# keep a backup copy, with a date stamp.
archive: $(AUTHKEYS) cookies
	@if [ -s $< ]; then \
		cp -p $< $<.$(STAMP); \
		chmod 600 $<.$(STAMP); \
	fi

#specifying keydir here catches keys that get rm'd.
cookies/keyupdate: $(AUTHKEYS) cookies $(KEYDIR) $(KEYS)
	@echo Updating $<
	@(for k in $(KEYS); do \
		echo \# $$k; \
		cat $$k; \
		echo; \
	done) > $<.new
	@chmod 600 $<
	@mv $<.new $<
	@touch $@

showdiff: $(AUTHKEYS)
	@( if [ -f $< -a -f $<.$(STAMP) ]; then \
		cmp -s $< $<.$(STAMP); \
		if [ $$? -ne 0 ]; then \
			echo The following changes were made:; \
			diff -u $<.$(STAMP) $< | grep "[+-]#"; \
		fi; \
	fi)

#if the current archive copy is the same, get rid of it.
cleanup: $(AUTHKEYS) showdiff
	@(cmp -s $< $<.$(STAMP); \
		if [ $$? -eq 0 ]; then \
			rm $<.$(STAMP); \
		fi )

update: $(AUTHKEYS) archive cookies/keyupdate cleanup

.PHONY: clean

clean:
	rm -rf cookies $(AUTHKEYS)* archive keyupdate
