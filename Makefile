%.42f: %.per 
	fglform -M $<

%.42m: %.4gl 
	fglcomp -M $*


MODS=$(patsubst %.4gl,%.42m,$(wildcard *.4gl))
FORMS=$(patsubst %.per,%.42f,$(wildcard *.per))

all: $(MODS) $(FORMS)

run: all
	fglrun pdfjs


#rule called by pdfjs.4gl
build_and_patch: pdf.js/src webcomponents webcomponents/web/web.html

pdf.js/src:
	-git submodule init
	-git submodule update

webcomponents: pdf.js/src
	rm -rf webcomponents
#       note you need node and npm for that and 'shelljs' but anyway gbc folks shouldn't have a problem with that
	cd pdf.js && npm install shelljs && node make generic && cd ..
	mkdir webcomponents
	cp -a pdf.js/build/generic/web/ webcomponents/web/
	cp -a pdf.js/build/generic/build/ webcomponents/build/

#we use the original viewer page and inject our gICAPI boiler plate script
webcomponents/web/web.html: webcomponents webcomponents/web/viewer.html
	cp webcomponents/web/viewer.html webcomponents/web/web.html
	patch -p0 <web4.patch
	cp myGICAPI.js webcomponents/web/

fglwebrun:
	git clone https://github.com/FourjsGenero/tool_fglwebrun.git fglwebrun

webrun: all fglwebrun build_and_patch
	fglwebrun/fglwebrun pdfjs

gdcwebrun: all fglwebrun build_and_patch
	GDC=1 fglwebrun/fglwebrun pdfjs

clean:
	rm -f *.42?
	rm -rf webcomponents fglwebrun
	rm -f  *.zip cookie.txt

distclean: clean
	cd pdf.js && git clean -fdx && git checkout package.json
	
