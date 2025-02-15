coloring_algorithm = DI.GreedyColoringAlgorithm()
sparsity_detector = DI.SymbolicsSparsityDetector()

sparse_backends = [
    AutoSparse(AutoFastDifferentiation()),
    AutoSparse(AutoSymbolics()),
    AutoSparse(AutoForwardDiff(); sparsity_detector, coloring_algorithm),
    AutoSparse(AutoEnzyme(Enzyme.Reverse); sparsity_detector, coloring_algorithm),
]

sparse_second_order_backends = [
    AutoSparse(AutoFastDifferentiation()),
    AutoSparse(AutoSymbolics()),
    AutoSparse(
        SecondOrder(AutoForwardDiff(), AutoZygote()); sparsity_detector, coloring_algorithm
    ),
]

for backend in vcat(sparse_backends, sparse_second_order_backends)
    @test check_available(backend)
end

test_differentiation(
    sparse_backends,
    sparse_scenarios();
    sparsity=true,
    second_order=false,
    logging=get(ENV, "CI", "false") == "false",
)

test_differentiation(
    sparse_second_order_backends,
    sparse_scenarios();
    sparsity=true,
    first_order=false,
    logging=get(ENV, "CI", "false") == "false",
)
