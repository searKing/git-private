# git-private

Use private repository of git with a free account.

## Overview

+ This project can sync the encryed project based on user's original project automatically.

+ This project can backup user's original project as an encryed project automatically.

## How this project work

0. Beforehand:

    There must be a git repository such as **git-private-demo** which contains .git/ on your disk.

1. Prepare:

    + clone or add this git-private project under **git-private-demo**
    ```bash
    cd git-private-demo/
    git submodule add https://github.com/searKing/git-private.git
    ```
    + install private tools
    ```bash
    cd git-private/
    ./install.sh
    # OK, some sub dirs will auto generate or update under your public project, you can just ignore them
    # such as :
    # .git-private-demo.private/        for private repo
    # .git-private-demo.private.git/    if remote_private_url="" set in config.ini under git-private/
    ```

    + uninstall private tools, if you want.
    ```bash
    cd git-private/
    ./uninstall.sh
    ```
2. Usage: <you can ignore this chapter, because everything can be done automatically>
    + autogenerate the private repo when you commit your public project
    ```bash
    git add what you what
    git commit what you what
    # OK, some sub dirs will auto generate or update under your public project, you can just ignore them
    # such as :
    # .git-private-demo.cached/         for speed up
    ```
    + auto upload the private repo to remote private
    ```bash
    git push what you what
    ```

    + recover your public repo to the dir .git-private-demo.public/ from .git-private-demo.private
    ```bash
    git commit -m "GodBlessMe"
    git commit -m "GodBlessMe"
    git commit -m "GodBlessMe"
    # .git-private-demo.public/ is recoverd public prj
    ``` 
     + others Great! You are can work as usual now! Add some content and do some change. Then git add && git commit && git push
     This process will pull the content from Github to privateRoot/ and decrypt it into a normal directory under publicRoot/. During this process git.private.pem will be used.

IMPORTANT:
==========

    After the pem files generated with "./install.sh" under the dir git-private/, which are stored under ./git/hooks/KeyRoot. Please take care of these *.pem files carefully. Once they are lost, you have no way to decrypt the file on you Github which means you lost them forever!!
