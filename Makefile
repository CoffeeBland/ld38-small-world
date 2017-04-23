run: build
	love crustal.love

build:
	zip -9 -r crustal.love main.lua *.lua imgs snds fonts

build-win: build
	./support/ensure-win.sh
	mkdir -p crustal
	cat love-0.10.2-win32/love.exe crustal.love > crustal/crustal.exe
	cp love-0.10.2-win32/*.dll crustal/
	cp LICENSE crustal/license.txt
	zip crustal-win.zip crustal/*
	rm -r crustal

build-osx: build
	./support/ensure-osx.sh
	cp -r love.app crustal.app
	cp crustal.love crustal.app/Contents/Resources/
	cp support/Info.plist crustal.app/Contents/Info.plist
	zip -9 -r -y crustal-osx.zip crustal.app

build-all: build build-win build-osx
dist: build-all

clean:
	@rm -f love-0.10.2-win32.zip
	@rm -f crustal-win.zip
	@rm -f crustal-osx.zip
	@rm -rf love.app
	@rm -rf crustal.app
	@rm -rf love-0.10.2-win32
	@rm -rf crustal*
