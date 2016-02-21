#!/bin/sh

# Shell script to be executed as pre-commit hook by Git.
# To use this hook create a symlink to ${projectDir}/.git/hooks/pre-commit
# Intent: many java projects configure their passwords into a properties file (typically
# injected through the build like gradle.properties), this script checks to see that the 
# passwords defined in gradle.properties are not staged for commit.  Nobody wants to check 
# in a password!

contains() {
	local string="$1"
	local substring="$2"

	if [[ $string == *"$substring"* ]]; then
		return 0;
	fi
	return 1;
}

trim() {
    local string="$1"
    string="${string#"${string%%[![:space:]]*}"}"
    string="${string%"${string##*[![:space:]]}"}"
    echo "$string"
}

NO_DETECTED_PASSWORD=0

echo "pre-commit start"

if [[ -e "./gradle.properties" ]]; then
	while IFS='' read -r line || [[ -n "$line" ]]; do
		IFS='=' read -ra properties <<< "$line"
		if contains ${properties[0]} "Password"; then
			password=$(trim "${properties[1]}")
			output=`git diff-index --cached --summary -S"$password" HEAD`
			if [[ -n "$output" ]]; then
				NO_DETECTED_PASSWORD=1
				echo " Aborting commit due to password staged for commit: $password"
				echo "$output"
			fi
		fi
	done < "./gradle.properties"
else
	echo "Cannot search for passwords without file: gradle.properties."
fi
echo "pre-commit finish"

exit "$NO_DETECTED_PASSWORD"