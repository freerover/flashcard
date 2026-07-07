.PHONY: build run app install dmg icon clean ios

XCODE = DEVELOPER_DIR=/Applications/Xcode15.app/Contents/Developer

build:
	$(MAKE) -C mac build

run:
	$(MAKE) -C mac run

app:
	$(MAKE) -C mac app

install:
	$(MAKE) -C mac install

run-app:
	$(MAKE) -C mac run-app

dmg:
	$(MAKE) -C mac dmg

icon:
	$(MAKE) -C mac icon

clean:
	$(MAKE) -C mac clean

ios:
	$(XCODE) swift build --package-path ios -c release
