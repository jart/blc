blc: blc.S
	$(CC) -nostdlib -Wl,-T,flat.lds $< -o $@
