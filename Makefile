all:
	rm -rf */Pods
	cd 'Debug Me' && pod install --no-update
	cd 'SuperDebug' && pod install --no-update
	# fix xcode idiosyncrasies, TODO: investigate
	for podproj in */Pods/Pods.xcodeproj/project.pbxproj; do awk '/GCC_PRECOMPILE/ {t=1;print;next} t && /string>YES/{ sub("YES", "NO"); print; t=0; next} {print}' "$$podproj" > "$$podproj.1"; mv "$$podproj.1" "$$podproj"; done


prepare:
	test -d ~/.cocoapods/proger || pod repo add proger https://github.com/proger/podspecs.git
