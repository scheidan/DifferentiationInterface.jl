module DifferentiationInterfaceTapirExt

using ADTypes: ADTypes, AutoTapir
import DifferentiationInterface as DI
using DifferentiationInterface: PullbackExtras
using Tapir:
    CoDual,
    NoTangent,
    build_rrule,
    increment!!,
    primal,
    set_to_zero!!,
    tangent,
    tangent_type,
    value_and_pullback!!,
    zero_codual,
    zero_tangent

DI.check_available(::AutoTapir) = true

include("onearg.jl")
include("twoarg.jl")

end
