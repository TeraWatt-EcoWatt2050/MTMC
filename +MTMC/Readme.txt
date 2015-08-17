MTMC (Mike Turbine Mesh Correction) is a package for performing a correction to improve the accuracy
of the modelling of tidal turbines in the MIKE3 by DHI 
hydrodynamic modelling suite.

Author: Simon Waldman, Heriot-Watt University, Jan/Feb 2015.

See (FIXME: CITE PAPER HERE) for more information.
If you use this package in work that leads to publication, 
a citation would be appreciated.

How to use:
1. Set up model in MIKE3, giving turbines a fixed correction factor of 1 (as per default).
    The thrust curve should be specified using the "Tabulated drag and lift
    coefficient" option, even if it is constant. The mesh must use cartesian (not 
    spherical / lonlat) coordinates.
2. Run the model, making sure that you have enabled Turbine Outputs. These
    are needed to provide this package with prior flow speed and direction information.
3. Run MTMC.MakeCorrection. This function takes five inputs which are filenames - 
    see the function's header for more info. This will produce a .dfs0 file
    of correction factors for each turbine and each timestep, and will modify
    the model definition file to point to this.
4. Run the model again.

Optionally, run MTMC.MakeCorrection and the model further times until an acceptable
convergence is reached. This should only be necessary if using a variable thrust
coefficient (because the flow speed and thrust coefficient both depend on one 
another).