# APC2BEM
Utility to convert [APC propeller geometry](https://www.apcprop.com/technical-information/file-downloads/) files to OpenVSP BEM format

## Installation
In Julia, enter the package manager by typing `]` and then run the following:
```
pkg> add ArgParse
pkg> add Interpolations
```

## Usage
```
> julia apc2bem.jl 19x12E-PERF.PE0 19x12E-PERF.BEM
```

By default, units are in `inches`, but a scale factor option `-s` can be provided to convert to another unit, eg. to `cm`:
```
> julia apc2bem.jl -s 2.54 19x12E-PERF.PE0 19x12E-PERF.BEM
```

### Importing in OpenVSP
After importing the `BEM` file into OpenVSP, set the following *Propeller* ⎡*Design*⎤ properties:
* *Construction X/C* `0.000`
* *Feather Axis* `0.125`

And set the *Propeller* ⎡*XSec*⎤ properties according to the `PE0` file.
```
       ----- AIRFOIL SECTIONS -----

 AIRFOIL1:      , E63         (Transition Start, Airfoil 1)
 AIRFOIL2:      , APC12       (Transition End, Airfoil 2)

 AIRFOILS ARE SCALED BASED ON THICKNESS RATIO IN TABLE ABOVE.

 NOTE: APC12 airfoil is equivalent to NACA 4412
```

AF coordinates can be downloaded from the UIUC Airfoil website:
* [E63](https://m-selig.ae.illinois.edu/ads/coord/e63.dat)
* [APC12/NACA 4412](https://m-selig.ae.illinois.edu/ads/coord/naca4412.dat) - alternatively can be created in OpenVSP as *FOUR_SERIES* airfoil
