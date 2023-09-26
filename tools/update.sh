#!/bin/bash

gex="/Applications/Godot.app/Contents/MacOS/Godot"
bdir="Export"
pdir=".."
vno=$(awk -F'"' '/^const VERSION/ {print $2}' ../scripts/singletons/CardInfo.gd)

echo Preparing to generate builds for version: $vno

cd $pdir

if false && [ -f "$bdir/win-$vno.exe" ]; then
    echo "$bdir/win-$vno.exe already exists! skipping..."
else
    echo "Building $bdir/win-$vno.exe"
    $gex --export-debug --headless "Windows Desktop" $bdir/win-$vno.exe
    7zz a $bdir/win-$vno.zip $bdir/win-$vno.exe $bdir/imf_tunnel.dll $bdir/win-$vno.pck
fi

if false && [ -f "$bdir/osx-$vno.zip" ]; then
    echo "$bdir/osx-$vno.zip already exists! skipping..."
else
    echo "Building $bdir/osx-$vno.zip"
    $gex --export-debug --headless "Mac OSX" $bdir/osx-$vno.zip
fi

if false && [ -f "$bdir/linux-$vno.x86_64" ]; then
    echo "$bdir/linux-$vno.x86_64 already exists! skipping..."
else
    echo Building $bdir/linux-$vno.x86_64
    $gex --export-debug --headless "Linux/X11" $bdir/linux-$vno.x86_64
    7zz a $bdir/linux-$vno.zip $bdir/linux-$vno.x86_64 $bdir/libimf_tunnel.so $bdir/linux-$vno.pck
fi

if false && [ -f "$bdir/android-$vno.apk" ]; then
    echo "$bdir/android-$vno.apk already exists! skipping..."
else
    echo Building $bdir/android-$vno.apk
    $gex --export-debug --headless "Android" $bdir/android-$vno.apk
fi


echo Building $bdir/HTML5.zip
mkdir $bdir/HTML5
$gex --export-debug --headless "HTML5" $bdir/HTML5/index.html
7zz a $bdir/HTML5.zip $bdir/HTML5

echo "Pushing windows..."
butler push $bdir/win-$vno.zip 107zxz/inscryption-multiplayer-godot:win --userversion $vno
echo "Pushing osx..."
butler push $bdir/osx-$vno.zip 107zxz/inscryption-multiplayer-godot:osx --userversion $vno
echo "Pushing linux..."
butler push $bdir/linux-$vno.zip 107zxz/inscryption-multiplayer-godot:linux --userversion $vno
echo "Pushing android..."
butler push $bdir/android-$vno.apk 107zxz/inscryption-multiplayer-godot:android --userversion $vno
echo "Pushing HTML5"
butler push $bdir/HTML5.zip 107zxz/inscryption-multiplayer-godot:web --userversion $vno
