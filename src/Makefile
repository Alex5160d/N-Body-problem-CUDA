RM := rm -rf
CC=nvcc
CFLAGS=-c -O3
LIBS := -lGLEW -lGLU -lglut
SOURCES = bodySystemAbstract.cu bodySystemCpu.cu bodySystemCuda.cu main.cu renderer.cu
OBJECTS=$(SOURCES:.cu=.o)
EXECUTABLE=nbody_problem


all : $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS) 
	$(CC) $(LIBS) $(OBJECTS) -o $@

$(OBJECTS): $(SOURCES) 
	$(CC) $(CFLAGS) $(SOURCES)
 
clean:
	-$(RM) $(OBJECTS)

mrproper: clean
	-$(RM) "nbody_problem"
