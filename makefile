run: build
	love crustal.love

build:
	zip -9 -r crustal.love main.lua *.lua imgs snds *.ttf

build-windows:
	./ensure-win.sh
	zip -9 -r crustal.love main.lua *.lua imgs snds *.ttf
	mkdir -p crustal
	cat love-0.10.2-win32/love.exe crustal.love > crustal/crustal.exe
	cp love-0.10.2-win32/*.dll crustal/
	zip crustal.zip crustal/*

clean:
	@rm -f love-0.10.2-win32.zip
	@rm -f crustal.zip
	@rm -rf love-0.10.2-win32
	@rm -rf crustal*
