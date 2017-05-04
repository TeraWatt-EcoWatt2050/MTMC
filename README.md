MTMC (Mike Turbine Mesh Correction) is a MATLAB package for performing a correction to improve the accuracy
of the modelling of tidal turbines in the MIKE 3 by DHI hydrodynamic modelling suite.

Author: Simon Waldman, Heriot-Watt University, 2015-2016.

See [1] for more information, especially on limitations.
If you use this package in work that leads to publication, a citation of [1] would be appreciated.
I would also appreciate hearing about your experience on smw13@hw.ac.uk.
The latest version of this package may be found at https://github.com/TeraWatt-EcoWatt2050/MTMC

Dependencies:
---
* MIKE Zero (or the MIKE SDK) must be installed on the computer.
* The MIKE Matlab toolbox (from DHI) must be on the Matlab path.
* The mike_tools package, available at https://github.com/TeraWatt-EcoWatt2050/MIKE_tools

How to install
---

To use a package of this type: Copy the whole folder `+MTMC` - *not* just
    the contents of the folder - into your MATLAB path. *Do not rename it*.
    Call functions from the package by prepending `MTMC.` to their names.

Example: If you keep your MATLAB scripts in D:\matlab-scripts\, then this could be
    in D:\matlab-scripts\+MTMC. D:\matlab-scripts would need to be on the path
    (or be the current directory) but D:\matlab-scripts\+MTMC would not need to be.

How to use
---

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

Versions used for publications & presentations
---

The version used for the EWTEC paper is tagged "EWTEC_paper".
This version also provided all figures for the EWTEC presentation except for the last, 
which came from the version tagged "EWTEC presentation".


[1] Waldman S, Genet G, Baston S and Side J (2015) Correcting for mesh size dependency
    in a regional model’s representation of tidal turbines. EWTEC conference 2015. 
    Available at: http://www.simonwaldman.me.uk/publications/2015/EWTEC_Correcting_for_mesh_size_dep.pdf
    Also included in this repo under "/publications/".



