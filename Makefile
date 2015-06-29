build:
	cp -R lib src
	coffee -c lib
	find lib -iname "*.coffee" -exec rm '{}' ';'

unbuild:
	rm -rf lib
	mv src lib
