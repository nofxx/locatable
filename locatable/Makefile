CC=gcc -std=c99
#arm-apple-darwin-cc
LD=$(CC)
LDFLAGS=-multiply_defined suppress -lobjc -framework CoreLocation -framework CoreFoundation -framework Foundation -framework UIKit -framework CoreGraphics -L"/usr/lib" -F"/System/Library/Frameworks" -bind_at_load

all:    Locatable

Locatable:  main.o LocatableAppDelegate.o OptionViewController.o
	$(LD) $(LDFLAGS) -v -o $@ $^
	ldid -S $@

%.o:    %.m
		$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
		rm -f *.o Locatable

install: Locatable
	rm /Applications/Locatable.app/Locatable
	cp Locatable icon.png Info.plist Default.png functions.html /Applications/Locatable.app

run: install
	launch com.tralfamadore.Locatable
