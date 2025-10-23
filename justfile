serve:
    hugo serve -O

init-theme:
    git submodule update --init --recursive

update-theme:
    git submodule foreach git pull origin master

post title:
    hugo new content blog/$(date +%Y-%m-%d)-{{title}}.md
