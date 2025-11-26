#!/usr/bin/env zsh

# ANSI colour codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Colour

# This just gets the location of the folder where the script is run from. 
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

set_vars() {
	ARCH="$(uname -m)"
	CORES=$(sysctl -n hw.ncpu)
	SHASUM_US1="af8788ac4d1a57260eae9c53ffe851fcf2a3319b"
	SHASUM_US="60dfe17923c03875b499b3cd3200f05cb538b7ad"
	SHASUM_EU="a663d3f4eee0b198471132db92e9639a9edd1985"
	SHASUM_JP="99bcaaa4841b09c845e1094006df8f637862f02e"
	PKGINFO_TITLE="PFDK"
	ICON_URL="https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/03c5fd504059ea1b5e40ccd9bac778ac_Perfect_Dark.icns"
	APP_SUPPORT=~/Library/Application\ Support/perfectdark
}

introduction() {
	echo "\n${PURPLE}This script will build a native macOS version of Perfect Dark${NC}\n"
	echo "${PURPLE}Run the script from the same folder as your Perfect Dark N64 rom${NC}"
	echo "${PURPLE}Rename your rom to one of the following based on the region: ${NC}"
	echo "${PURPLE}US: ${GREEN}pd.ntsc-final.z64${NC}"
	echo "${PURPLE}EU: ${GREEN}pd.pal-final.z64${NC}"
	echo "${PURPLE}Japan: ${GREEN}pd.jpn-final.z64${NC}\n"
}

main_menu() {
	set_vars
	introduction
	homebrew_check
	check_rom
	PS3='Would you like to continue building? '
	OPTIONS=(
		"Build"
		"Quit")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Build")
				build
				bundle
				break
				;;
			"Quit")
				echo "${RED}Quitting${NC}"
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
		echo "${PURPLE}Homebrew has not been detected${NC}"
		homebrew_install_menu
	else
		echo "${PURPLE}Homebrew has been detected${NC}"
		homebrew_update_menu
	fi
}

homebrew_install_menu() {
	echo "${GREEN}Homebrew${PURPLE} and the ${GREEN}Xcode command-line tools${PURPLE} are required${NC}\n"
	PS3='Would you like to install Homebrew? '
	OPTIONS=(
		"Yes"
		"No")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Yes")
				install_homebrew
				break
				;;
			"No")
				echo "${PURPLE}The script cannot run without Homebrew${NC}"
				echo "${RED}Quitting${NC}"
				exit 0
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

homebrew_update_menu() {
	PS3='Would you like to install or update the required dependencies? '
	OPTIONS=(
		"Continue"
		"Install / Update")
	select opt in $OPTIONS[@]
	do
		case $opt in
			"Continue")
				echo "\n${RED}Skipping Homebrew checks${NC}"
				echo "${PURPLE}The script will fail if any of the dependencies are missing${NC}\n"
				break
				;;
			"Install / Update")
				update_homebrew
				check_all_dependencies
				break
				;;
			*) 
				echo "\"$REPLY\" is not one of the options..."
				echo "Enter the number of the option and press enter to select"
				;;
		esac
	done
}

install_homebrew() {
	echo "${PURPLE}Installing Homebrew...${NC}"
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
}

update_homebrew() {
	echo "${PURPLE}Updating Homebrew...${NC}"
	brew update
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

check_rom() {
	if [[ -a "pd.ntsc-final.z64" ]]; then 
		echo "${PURPLE}Checking shasum...${NC}"
		ROM_NAME="pd.ntsc-final.z64"
		check_shasum "${ROM_NAME}"
	elif [[ -a "pd.pal-final.z64" ]]; then 
		echo "${PURPLE}Checking shasum...${NC}"
		ROM_NAME="pd.pal-final.z64"
		check_shasum "${ROM_NAME}"
	elif [[ -a "pd.jpn-final.z64" ]]; then 
		echo "${PURPLE}Checking shasum...${NC}"
		ROM_NAME="pd.jpn-final.z64"
		check_shasum "${ROM_NAME}"
	else 
		echo "${RED}Couldn't find a valid rom${NC}"
		echo "${PURPLE}Place the ROM in the same folder that the script is run from and rename it${NC}\n"
		exit 1
	fi
}

check_shasum() {
	USR_ROM_SHA=$(shasum $1 | awk '{print $1}')
	
	if [ $? -ne 0 ]; then
		echo "${RED}There was an issue checking the shasum of the file.${NC}"	
		exit 1
	fi
	
	echo "${PURPLE}\nThe shasum of the provided file is: \n${NC}$USR_ROM_SHA"
	
	if [[ $USR_ROM_SHA == $SHASUM_US1 ]]; then
		echo "${GREEN}US region rom v1.1 has been detected${NC}\n"
		REGION="ntsc"
		GAME_ID="pd.$ARCH"
		ROM_ID="pd.ntsc-final.z64"
		GAME_TITLE="Perfect Dark (US)"
		GAME_VERSION="1.1"
	elif [[ $USR_ROM_SHA == $SHASUM_EU ]]; then
		echo "${GREEN}EU region rom has been detected${NC}\n"
		REGION="pal"
		GAME_ID="pd.pal.$ARCH"
		ROM_ID="pd.pal-final.z64"
		GAME_TITLE="Perfect Dark (EU)"
		GAME_VERSION="1.0"
	elif [[ $USR_ROM_SHA == $SHASUM_JP ]]; then
		echo "${GREEN}JP region rom has been detected${NC}\n"
		REGION="jpn"
		GAME_ID="pd.jpn.$ARCH"
		ROM_ID="pd.jpn-final.z64"
		GAME_TITLE="Perfect Dark (JP)"
		GAME_VERSION="1.0"
	elif [[ $USR_ROM_SHA == $SHASUM_US ]]; then
		echo "${PURPLE}The shasum matches the US v1.0 version of the game. \n${RED}This version is unsupported.${NC}"
		exit 1
	else 
		echo "${RED}The shasum does not match any supported version of the game.${NC}"
		exit 1
	fi
}

build() {
	if [ -d perfect_dark ]; then
		rm -rf perfect_dark
	fi
	
	git clone --recursive https://github.com/fgsfdsfgs/perfect_dark.git
	# Check for errors
	if [ $? -ne 0 ]; then
		echo "${RED}There was an issue downloading the source repository${NC}"
		echo "${PURPLE}Quitting script...${NC}"	
		exit 1
	fi
	
	cd perfect_dark
	
	cmake -G"Unix Makefiles" -Bbuild -DCMAKE_MACOSX_RPATH=ON -DCMAKE_OSX_ARCHITECTURES=$ARCH -DROMID=${REGION}-final .
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
	mkdir -p "${GAME_TITLE}.app/Contents/Resources"
	
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
		<string>${GAME_VERSION}</string>
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
	ditto $(brew --prefix)/opt/sdl2/lib/libSDL2-2.0.0.dylib "${GAME_TITLE}.app/Contents/Frameworks"
	install_name_tool -change $(brew --prefix)/opt/sdl2/lib/libSDL2-2.0.0.dylib @executable_path/../Frameworks/libSDL2-2.0.0.dylib "${GAME_TITLE}.app/Contents/MacOS/${GAME_ID}"
	
	
	# Copy game data
	if [ ! -d $APP_SUPPORT/data ]; then 
		mkdir -p $APP_SUPPORT/data/
	fi
	
	if [ ! -a $APP_SUPPORT/data/$ROM_ID ]; then 
		cp $ROM_ID "$APP_SUPPORT/data/"
	fi
	
	curl -o ${GAME_TITLE}.app/Contents/Resources/${GAME_ID}.icns ${ICON_URL}
}

main_menu
