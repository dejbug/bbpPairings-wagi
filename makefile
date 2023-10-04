CloneUrl = https://github.com/BieremaBoyzProgramming/bbpPairings.git
DownloadUrl = https://github.com/BieremaBoyzProgramming/bbpPairings/archive/refs/tags/v5.0.1.tar.gz

.PHONY : all clean reset test

all : bbpPairings/

bbpPairings/ : ; git clone $(CloneUrl)



clean : ;
reset : | clean ; rm -rf bbpPairings/
