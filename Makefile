.PHONY: build run app install dmg icon clean ios

XCODE = DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

build:
	$(MAKE) -C macos build

run:
	$(MAKE) -C macos run

app:
	$(MAKE) -C macos app

install:
	$(MAKE) -C macos install

run-app:
	$(MAKE) -C macos run-app

dmg:
	$(MAKE) -C macos dmg

icon:
	$(MAKE) -C macos icon

clean:
	$(MAKE) -C macos clean

ios:
	$(XCODE) swift build --package-path ios -c release
