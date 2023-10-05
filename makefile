BinName := bbpPairings
BinExt := exe

OutDir := build
CacheDir := cache

SourceArchiveVersion := 5.0.1
SourceArchiveUrl := https://github.com/BieremaBoyzProgramming/bbpPairings/archive/refs/tags/v$(SourceArchiveVersion).tar.gz
SourceArchive := bbpPairings-v$(SourceArchiveVersion).tar.gz
SourceDir := bbpPairings-$(SourceArchiveVersion)
ModDir := src

Sources := $(shell find $(ModDir) \( -name '*.cpp' -or -name '*.h' \))
SourcesDeps := $(filter %.cpp,$(Sources))
SourcesDeps := $(SourcesDeps:%.cpp=%.d)
SourcesDeps := $(SourcesDeps:$(ModDir)/%=$(OutDir)/dep/%)

# A sample TRF to fetch from Lichess. We need to artificially increase its
#	XXR (round count), here from 20 to 21, so the pairer doesn't complain.
SampleTrfId := j8rtJ5GL
SampleTrfRewrite := '9s/20/21/'
SampleTrfExpectedOutput := 56/39 5/13 6/49 1/3 42/53 7/25 26/16 30/36 9/59 11/20 24/4 97/22 77/87 50/79 60/34 73/46 38/101 63/65 31/57 66/2 43/90 18/110 33/76 10/72 109/80 74/35 15/19 27/56 8/51 84/78 48/14 55/82 29/41 96/104 70/112 95/45 47/28 93/83 32/69 75/108 21/40 85/52 102/94 23/105 58/61 103/88 12/86 17/37 89/91 44/99 54/62 92/64 98/67 100/106 68/107 71/81 111/

# External output highlighter to use. Defaults to grc, if present.
OH := $(shell which grc 2> /dev/null)
# We need to force the colors on so they are not dropped when piping.
OH := $(if $(OH),$(OH) --colour=on ,)

DIFF := diff
DiffCommonFlags := -r --no-dereference -x '*.[od]' -x '*.exe'
DiffPatchFlags := -N
# Bright red deletions, bright green additions, underlined bright yellow meta.
DiffPalette := 'rs=0:hd=1:ad=1;32:de=1;31:ln=1;4;33'
# We need to force the colors on so they are not dropped when piping.
DiffColorFlags := --color=always --palette=$(DiffPalette)
DiffPrintFlags := --unidirectional-new-file $(if $(OH),,$(DiffColorFlags) )
# Use external output highlighter, if present, or fall back on diff-internal
#	highlighting (which by default uses the dim color spectrum on my machine).
DiffPatch := $(DIFF) $(DiffCommonFlags) $(DiffPatchFlags)
DiffPrint := $(OH)$(DIFF) $(DiffCommonFlags) $(DiffPrintFlags)

CXX := g++
CXXFLAGS :=

NonBuildingGoals := clean purge reset dif diff
filterNonBuildingGoals := $(filter $(NonBuildingGoals),$(MAKECMDGOALS))

.PHONY : all clean purge reset test dif diff

all : $(OutDir)/$(BinName).$(BinExt)

$(SourcesDeps) : $(OutDir)/dep/%.d : $(ModDir)/%.cpp
	mkdir -p $(dir $@)
# 	$(eval _Obj = $(<:%.cpp=%.o))
# 	$(eval _Obj = $(<:$(ModDir)/src/%=$(OutDir)/obj/%))
# 	$(info $(_Obj))
# 	$(CXX) $(CXXFLAGS) -MF $@ -MT $@ -MT $(_Obj) -MM $<
	$(CXX) $(CXXFLAGS) -MF $@ -MT $@ -MM $<

ifeq (,$(call filterNonBuildingGoals))
-include $(SourcesDeps)
endif

$(OutDir)/$(BinName).$(BinExt) : $(SourcesDeps) | $(OutDir)/
	$(MAKE) -C $(ModDir)
	cp $(ModDir)/bbpPairings.exe $@

$(OutDir)/$(SourceDir)/ : $(CacheDir)/$(SourceArchive) ; tar -C $(OutDir) -mxf $<
$(CacheDir)/$(SourceArchive) : | $(CacheDir)/ ; curl -Lo $@ $(SourceArchiveUrl)

$(CacheDir)/$(SampleTrfId).trf : | build
	curl -o $@ https://lichess.org/swiss/$(@F)
	sed -i $(SampleTrfRewrite) $@

%/ : ; mkdir -p $@

clean : ; $(MAKE) -C $(ModDir)/ clean
purge : | clean ; rm -rf $(OutDir)/
reset : | purge ; rm -rf $(CacheDir)/

test : $(OutDir)/$(BinName).$(BinExt) $(CacheDir)/$(SampleTrfId).trf
	$(eval _Bin = $<)
	$(eval _Trf = $(word 2,$^))
ifeq ($(BinExt),exe)
	$(eval _TestOutput = $(shell $(_Bin) --dutch $(_Trf) -p | tr '\n' '/'))
else ifeq ($(BinExt),wasm)
	$(eval _TestOutput = $(shell cat $(_Trf) | $(_Bin) --dutch -p | tr '\n' '/'))
endif
	@echo $(shell [[ "$(_TestOutput)" = "$(SampleTrfExpectedOutput)" ]] && echo "OK" )

# Show `diff` between original and mod (in color, w/ or w/o pager).
diff : $(OutDir)/$(SourceDir)/ ; -@$(DiffPrint) $< $(ModDir)
dif  : $(OutDir)/$(SourceDir)/ ; -@$(DiffPrint) $< $(ModDir) | less -R

# Create a patch between original and mod (while silencing the makefile error
#	raised due to non-zero exit code).
%.patch : $(OutDir)/$(SourceDir)/ ; @echo -n $(shell $(DiffPatch) $< $(ModDir) > $@)

.DELETE_ON_ERROR :
