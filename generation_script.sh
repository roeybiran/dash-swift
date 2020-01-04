#!/bin/bash

# https://kapeli.com/docsets#dashDocset
# https://github.com/Kapeli/Dash-User-Contributions/wiki/Docset-Contribution-Checklist
# https://github.com/Kapeli/Dash-User-Contributions#contribute-a-new-docset

# wget -k -r -p -np https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html

SOURCE="${BASH_SOURCE[0]}"

# resolve $SOURCE until the file is no longer a symlink
while [ -h "$SOURCE" ]; do
	DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

DIR=$(dirname "${SOURCE}")

db="${DIR}/Swift.docset/Contents/Resources/docSet.dsidx"
rm "${db}" 2>/dev/null
sqlite3 "${db}" 'CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT); CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);'
for h in h1_Guide h2_Section h3_Entry h4_Keyword; do
	element=$(echo "${h}" | cut -d"_" -f1)
	type=$(echo "${h}" | cut -d"_" -f2)
	for f in "${DIR}/Swift.docset/Contents/Resources/Documents/LanguageGuide/"*; do
		while IFS=$'\n' read -r anchor; do
			name=$(echo "${anchor}" | grep -E --only-matching "^<..>.+<a" | sed -E 's/<..>//' | sed -E 's/<a//')
			path=$(echo "${anchor}" | grep -E --only-matching 'href=.+title="' | sed 's/href="//' | sed 's/" title="//')
			path="LanguageGuide/${path}"
			sqlite3 "${DIR}/Swift.docset/Contents/Resources/docSet.dsidx" "INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (\"${name}\", \"${type}\", \"${path}\");"
		done < <(grep -E --only-matching "<${element}>.+<a.+</${element}>" "${f}")
	done
done
