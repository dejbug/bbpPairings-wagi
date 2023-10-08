BinName := bbpPairings
BinExt := wagi

CacheDir := cache
OutDir := build

# WasiClang := $(wildcard $(OutDir)/*/bin/clang++)
# WasiDir := $(WasiClang:%/bin/clang++=%)
# $(info $(WasiDir))
# blah : ;

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
SampleTrfExpectedOutput-dutch := content-type: text/plain//56/39 5/13 6/49 1/3 42/53 7/25 26/16 30/36 9/59 11/20 24/4 97/22 77/87 50/79 60/34 73/46 38/101 63/65 31/57 66/2 43/90 18/110 33/76 10/72 109/80 74/35 15/19 27/56 8/51 84/78 48/14 55/82 29/41 96/104 70/112 95/45 47/28 93/83 32/69 75/108 21/40 85/52 102/94 23/105 58/61 103/88 12/86 17/37 89/91 44/99 54/62 92/64 98/67 100/106 68/107 71/81 111/
SampleTrfExpectedOutput-burstein := content-type: text/plain//56/53 5/36 6/13 7/49 1/3 24/25 26/30 39/16 9/42 11/20 59/4 97/22 77/87 50/79 60/34 73/46 38/101 63/65 31/57 66/2 43/110 18/90 33/80 10/72 109/76 74/35 15/19 27/56 8/51 84/78 55/48 96/82 14/41 29/95 70/104 112/45 93/69 47/28 75/108 32/83 85/52 21/40 102/105 23/103 58/61 94/91 88/37 12/86 17/64 44/99 54/62 100/67 92/81 68/89 71/106 98/107 111/

WasiDir := wasi-sdk-20.0
WasiFile := $(WasiDir)-linux.tar.gz
WasiSdkUrl := https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20/$(WasiFile)

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

$(OutDir)/$(BinName).exe : $(SourcesDeps) | $(OutDir)/
	$(MAKE) -C $(ModDir)
	cp $(ModDir)/bbpPairings.exe $@

$(OutDir)/$(BinName).wagi : $(SourcesDeps) | $(OutDir)/wasi-clang++
	$(MAKE) -C $(ModDir) COMP=clang WasiSdk=../$(OutDir)/$(WasiDir)
	cp $(ModDir)/build/bbpPairings.wagi $@
	chmod u+x $@

$(OutDir)/$(SourceDir)/ : $(CacheDir)/$(SourceArchive) ; tar -C $(OutDir) -mxf $<
$(CacheDir)/$(SourceArchive) : | $(CacheDir)/ ; curl -Lo $@ $(SourceArchiveUrl)

$(CacheDir)/$(SampleTrfId).trf : | $(CacheDir)/
	curl -o $@ https://lichess.org/swiss/$(@F)
	sed -i $(SampleTrfRewrite) $@

# FIXME: This is ugly. Paths need to be relative to src/Makefile.
$(OutDir)/wasi-clang++ : $(OutDir)/$(WasiDir)
	$(eval _Compiler = $(wildcard $(OutDir)/*/bin/clang++))
	$(eval _SysRoot = $(wildcard $(OutDir)/*/share/wasi-sysroot/))
	$(shell echo ../$(_Compiler) --sysroot ../$(_SysRoot) '"$$@"' > $@)
	chmod u+x $@

$(OutDir)/$(WasiDir) : $(CacheDir)/$(WasiFile) | $(OutDir)/
	cd $(OutDir) && tar xmzf ../$<

# $(CacheDir)/$(WasiFile) : ; curl -Lo $@ $(WasiSdkUrl)
$(CacheDir)/$(WasiFile) : | $(CacheDir)/ ; cp ~/Downloads/$(WasiFile) $@

%/ : ; mkdir -p $@

clean : ; $(MAKE) -C $(ModDir)/ clean
purge : | clean ; rm -rf $(OutDir)/
reset : | purge ; rm -rf $(CacheDir)/ && git checkout $(CacheDir)/

.PHONY : run test

Bin := $(OutDir)/$(BinName).$(BinExt)
Trf := $(CacheDir)/$(SampleTrfId).trf

ifeq ($(BinExt),exe)
define runBin
cat $(Trf) | $(Bin) --$1
endef
else ifeq ($(BinExt),wagi)
define runBin
cat $(Trf) | wasmtime $(Bin) -- --$1
endef
else
$(error unsupported binary extension "$(BinExt)")
endif

define makeRunTarget
.PHONY : run-$1
run-$1 : $(Bin) $(Trf)
	$$(call runBin,$1)
endef

$(eval $(call makeRunTarget,dutch))
$(eval $(call makeRunTarget,burstein))
run : | run-dutch ; @echo -n

define makeTestTarget
.PHONY : test-$1
test-$1 : $(Bin) $(Trf)
	$$(eval _TestOutput = $$(shell $(call runBin,$1) | tr '\n' '/'))
	@echo $$(shell [[ "$$(_TestOutput)" = "$$(SampleTrfExpectedOutput-$1)" ]] && echo "$1 OK" )
endef

$(eval $(call makeTestTarget,dutch))
$(eval $(call makeTestTarget,burstein))
test : | test-dutch test-burstein ; @echo -n

# Show `diff` between original and mod (in color, w/ or w/o pager).
diff : $(OutDir)/$(SourceDir)/ ; -@$(DiffPrint) $< $(ModDir)
dif  : $(OutDir)/$(SourceDir)/ ; -@$(DiffPrint) $< $(ModDir) | less -R

# Create a patch between original and mod (while silencing the makefile error
#	raised due to non-zero exit code).
%.patch : $(OutDir)/$(SourceDir)/ ; @echo -n $(shell $(DiffPatch) $< $(ModDir) > $@)

.DELETE_ON_ERROR :
