.PHONY: web gen app run test test-web test-swift clean

web:
	cd web && npm run build

gen:
	xcodegen generate

app: web gen
	xcodebuild -project viewmd.xcodeproj -scheme viewmd \
	  -configuration Release -derivedDataPath .build build

run: app
	open .build/Build/Products/Release/viewmd.app

test-web:
	cd web && npm test

test-swift: web gen
	xcodebuild -project viewmd.xcodeproj -scheme viewmd \
	  -derivedDataPath .build test

test: test-web test-swift

clean:
	rm -rf .build web/dist viewmd.xcodeproj
