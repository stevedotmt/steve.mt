.PHONY: update-theme
update-theme:
	git submodule foreach git pull origin master
