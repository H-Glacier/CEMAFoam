/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     |
    \\  /    A nd           | CEMAFoam
     \\/     M anipulation  |
-------------------------------------------------------------------------------
    Copyright (C) CEMAFoam contributors

    This file provides dummy implementations of PyJac functions for testing.
    Replace this with actual PyJac-generated code for production use.
\*---------------------------------------------------------------------------*/

#include <string.h>
#include <math.h>
#include "../pyjacInclude/header.h"
#include "../pyjacInclude/mechanism.h"

// Dummy implementation for species enthalpy of formation
void eval_h(const double T, double* h) {
    // Temporary implementation: return approximate values
    // These should be replaced with actual PyJac-generated values
    for(int i = 0; i < NSP; i++) {
        h[i] = -1000.0 * (i + 1);  // Dummy values
    }
}

// Dummy implementation for species internal energy
void eval_u(const double T, double* u) {
    for(int i = 0; i < NSP; i++) {
        u[i] = -900.0 * (i + 1);  // Dummy values
    }
}

// Dummy implementation for species heat capacity at constant volume
void eval_cv(const double T, double* cv) {
    for(int i = 0; i < NSP; i++) {
        cv[i] = 1000.0 + 10.0 * i;  // Dummy values
    }
}

// Dummy implementation for species heat capacity at constant pressure  
void eval_cp(const double T, double* cp) {
    for(int i = 0; i < NSP; i++) {
        cp[i] = 1200.0 + 10.0 * i;  // Dummy values
    }
}

// Dummy implementation for concentration evaluation
void eval_conc(const double T, const double P, 
               const double* Y, double* C, 
               double* RHO, double* RHOY, double* MW) {
    // Temporary implementation
    *RHO = P / (287.0 * T);  // Ideal gas approximation
    *MW = 28.97;  // Air molecular weight
    
    for(int i = 0; i < NSP; i++) {
        RHOY[i] = (*RHO) * Y[i];
        C[i] = RHOY[i] / (28.0 + i);  // Dummy molecular weights
    }
}

// Dummy implementation for concentration evaluation with density
void eval_conc_rho(const double T, const double RHO_in,
                   const double* Y, double* C,
                   double* P, double* RHOY, double* MW) {
    *P = RHO_in * 287.0 * T;  // Ideal gas
    *MW = 28.97;
    
    for(int i = 0; i < NSP; i++) {
        RHOY[i] = RHO_in * Y[i];
        C[i] = RHOY[i] / (28.0 + i);
    }
}

// Dummy implementation for time derivatives
void dydt(const double t, const double P, 
          const double* y, double* dy) {
    // Temporary implementation: return small change rates
    dy[0] = -0.001 * y[0];  // Temperature
    for(int i = 1; i < NN; i++) {
        dy[i] = -0.0001 * y[i];  // Species
    }
}

// Dummy implementation for Jacobian evaluation
void eval_jacob(const double t, const double P,
                const double* y, double* jac) {
    // Temporary implementation: return a simple diagonal matrix
    memset(jac, 0, NN * NN * sizeof(double));
    for(int i = 0; i < NN; i++) {
        jac[i * NN + i] = -0.001;  // Diagonal elements
    }
}

// Dummy implementation for CEMA
void cema(double* cem) {
    *cem = 1.0e-6;  // Dummy explosive mode
}

// Additional functions that might be needed
void set_same_initial_conditions(int n, double** y1, double** y2) {
    // Copy initial conditions
    for(int i = 0; i < n; i++) {
        for(int j = 0; j < NN; j++) {
            y2[i][j] = y1[i][j];
        }
    }
}

void apply_mask(double* y) {
    // No-op for dummy implementation
}

void apply_reverse_mask(double* y) {
    // No-op for dummy implementation
}