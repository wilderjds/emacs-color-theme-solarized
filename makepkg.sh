#!/usr/bin/env bash

version=$1

if [ "$version" = "" ]; then
    version=$(date -u '+%Y%m%d')
fi
echo "version = $version"

dir="color-theme-lunarized-${version}"

mkdir $dir

cp *.el $dir
sed -i "s/%%version%%/$version/" "$dir/color-theme-lunarized-pkg.el"

tar cf color-theme-lunarized-${version}.tar $dir
