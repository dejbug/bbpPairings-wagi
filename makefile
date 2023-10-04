
# SourceRepository = https://github.com/BieremaBoyzProgramming/bbpPairings.git
SourceArchiveVersion = 5.0.1
SourceArchiveUrl = https://github.com/BieremaBoyzProgramming/bbpPairings/archive/refs/tags/v$(SourceArchiveVersion).tar.gz
SourceArchive = bbpPairings-v$(SourceArchiveVersion).tar.gz
SourceFolder = bbpPairings-$(SourceArchiveVersion)
ModFolder = bbpPairings/

.PHONY : all clean reset test patch

all : $(SourceFolder)/

$(SourceFolder)/ : $(SourceArchive) ; tar -mxf $<
$(SourceArchive) : ; curl -Lo $@ $(SourceArchiveUrl)

clean : ; rm -rf $(SourceFolder)/
reset : | clean ; rm -r $(SourceArchive)

%.patch : $(SourceFolder)/ ; diff -rN $(SourceFolder)/ $(ModFolder) > $@
