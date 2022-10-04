using DelimitedFiles
using ArgParse
using Printf
using Interpolations

s = ArgParseSettings()
@add_arg_table s begin
    "--scale", "-s"
        help = "scale factor from inches"
        arg_type = Float64
        default = 1.0
    "input"
        help = "input PE0 file"
        arg_type = String
        required = true
    "output"
        help = "output VSP BEM file"
        arg_type = String
        required = true
end

parsed_args = parse_args(s)

infile = parsed_args["input"]
outfile = parsed_args["output"]

scale = parsed_args["scale"]

open(infile, "r") do io
    readuntil(io, "(IN)       (IN)       (QUOTED)    (LE-TE)     (PRATHER)      (IN)     RATIO         (DEG)       (IN)      (IN**2)      (IN)         (IN)         (IN)")
    geom_data = Vector{UInt8}(strip(readuntil(io, "RADIUS: ")))
    global apc = readdlm(geom_data, Float64)

    global R = parse(Float64, strip(readuntil(io, "PROPELLER RADIUS (IN)")))

    readuntil(io, "BLADES:")
    global num_blade = parse(Int, strip(readuntil(io, "NUMBER OF BLADES")))
end

num_sections = size(apc, 1)
# STATION     CHORD       PITCH       PITCH        PITCH       SWEEP    THICKNESS      TWIST      MAX-THICK  CROSS-SECTION ZHIGH       CGY          CGZ                        
# (IN)       (IN)       (QUOTED)    (LE-TE)     (PRATHER)      (IN)     RATIO         (DEG)       (IN)      (IN**2)      (IN)         (IN)         (IN)  
station = apc[:,1] # STATION (IN)
radius_R = station/R

chord = apc[:,2] # CHORD (IN)
chord_R = chord/R

sweep = apc[:,6] # SWEEP (IN)
# NOTE: SWEEP IS DEFINED WITH (MOLD) LE PARTING LINE.
skew_R = -sweep/R

t_c = apc[:,7] # THICKNESS RATIO
twist_deg = apc[:,8] # TWIST (DEG)

rake_R = zeros(num_sections)
sweep_deg = zeros(num_sections)
CLi = zeros(num_sections)
axial = zeros(num_sections)
tangential = zeros(num_sections)

# Radius/R, Chord/R, Twist (deg), Rake/R, Skew/R, Sweep, t/c, CLi, Axial, Tangential
bem = [radius_R chord_R twist_deg rake_R skew_R sweep_deg t_c CLi axial tangential]

linterp(A, B, at) = interpolate((A,), B, Gridded(Linear()))[at]

diameter = 2*R*scale
beta3_4 = linterp(radius_R, twist_deg, 0.75)
feather = 0.0
pre_cone = 0.0
center = [0.0, 0.0, 0.0]
normal = [-1.0, 0.0, 0.0]

function writemat(io::IO, a::Matrix{<:AbstractFloat})
    lastc = last(axes(a, 2))
    for i = axes(a, 1)
        for j = axes(a, 2)
            @printf io "%.8f" a[i,j]
            j == lastc ? print(io, '\n') : print(io, ", ")
        end
    end
end

open(outfile, "w") do io
    println(io, "...BEM Propeller...")
    @printf io "Num_Sections: %i\n" num_sections
    @printf io "Num_Blade: %i\n" num_blade
    @printf io "Diameter: %.8f\n" diameter
    @printf io "Beta 3/4 (deg): %.8f\n" beta3_4
    @printf io "Feather (deg): %.8f\n" feather
    @printf io "Pre_Cone (deg): %.8f\n" pre_cone
    @printf io "Center: %.8f, %.8f, %.8f\n" center[1] center[2] center[3]
    @printf io "Normal: %.8f, %.8f, %.8f\n" normal[1] normal[2] normal[3]
    println(io)

    println(io, "Radius/R, Chord/R, Twist (deg), Rake/R, Skew/R, Sweep, t/c, CLi, Axial, Tangential")
    writemat(io, bem)
end

println("After importing BEM file, set the following properties:")
println("Construction X/C: 0.000")
println("    Feather Axis: 0.125")
