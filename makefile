run: build
	love ld38-small-world.love

build:
	zip -9 -r ld38-small-world.love main.lua *.lua imgs snds

build-windows:
	./ensure-win.sh
	zip -9 -r ld38-small-world.love main.lua *.lua imgs snds
	mkdir -p ld38-small-world
	cat love-0.10.2-win32/love.exe ld38-small-world.love > ld38-small-world/crustal.exe
	cp love-0.10.2-win32/*.dll ld38-small-world/
	zip crustal.zip ld38-small-world/*

clean:
	@rm -f love-0.10.2-win32.zip
	@rm -f crustal.zip
	@rm -rf love-0.10.2-win32
	@rm -rf ld38-small-world*
