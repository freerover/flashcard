.PHONY: build run app install dmg icon clean

APP_NAME = Flashcard
DMG_NAME = Flashcard-Installer
XCODE = DEVELOPER_DIR=/Applications/Xcode15.app/Contents/Developer

build:
	$(XCODE) swift build -c release

run:
	$(XCODE) swift run

icon:
	$(XCODE) swift Resources/gen-icon.swift Resources/$(APP_NAME).icns

app: icon build
	rm -rf $(APP_NAME).app
	mkdir -p $(APP_NAME).app/Contents/MacOS
	mkdir -p $(APP_NAME).app/Contents/Resources
	cp .build/release/$(APP_NAME) $(APP_NAME).app/Contents/MacOS/
	cp Resources/Info.plist $(APP_NAME).app/Contents/
	cp Resources/Flashcard.icns $(APP_NAME).app/Contents/Resources/
	cp Resources/config.json $(APP_NAME).app/Contents/Resources/
	cp -r Resources/libs $(APP_NAME).app/Contents/Resources/libs
	@echo "✅ $(APP_NAME).app 创建成功"

install: app
	cp -r $(APP_NAME).app /Applications/
	@echo "✅ 已安装到 /Applications/$(APP_NAME).app"

run-app: app
	open $(APP_NAME).app

dmg: app
	rm -rf /tmp/$(DMG_NAME) /tmp/$(DMG_NAME).dmg
	$(XCODE) swift Resources/gen-dmg-bg.swift /tmp/安装说明.png 2>/dev/null; true
	mkdir -p /tmp/$(DMG_NAME)
	cp -r $(APP_NAME).app /tmp/$(DMG_NAME)/
	cp /tmp/安装说明.png /tmp/$(DMG_NAME)/
	ln -s /Applications /tmp/$(DMG_NAME)/
	rm -f /tmp/安装说明.png
	hdiutil create -volname "$(APP_NAME)" -srcfolder /tmp/$(DMG_NAME) -ov -format UDZO $(DMG_NAME).dmg
	rm -rf /tmp/$(DMG_NAME)
	@echo "✅ $(DMG_NAME).dmg 创建成功"

clean:
	rm -rf .build $(APP_NAME).app $(DMG_NAME).dmg Resources/$(APP_NAME).icns
	@echo "✅ 已清理"
