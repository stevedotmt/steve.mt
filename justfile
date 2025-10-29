serve:
    hugo serve -O

post title:
    hugo new content blog/$(date +%Y-%m-%d)-{{title}}.md
