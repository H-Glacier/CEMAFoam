#!/bin/bash
# Complete compilation script for CEMAFoam with PyJac

echo "============================================="
echo "Complete CEMAFoam Build Script"
echo "============================================="

# Check if OpenFOAM environment is set
if [ -z "$WM_PROJECT" ]; then
    echo "Error: OpenFOAM environment not set!"
    echo "Please source OpenFOAM bashrc first:"
    echo "  For OpenFOAM v2006:"
    echo "    source /opt/OpenFOAM/OpenFOAM-v2006/etc/bashrc"
    echo "  For OpenFOAM v6:"
    echo "    source /opt/openfoam6/etc/bashrc"
    exit 1
fi

echo "Using OpenFOAM: $WM_PROJECT $WM_PROJECT_VERSION"
echo ""

# Step 1: Build PyJac dummy library
echo "Step 1: Building PyJac dummy library..."
echo "========================================="
cd /workspace/src/thermophysicalModels/chemistryModel

# Compile the C file to object file
echo "Compiling pyjac_dummy.c..."
gcc -c -fPIC -IpyjacInclude pyjacSrc/pyjac_dummy.c -o pyjacSrc/pyjac_dummy.o

if [ $? -ne 0 ]; then
    echo "Error: Failed to compile pyjac_dummy.c"
    exit 1
fi

# Create static library
echo "Creating static library..."
ar rcs pyjacSrc/libpyjac_dummy.a pyjacSrc/pyjac_dummy.o

# Create shared library  
echo "Creating shared library..."
gcc -shared -o pyjacSrc/libpyjac_dummy.so pyjacSrc/pyjac_dummy.o -lm

echo "PyJac dummy library built successfully!"
echo ""

# Step 2: Clean previous OpenFOAM build
echo "Step 2: Cleaning previous build..."
echo "========================================="
wclean

# Step 3: Create lnInclude directory
echo ""
echo "Step 3: Creating lnInclude directory..."
echo "========================================="
wmakeLnInclude .

# Step 4: Compile the OpenFOAM library
echo ""
echo "Step 4: Compiling CEMAFoam chemistry library..."
echo "========================================="
wmake libso

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "============================================="
    echo "BUILD SUCCESSFUL!"
    echo "============================================="
    echo ""
    echo "Library created at: $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so"
    echo ""
    echo "Checking for PyJac symbols:"
    echo "----------------------------"
    nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -E "eval_h|dydt|eval_jacob" | head -5
    echo ""
    echo "Library dependencies:"
    echo "----------------------------"
    ldd $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep -E "pyjac|libm"
    echo ""
    echo "============================================="
    echo "Next steps:"
    echo "1. Ensure your case uses libcemaPyjacChemistryModel.so"
    echo "2. Add to system/controlDict:"
    echo "   libs (\"libcemaPyjacChemistryModel.so\");"
    echo "3. Run your case with reactingFoam"
    echo "============================================="
else
    echo ""
    echo "============================================="
    echo "BUILD FAILED!"
    echo "============================================="
    echo "Please check the error messages above."
    echo ""
    echo "Common issues:"
    echo "1. OpenFOAM environment not properly set"
    echo "2. Missing dependencies"  
    echo "3. Permission issues in $FOAM_USER_LIBBIN"
    echo "============================================="
    exit 1
fi