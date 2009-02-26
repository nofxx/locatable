CC=gcc
#arm-apple-darwin-cc
LD=$(CC)
LDFLAGS=-multiply_defined suppress -lobjc -framework CoreLocation -framework CoreFoundation -framework Foundation -framework UIKit -lsqlite3 -L"/usr/lib" -F"/System/Library/Frameworks" -bind_at_load

all:    Relocatable

Relocatable:  main.o Relocatable.o 
	$(LD) $(LDFLAGS) -v -o $@ $^
	ldid -S $@

%.o:    %.m
		$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
		rm -f *.o Relocatable

