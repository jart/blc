PREFIX = /usr/local

blc: blc.S
	$(CC) -nostdlib -Wl,-T,flat.lds $< -o $@

.PHONY: install
install: blc blc.1
	mkdir -p $(PREFIX)/bin
	install blc $(PREFIX)/bin/blc
	mkdir -p $(PREFIX)/share/man/man1
	install -m 0644 blc.1 $(PREFIX)/share/man/man1/blc.1
