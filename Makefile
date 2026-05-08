.PHONY: test

NVIM ?= nvim

test:
	$(NVIM) --headless -u tests/minimal_init.lua \
		-c "PlenaryBustedDir tests/spec/ {minimal_init = 'tests/minimal_init.lua'}"
