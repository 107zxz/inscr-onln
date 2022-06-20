#!/bin/bash

gex="/Applications/Godot.app/Contents/MacOS/Godot"
bdir="Export"
pdir=".."
vno=$(awk -F'"' '/^const VERSION/ {print $2}' ../scripts/Network.gd)

echo Preparing to generate builds for version: $vno

cd $pdir

if [ -f "$bdir/win-$vno.exe" ]; then
    echo "$bdir/win-$vno.exe already exists! skipping..."
else
    echo "Building $bdir/win-$vno.exe"
    $gex --export-debug "Windows Desktop" $bdir/win-$vno.exe
fi

if [ -f "$bdir/osx-$vno.zip" ]; then
    echo "$bdir/osx-$vno.zip already exists! skipping..."
else
    echo "Building $bdir/osx-$vno.zip"
    $gex --export-debug "Mac OSX" $bdir/osx-$vno.zip
fi

if [ -f "$bdir/linux-$vno.x86_64" ]; then
    echo "$bdir/linux-$vno.x86_64 already exists! skipping..."
else
    echo Building $bdir/linux-$vno.x86_64
    $gex --export-debug "Linux/X11" $bdir/linux-$vno.x86_64
fi

echo "Pushing windows..."
butler push $bdir/win-$vno.exe 107zxz/inscryption-multiplayer-godot:win --userversion $vno
echo "Pushing osx..."
butler push $bdir/osx-$vno.zip 107zxz/inscryption-multiplayer-godot:osx --userversion $vno
echo "Pushing linux..."
butler push $bdir/linux-$vno.x86_64 107zxz/inscryption-multiplayer-godot:linux --userversion $vno