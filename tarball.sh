#!/bin/sh
export dir=`basename "$PWD"`

cd ..;tar -czf $dir/$dir.tgz  --exclude .gitignore --exclude ._.DS_Store --exclude .DS_Store --exclude ModelLibrary --exclude .git --exclude .vagrant --exclude  .http_proxy --exclude .gitmodules --exclude $dir.tgz  `cd $dir; git ls-tree --name-only -r master | grep -v .git | awk '{print "'$dir'/"$0}'`

#cd ..;tar --exclude .gitignore --exclude ._.DS_Store --exclude .DS_Store --exclude ModelLibrary --exclude .git --exclude .vagrant --exclude  .http_proxy --exclude .gitmodules --exclude $dir.tgz -czf $dir/$dir.tgz $dir