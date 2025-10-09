init-theme:
    git submodule update --init --recursive

update-theme:
    git submodule foreach git pull origin master
