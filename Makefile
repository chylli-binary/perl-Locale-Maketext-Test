test:
	dzil test

xtest:
	dzil xtest

tidy:
	find . -name '*.p?.bak' -delete
	find . -not -path "./.git*" -name '*.p[lm]' -o -name '*.t' | xargs perltidy -pro=t/rc/.perltidyrc --backup-and-modify-in-place -bext=tidyup
	find . -name '*.tidyup' -delete
