#!/bin/bash
# Compilation script for CEMAFoam chemistry model with PyJac

echo "============================================="
echo "Compiling CEMAFoam Chemistry Model"
echo "============================================="

# Check if OpenFOAM environment is set
if [ -z "$WM_PROJECT" ]; then
    echo "Error: OpenFOAM environment not set!"
    echo "Please source OpenFOAM bashrc first:"
    echo "  source /opt/OpenFOAM/OpenFOAM-v2006/etc/bashrc"
    echo "  OR"
    echo "  source /opt/OpenFOAM/OpenFOAM-6/etc/bashrc"
    exit 1
fi

echo "Using OpenFOAM: $WM_PROJECT $WM_PROJECT_VERSION"
echo "Target directory: $FOAM_USER_LIBBIN"

# Navigate to chemistry model directory
cd /workspace/src/thermophysicalModels/chemistryModel

# Clean previous build
echo ""
echo "Cleaning previous build..."
wclean

# Create lnInclude directory
echo ""
echo "Creating lnInclude directory..."
wmakeLnInclude .

# Compile the library
echo ""
echo "Compiling library..."
wmake libso

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "============================================="
    echo "Compilation successful!"
    echo "Library created at: $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so"
    echo ""
    echo "Checking for PyJac symbols in the library:"
    nm -D $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep eval_h
    echo "============================================="
else
    echo ""
    echo "============================================="
    echo "Compilation failed!"
    echo "Please check the error messages above."
    echo "============================================="
    exit 1
fi