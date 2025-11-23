#!/bin/bash
# Build PyJac dummy implementation

echo "Building PyJac dummy library..."

cd /workspace/src/thermophysicalModels/chemistryModel

# Compile the C file to object file
echo "Compiling pyjac_dummy.c..."
gcc -c -fPIC -IpyjacInclude pyjacSrc/pyjac_dummy.c -o pyjacSrc/pyjac_dummy.o

# Create a static library
echo "Creating static library..."
ar rcs pyjacSrc/libpyjac_dummy.a pyjacSrc/pyjac_dummy.o

# Create a shared library
echo "Creating shared library..."
gcc -shared -o pyjacSrc/libpyjac_dummy.so pyjacSrc/pyjac_dummy.o -lm

echo "PyJac dummy library built successfully!"
echo "Files created:"
ls -la pyjacSrc/*.o pyjacSrc/*.a pyjacSrc/*.so 2>/dev/null