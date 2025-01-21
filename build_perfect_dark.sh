#!/usr/bin/env zsh

# ANSI colour codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Colour

# This just gets the location of the folder where the script is run from. 
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

ARCH="$(uname -m)"
CORES=$(sysctl -n hw.ncpu)

introduction() {
	echo "${PURPLE}This script will build a native macOS version of Perfect Dark${NC}"
	echo "${PURPLE}Run the script from the same folder as your Perfect Dark N64 rom${NC}"
}

main_menu() {
	PS3='Which version would you like to build? '
	OPTIONS=(
		"US (v.1.1)"
		"EU"
		"JP"
		"Quit")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"US (v.1.1)")
				GAME_ID="pd.$ARCH"
				ROM_ID="pd.ntsc-final.z64"
				GAME_TITLE="Perfect Dark (US)"
				set_vars
				homebrew_check
				check_all_dependencies
				build ntsc
				bundle
				break
				;;
			"EU")
				GAME_ID="pd.pal.$ARCH"
				ROM_ID="pd.pal-final.z64"
				GAME_TITLE="Perfect Dark (EU)"
				set_vars
				homebrew_check
				check_all_dependencies
				build pal
				bundle
				break
				;;
			"JP")
				GAME_ID="pd.jpn.$ARCH"
				ROM_ID="pd.jpn-final.z64"
				GAME_TITLE="Perfect Dark (JP)"
				set_vars
				homebrew_check
				check_all_dependencies
				build jpn
				bundle
				break
				;;
			"Quit")
				echo -e "${RED}Quitting${NC}"
				exit 0
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

# Functions for checking for Homebrew installation
homebrew_check() {
	echo "${PURPLE}Checking for Homebrew...${NC}"
	if ! command -v brew &> /dev/null; then
		echo "${PURPLE}Homebrew not found. Installing Homebrew...${NC}"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		if [[ "${ARCH}" == "arm64" ]]; then 
			(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.zprofile
			eval "$(/opt/homebrew/bin/brew shellenv)"
		else 
			(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> $HOME/.zprofile
			eval "$(/usr/local/bin/brew shellenv)"
		fi
		
		# Check for errors
		if [ $? -ne 0 ]; then
			echo "${RED}There was an issue installing Homebrew${NC}"
			echo "${PURPLE}Quitting script...${NC}"	
			exit 1
		fi
	else
		echo "${PURPLE}Homebrew found. Updating Homebrew...${NC}"
		brew update
	fi
}

# Function for checking for an individual dependency
single_dependency_check() {
	if [ -d "$(brew --prefix)/opt/$1" ]; then
		echo "${GREEN}Found $1. Checking for updates...${NC}"
		brew upgrade $1
	else
		 echo "${PURPLE}Did not find $1. Installing...${NC}"
		brew install $1
	fi
}

# Install required dependencies
check_all_dependencies() {
	echo "${PURPLE}Checking for Homebrew dependencies...${NC}"
	# Required Homebrew packages
	deps=( cmake sdl2 )
	
	for dep in $deps[@]
	do 
		single_dependency_check $dep
	done
}

set_vars() {
	echo "${PURPLE}Setting variables...${NC}"
	PKGINFO_TITLE="PFDK"
	
	ICON_URL="https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/b2b70e5bbb4a1130e42deb5b0128ebde_low_res_Perfect_Dark.png"
	APP_SUPPORT=~/Library/Application\ Support/perfectdark
}

build() {
	git clone --recursive https://github.com/fgsfdsfgs/perfect_dark.git
	cd perfect_dark
	
	cmake -G"Unix Makefiles" -Bbuild -DCMAKE_MACOSX_RPATH=ON -DCMAKE_OSX_ARCHITECTURES=$ARCH -DROMID=$1-final .
	cmake --build build --target pd -j$CORES --clean-first
	
	cd ..
	mv perfect_dark/build/$GAME_ID .
	rm -rf perfect_dark
}

# Create the app bundle
bundle() {
	echo "${PURPLE}Creating app bundle...${NC}"
	rm -rf "${GAME_TITLE}.app"
	mkdir -p "${GAME_TITLE}.app/Contents/Frameworks"
	mkdir -p "${GAME_TITLE}.app/Contents/MacOS"
	
	# create Info.plist
	PLIST="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
	<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
	<plist version=\"1.0\">
	<dict>
		<key>CFBundleDevelopmentRegion</key>
		<string>English</string>
		<key>CFBundleGetInfoString</key>
		<string>${GAME_TITLE}</string>
		<key>CFBundleExecutable</key>
		<string>${GAME_ID}</string>
		<key>CFBundleIconFile</key>
		<string>${GAME_ID}.icns</string>
		<key>CFBundleIdentifier</key>
		<string>com.github.fgsfdsfgs.${GAME_ID}</string>
		<key>CFBundleInfoDictionaryVersion</key>
		<string>6.0</string>
		<key>CFBundleName</key>
		<string>${GAME_TITLE}</string>
		<key>CFBundlePackageType</key>
		<string>APPL</string>
		<key>CFBundleSupportedPlatforms</key>
		<array>
			<string>MacOSX</string>
		</array>
		<key>CFBundleShortVersionString</key>
		<string>1.0</string>
		<key>CFBundleVersion</key>
		<string>1.0</string>
		<key>LSMinimumSystemVersion</key>
		<string>11.0</string>
		<key>NSPrincipalClass</key>
		<string>NSApplication</string>
		<key>NSHumanReadableCopyright</key>
		<string>Perfect Dark Contributors</string>
		<key>NSHighResolutionCapable</key>
		<true/>
		<key>LSApplicationCategoryType</key>
		<string>public.app-category.games</string>
		<key>LSArchitecturePriority</key>
		<array>
			<string>arm64</string>
		</array>
	</dict>
	</plist>
	"
	echo "${PLIST}" > "${GAME_TITLE}.app/Contents/Info.plist"
	
	# Create PkgInfo
	PKGINFO="-n APPL${PKGINFO_TITLE}"
	echo "${PKGINFO}" > "${GAME_TITLE}.app/Contents/PkgInfo"
	
	mv ${GAME_ID} "${GAME_TITLE}.app/Contents/MacOS"
	ditto /opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib "${GAME_TITLE}.app/Contents/Frameworks"
	install_name_tool -change /opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib @executable_path/../Frameworks/libSDL2-2.0.0.dylib "${GAME_TITLE}.app/Contents/MacOS/${GAME_ID}"
	
	
	# Copy game data
	if [ ! -d $APP_SUPPORT/data ]; then 
		mkdir -p $APP_SUPPORT/data/
	fi
	cp $ROM_ID "$APP_SUPPORT/data/"
}

introduction
main_menu