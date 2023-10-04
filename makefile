
# CloneUrl = https://github.com/BieremaBoyzProgramming/bbpPairings.git
SourceVersion = 5.0.1
SourceArchiveUrl = https://github.com/BieremaBoyzProgramming/bbpPairings/archive/refs/tags/v$(SourceVersion).tar.gz
SourceArchiveName = bbpPairings-v$(SourceVersion).tar.gz
SourceFolderName = bbpPairings-$(SourceVersion)

.PHONY : all clean reset test

all : $(SourceFolderName)/

$(SourceFolderName)/ : $(SourceArchiveName) ; tar -mxf $<
$(SourceArchiveName) : ; curl -Lo $@ $(SourceArchiveUrl)

clean : ; rm -rf $(SourceFolderName)/
reset : | clean ; rm -r $(SourceArchiveName)
