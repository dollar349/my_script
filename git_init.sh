#!/bin/sh
git config --global user.name “Dollar”
git config --global user.email "dollar@acsgconsults.com"
git config --global color.ui true
git config --global alias.st status
git config --global core.editor "vim"
git config --global credential.helper store
git config --global push.default current
git config --global alias.ck checkout
git config --global alias.br branch
git config --global alias.cm commit
git config --global alias.cpk cherry-pick
#git config --global http.sslverify false
git config --global url."https://".insteadOf git://

