# SourceRepository := https://github.com/BieremaBoyzProgramming/bbpPairings.git
SourceArchiveVersion := 5.0.1
SourceArchiveUrl := https://github.com/BieremaBoyzProgramming/bbpPairings/archive/refs/tags/v$(SourceArchiveVersion).tar.gz
SourceArchive := bbpPairings-v$(SourceArchiveVersion).tar.gz
SourceFolder := bbpPairings-$(SourceArchiveVersion)
ModFolder := src/

# External output highlighter to use. Defaults to grc, if present.
OH := $(shell which grc 2> /dev/null)
OH := $(if $(OH),$(OH) --colour=on ,)

# Bright red deletions, bright green additions, underlined bright yellow meta.
DiffPalette = 'rs=0:hd=1:ad=1;32:de=1;31:ln=1;4;33'
# Diff command. Use external output highlighter, if present, or
#	fall back on diff-internal highlighting (which by default
#	uses the dim color spectrum on my machine).
DIFF := $(OH)diff -rN $(if $(OH),,--color=always --palette=$(DiffPalette) )

.PHONY : all clean reset test dif diff

all : ; @echo -n

$(SourceFolder)/ : $(SourceArchive) ; tar -mxf $<
$(SourceArchive) : ; curl -Lo $@ $(SourceArchiveUrl)

clean : ; rm -rf $(SourceFolder)/
reset : | clean ; rm -r $(SourceArchive)

# Show `diff` between original (first) and mod (in color, w/ or w/o pager).
dif  : $(SourceFolder)/ ; -@$(DIFF) $(ModFolder) $(SourceFolder)
diff : $(SourceFolder)/ ; -@$(DIFF) $(ModFolder) $(SourceFolder) | less -R

# Create a patch between original and mod (while silencing the makefile error
#	raised due to non-zero exit code).
%.patch : $(SourceFolder)/ ; @echo -n $(shell diff -rN $(SourceFolder)/ $(ModFolder) > $@)

.DELETE_ON_ERROR :
