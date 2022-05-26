#!/bin/bash
mkdir ~/.ssh/privateKeys
chmod 700 ~/.ssh/privateKeys
echo 'eval $(ssh-agent) > /dev/null' >>  ~/.zshrc
echo 'for possiblekey in ${HOME}/.ssh/privateKeys/*; do' >>  ~/.zshrc
echo '        ssh-add "$possiblekey" > /dev/null' >>  ~/.zshrc
echo 'done' >> ~/.zshrc