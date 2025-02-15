## Docstrings

"""
    prepare_derivative(f,     backend, x) -> extras
    prepare_derivative(f!, y, backend, x) -> extras

Create an `extras` object subtyping [`DerivativeExtras`](@ref) that can be given to derivative operators.

Beware that in the two-argument case, `y` is mutated by `f!` during preparation.
"""
function prepare_derivative end

"""
    value_and_derivative(f,     backend, x, [extras]) -> (y, der)
    value_and_derivative(f!, y, backend, x, [extras]) -> (y, der)
"""
function value_and_derivative end

"""
    value_and_derivative!(f,     der, backend, x, [extras]) -> (y, der)
    value_and_derivative!(f!, y, der, backend, x, [extras]) -> (y, der)
"""
function value_and_derivative! end

"""
    derivative(f,     backend, x, [extras]) -> der
    derivative(f!, y, backend, x, [extras]) -> der
"""
function derivative end

"""
    derivative!(f,     der, backend, x, [extras]) -> der
    derivative!(f!, y, der, backend, x, [extras]) -> der
"""
function derivative! end

## Preparation

"""
    DerivativeExtras

Abstract type for additional information needed by derivative operators.
"""
abstract type DerivativeExtras <: Extras end

struct NoDerivativeExtras <: DerivativeExtras end

struct PushforwardDerivativeExtras{E<:PushforwardExtras} <: DerivativeExtras
    pushforward_extras::E
end

function prepare_derivative(f::F, backend::AbstractADType, x) where {F}
    dx = one(x)
    return PushforwardDerivativeExtras(prepare_pushforward(f, backend, x, dx))
end

function prepare_derivative(f!::F, y, backend::AbstractADType, x) where {F}
    dx = one(x)
    pushforward_extras = prepare_pushforward(f!, y, backend, x, dx)
    return PushforwardDerivativeExtras(pushforward_extras)
end

## One argument

function value_and_derivative(
    f::F,
    backend::AbstractADType,
    x,
    extras::DerivativeExtras=prepare_derivative(f, backend, x),
) where {F}
    return value_and_pushforward(f, backend, x, one(x), extras.pushforward_extras)
end

function value_and_derivative!(
    f::F,
    der,
    backend::AbstractADType,
    x,
    extras::DerivativeExtras=prepare_derivative(f, backend, x),
) where {F}
    return value_and_pushforward!(f, der, backend, x, one(x), extras.pushforward_extras)
end

function derivative(
    f::F,
    backend::AbstractADType,
    x,
    extras::DerivativeExtras=prepare_derivative(f, backend, x),
) where {F}
    return pushforward(f, backend, x, one(x), extras.pushforward_extras)
end

function derivative!(
    f::F,
    der,
    backend::AbstractADType,
    x,
    extras::DerivativeExtras=prepare_derivative(f, backend, x),
) where {F}
    return pushforward!(f, der, backend, x, one(x), extras.pushforward_extras)
end

## Two arguments

function value_and_derivative(
    f!::F,
    y,
    backend::AbstractADType,
    x,
    extras::DerivativeExtras=prepare_derivative(f!, y, backend, x),
) where {F}
    return value_and_pushforward(f!, y, backend, x, one(x), extras.pushforward_extras)
end

function value_and_derivative!(
    f!::F,
    y,
    der,
    backend::AbstractADType,
    x,
    extras::DerivativeExtras=prepare_derivative(f!, y, backend, x),
) where {F}
    return value_and_pushforward!(f!, y, der, backend, x, one(x), extras.pushforward_extras)
end

function derivative(
    f!::F,
    y,
    backend::AbstractADType,
    x,
    extras::DerivativeExtras=prepare_derivative(f!, y, backend, x),
) where {F}
    return pushforward(f!, y, backend, x, one(x), extras.pushforward_extras)
end

function derivative!(
    f!::F,
    y,
    der,
    backend::AbstractADType,
    x,
    extras::DerivativeExtras=prepare_derivative(f!, y, backend, x),
) where {F}
    return pushforward!(f!, y, der, backend, x, one(x), extras.pushforward_extras)
end
