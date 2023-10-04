# SourceRepository := https://github.com/BieremaBoyzProgramming/bbpPairings.git
SourceArchiveVersion := 5.0.1
SourceArchiveUrl := https://github.com/BieremaBoyzProgramming/bbpPairings/archive/refs/tags/v$(SourceArchiveVersion).tar.gz
SourceArchive := bbpPairings-v$(SourceArchiveVersion).tar.gz
SourceFolder := bbpPairings-$(SourceArchiveVersion)
ModFolder := src/

# Output highlighter to use. Defaults to grc, if present.
GRC := $(shell which grc)
GRC := $(GRC:%=% )

.PHONY : all clean reset test diff

all : ; @echo -n

$(SourceFolder)/ : $(SourceArchive) ; tar -mxf $<
$(SourceArchive) : ; curl -Lo $@ $(SourceArchiveUrl)

clean : ; rm -rf $(SourceFolder)/
reset : | clean ; rm -r $(SourceArchive)

# Show `diff` between original and mod (in color, if `grc` is present).
diff : $(SourceFolder)/ ; -@$(GRC)diff -rN $(SourceFolder)/ $(ModFolder)

# Create a patch between original and mod (while silencing the makefile error
#	raised due to non-zero exit code).
%.patch : $(SourceFolder)/ ; @echo -n $(shell diff -rN $(SourceFolder)/ $(ModFolder) > $@)

.DELETE_ON_ERROR :
