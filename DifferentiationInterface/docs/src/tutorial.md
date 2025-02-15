```@meta
CurrentModule = Main
```

# Tutorial

We present a typical workflow with DifferentiationInterface.jl and showcase its potential performance benefits.

```@example tuto
using DifferentiationInterface
```

## Computing a gradient

A common use case of automatic differentiation (AD) is optimizing real-valued functions with first- or second-order methods.
Let's define a simple objective and a random input vector

```@example tuto
f(x) = sum(abs2, x)

x = collect(1.0:5.0)
```

To compute its gradient, we need to choose a "backend", i.e. an AD package to call under the hood.
Most backend types are defined by [ADTypes.jl](https://github.com/SciML/ADTypes.jl) and re-exported by DifferentiationInterface.jl.

[ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) is very generic and efficient for low-dimensional inputs, so it's a good starting point:

```@example tuto
import ForwardDiff

backend = AutoForwardDiff()
nothing # hide
```

!!! tip
    To avoid name conflicts, load AD packages with `import` instead of `using`.
    Indeed, most AD packages also export operators like `gradient` and `jacobian`, but you only want to use the ones from DifferentiationInterface.jl.

Now you can use the following syntax to compute the gradient:

```@example tuto
gradient(f, backend, x)
```

Was that fast?
[BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl) helps you answer that question.

```@example tuto
using BenchmarkTools

@benchmark gradient($f, $backend, $x)
```

Not bad, but you can do better.

## Overwriting a gradient

Since you know how much space your gradient will occupy (the same as your input `x`), you can pre-allocate that memory and offer it to AD.
Some backends get a speed boost from this trick.

```@example tuto
grad = similar(x)
gradient!(f, grad, backend, x)
grad  # has been mutated
```

The bang indicates that one of the arguments of `gradient!` might be mutated.
More precisely, our convention is that _every positional argument between the function and the backend is mutated (and the `extras` too, see below)_.

```@example tuto
@benchmark gradient!($f, _grad, $backend, $x) evals=1 setup=(_grad=similar($x))
```

For some reason the in-place version is not much better than your first attempt.
However, it makes fewer allocations, thanks to the gradient vector you provided.
Don't worry, you can get even more performance.

## Preparing for multiple gradients

Internally, ForwardDiff.jl creates some data structures to keep track of things.
These objects can be reused between gradient computations, even on different input values.
We abstract away the preparation step behind a backend-agnostic syntax:

```@example tuto
extras = prepare_gradient(f, backend, x)
nothing # hide
```

You don't need to know what this object is, you just need to pass it to the gradient operator.

```@example tuto
grad = similar(x)
gradient!(f, grad, backend, x, extras)
grad  # has been mutated
```

Preparation makes the gradient computation much faster, and (in this case) allocation-free.

```@example tuto
@benchmark gradient!($f, _grad, $backend, $x, _extras) evals=1 setup=(
    _grad=similar($x);
    _extras=prepare_gradient($f, $backend, $x)
)
```

Beware that the `extras` object is nearly always mutated by differentiation operators, even though it is given as the last positional argument.

## Switching backends

The whole point of DifferentiationInterface.jl is that you can easily experiment with different AD solutions.
Typically, for gradients, reverse mode AD might be a better fit, so let's try [ReverseDiff.jl](https://github.com/JuliaDiff/ReverseDiff.jl)!

For this one, the backend definition is slightly more involved, because you can specify whether the tape needs to be compiled:

```@example tuto
import ReverseDiff

backend2 = AutoReverseDiff(; compile=true)
nothing # hide
```

But once it is done, things run smoothly with exactly the same syntax:

```@example tuto
gradient(f, backend2, x)
```

And you can run the same benchmarks to see what you gained (although such a small input may not be realistic):

```@example tuto
@benchmark gradient!($f, _grad, $backend2, $x, _extras) evals=1 setup=(
    _grad=similar($x);
    _extras=prepare_gradient($f, $backend2, $x)
)
```

In short, DifferentiationInterface.jl allows for easy testing and comparison of AD backends.
If you want to go further, check out the [DifferentiationInterfaceTest.jl tutorial](https://gdalle.github.io/DifferentiationInterface.jl/DifferentiationInterfaceTest/dev/tutorial/).
It provides benchmarking utilities to compare backends and help you select the one that is best suited for your problem.

## [Handling sparsity](@id sparsity-tutorial)

To compute sparse Jacobians or Hessians, you need three ingredients (read [this survey](https://epubs.siam.org/doi/10.1137/S0036144504444711) to understand why):

1. A sparsity pattern detector
2. A coloring algorithm
3. An underlying AD backend

ADTypes.jl v1.0 defines the [`AutoSparse`](@ref) wrapper, which brings together these three ingredients.
At the moment, this new wrapper is not well-supported in the ecosystem, which is why DifferentiationInterface.jl provides the necessary objects to get you started:

1. [`DifferentiationInterface.SymbolicsSparsityDetector`](@ref) (requires [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl) to be loaded)
2. [`DifferentiationInterface.GreedyColoringAlgorithm`](@ref)

!!! warning
    These objects are not part of the public API, so they can change unexpectedly between versions.

!!! info
    The symbolic backends have built-in sparsity handling, so `AutoSparse(AutoSymbolics())` and `AutoSparse(AutoFastDifferentiation())` do not need additional configuration.

Here's an example:

```@example tuto
import Symbolics

sparsity_detector = DifferentiationInterface.SymbolicsSparsityDetector()
coloring_algorithm = DifferentiationInterface.GreedyColoringAlgorithm()
dense_backend = AutoForwardDiff()

sparse_backend = AutoSparse(dense_backend; sparsity_detector, coloring_algorithm)
```

See how the computed Hessian is sparse, whereas the underlying backend alone would give us a dense matrix:

```@example tuto
hessian(f, sparse_backend, x)
```

```@example tuto
hessian(f, dense_backend, x)
```

The sparsity detector and coloring algorithm are called during the preparation step, which can be fairly expensive.
If you plan to compute several Jacobians or Hessians with the same pattern but different input vectors, you should reuse the `extras` object created by `prepare_jacobian` or `prepare_hessian`.
After preparation, the sparse computation itself will be much faster than the dense one, and require fewer calls to the function. 