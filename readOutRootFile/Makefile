# Autor: Fernando Quinonez
# Para trabajar con linux o macintosh, no existe nada mas :D
# Los codigos fuente deben ser .cxx

include Makefile.arch

mains = main.$(SrcSuf) mainDict.$(SrcSuf) 
maino = main.$(ObjSuf) mainDict.$(ObjSuf) 
mainso = main.$(DllSuf) 
main = mainExe$(ExeSuf) 
mainlib = $(shell pwd)/$(EVENTSO)

OBJS = $(maino)
PROGRAMS = $(main)

.SUFFIXES: .$(SrcSuf) .$(ObjSuf) .$(DllSuf)
.PHONY:    Aclock Hello Tetris


# Esta parte da las reglas para hacer las librerias dinamicas
all: $(PROGRAMS)
$(mainso): $(maino)
ifeq ($(PLATFORM),macosx) # 1
# We need to make both the .dylib and the .so
		$(LD) $(SOFLAGS)$@ $(LDFLAGS) $^ $(OutPutOpt) $@ $(EXPLLINKLIBS)

ifneq ($(subst $(MACOSX_MINOR),,1234),1234) # 2
ifeq ($(MACOSX_MINOR),4) # 3
		ln -sf $@ $(subst .$(DllSuf),.so,$@)
endif # 3
endif # 2

else
		$(LD) $(SOFLAGS) $(LDFLAGS) $^ $(OutPutOpt) $@ $(EXPLLINKLIBS)
endif # 1

		@echo "$@ done"

# aqui se construye el ejecutable
$(main):       $(mainso) 
		$(LD) $(LDFLAGS) $(maino) $(LIBS) $(OutPutOpt)$@
		@echo "$@ done"

clean:
		@rm -f $(OBJS) $(PROGRAMS) $(mainso) *Dict.*



.SUFFIXES: .$(SrcSuf)

mainDict.$(SrcSuf): mainLinkDef.h
	@echo "Generating dictionary $@..."
	$(ROOTCINT) -f $@ -c $^



.$(SrcSuf).$(ObjSuf):
	$(CXX)  $(CXXFLAGS) -c $<

ifeq ($(GCC_MAJOR),4)
ifeq ($(GCC_MINOR),1)
TBenchDict.o: CXXFLAGS += -Wno-strict-aliasing
endif
endif


