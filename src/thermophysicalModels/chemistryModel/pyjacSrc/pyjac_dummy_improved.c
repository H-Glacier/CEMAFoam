/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     |
    \\  /    A nd           | CEMAFoam
     \\/     M anipulation  |
-------------------------------------------------------------------------------
    Copyright (C) CEMAFoam contributors

    Improved dummy implementation of PyJac functions for testing CEMA.
    This version provides temperature-dependent values for more realistic testing.
\*---------------------------------------------------------------------------*/

#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "header.h"
#include "mechanism.h"
#include "chem_utils.h"

// Global variable to track temperature (for testing only!)
static double last_temperature = 300.0;

// Dummy implementation for species enthalpy of formation
void eval_h(const double T, double* h) {
    // Store temperature for use in other functions
    last_temperature = T;
    
    // Return temperature-dependent values
    for(int i = 0; i < NSP; i++) {
        h[i] = -1000.0 * (i + 1) * (1500.0 / T);
    }
}

// Dummy implementation for species internal energy
void eval_u(const double T, double* u) {
    last_temperature = T;
    for(int i = 0; i < NSP; i++) {
        u[i] = -900.0 * (i + 1) * (1500.0 / T);
    }
}

// Dummy implementation for species heat capacity at constant volume
void eval_cv(const double T, double* cv) {
    last_temperature = T;
    for(int i = 0; i < NSP; i++) {
        cv[i] = 1000.0 + 10.0 * i * (T / 300.0);
    }
}

// Dummy implementation for species heat capacity at constant pressure
void eval_cp(const double T, double* cp) {
    last_temperature = T;
    for(int i = 0; i < NSP; i++) {
        cp[i] = 1200.0 + 10.0 * i * (T / 300.0);
    }
}

// Dummy implementation for concentration evaluation
void eval_conc(const double T, const double P, 
               const double* Y, double* C, 
               double* RHO, double* RHOY, double* MW) {
    last_temperature = T;
    *RHO = P / (287.0 * T);
    *MW = 28.97;
    
    for(int i = 0; i < NSP; i++) {
        RHOY[i] = (*RHO) * Y[i];
        C[i] = RHOY[i] / (28.0 + i);
    }
}

// Dummy implementation for concentration evaluation with density
void eval_conc_rho(const double T, const double RHO_in,
                   const double* Y, double* C,
                   const double* P, double* RHOY, double* MW) {
    last_temperature = T;
    *P = RHO_in * 287.0 * T;
    *MW = 28.97;
    
    for(int i = 0; i < NSP; i++) {
        RHOY[i] = RHO_in * Y[i];
        C[i] = RHOY[i] / (28.0 + i);
    }
}

// Improved dummy implementation for time derivatives
void dydt(const double t, const double P, 
          const double* y, double* dy) {
    // y[0] is temperature
    double T = y[0];
    last_temperature = T;
    
    // Temperature-dependent reaction rates
    double rate_factor = 0.0;
    if (T > 1500.0) {
        rate_factor = 1000.0 * exp((T - 1500.0) / 200.0);
    } else if (T > 1000.0) {
        rate_factor = 0.1 * (T - 1000.0) / 500.0;
    } else {
        rate_factor = -0.001;
    }
    
    // Temperature derivative
    dy[0] = rate_factor * 0.01;
    
    // Species derivatives
    for(int i = 1; i < NN; i++) {
        dy[i] = -rate_factor * y[i] * 0.001;
    }
}

// Improved dummy implementation for Jacobian evaluation
void eval_jacob(const double t, const double P,
                const double* y, double* jac) {
    // y[0] is temperature
    double T = y[0];
    last_temperature = T;
    
    // Clear matrix
    memset(jac, 0, NN * NN * sizeof(double));
    
    // Temperature-dependent eigenvalues
    double max_eigenvalue = 0.0;
    
    if (T > 1800.0) {
        // Strong explosive mode
        max_eigenvalue = 1.0e7 * (T / 1800.0);
    } else if (T > 1500.0) {
        // Moderate explosive mode
        max_eigenvalue = 1.0e5 * ((T - 1500.0) / 300.0);
    } else if (T > 1200.0) {
        // Weak explosive mode
        max_eigenvalue = 1.0e3 * ((T - 1200.0) / 300.0);
    } else if (T > 1000.0) {
        // Near neutral
        max_eigenvalue = -1.0e2 + 100.0 * ((T - 1000.0) / 200.0);
    } else {
        // Stable
        max_eigenvalue = -1.0e4 * (1500.0 / T);
    }
    
    // Set diagonal elements with varying eigenvalues
    for(int i = 0; i < NN; i++) {
        if (i < 3) {
            // First few modes are most explosive
            jac[i * NN + i] = max_eigenvalue * (1.0 - 0.1 * i);
        } else {
            // Other modes are stable
            jac[i * NN + i] = -1.0e3 - 100.0 * i;
        }
    }
    
    // Add some off-diagonal elements for coupling
    for(int i = 1; i < NN; i++) {
        jac[i * NN + i-1] = -50.0;
        jac[(i-1) * NN + i] = -50.0;
    }
}

// Improved dummy implementation for CEMA
void cema(double* cem) {
    // Use the stored temperature to compute CEM
    double T = last_temperature;
    
    if (T > 1800.0) {
        // Strong explosive mode
        *cem = 1.0e7 * (T / 1800.0);
    } else if (T > 1500.0) {
        // Moderate explosive mode
        *cem = 1.0e5 * ((T - 1500.0) / 300.0);
    } else if (T > 1200.0) {
        // Weak explosive mode
        *cem = 1.0e3 * ((T - 1200.0) / 300.0);
    } else if (T > 1000.0) {
        // Transition region
        *cem = -1.0e2 + 100.0 * ((T - 1000.0) / 200.0);
    } else {
        // Stable region
        *cem = -1.0e4 * (1500.0 / T);
    }
    
    // Add some random variation for testing (±10%)
    double variation = ((double)rand() / RAND_MAX - 0.5) * 0.2;
    *cem = *cem * (1.0 + variation);
}

// Additional functions
void set_same_initial_conditions(int n, double** y1, double** y2) {
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