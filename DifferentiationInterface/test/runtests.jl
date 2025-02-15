include("test_imports.jl")

## Main tests

@testset verbose = true "DifferentiationInterface.jl" begin
    @testset verbose = true "Formal tests" begin
        @testset "Aqua" begin
            Aqua.test_all(
                DifferentiationInterface;
                ambiguities=false,
                deps_compat=(check_extras = false),
            )
        end
        @testset "JuliaFormatter" begin
            @test JuliaFormatter.format(
                DifferentiationInterface; verbose=false, overwrite=false
            )
        end
        @testset verbose = true "JET" begin
            JET.test_package(DifferentiationInterface; target_defined_modules=true)
        end
    end

    Documenter.doctest(DifferentiationInterface)

    @testset verbose = true "First order" begin
        include("first_order.jl")
    end

    @testset verbose = true "Second order" begin
        include("second_order.jl")
    end

    @testset verbose = true "Sparsity" begin
        include("sparsity.jl")
    end

    @testset verbose = true "DifferentiateWith" begin
        include("differentiate_with.jl")
    end

    @testset verbose = true "Bonus round" begin
        @testset "Type stability" begin
            include("bonus/type_stability.jl")
        end

        @testset "Efficiency" begin
            include("bonus/efficiency.jl")
        end

        @testset "Weird arrays" begin
            include("bonus/weird_arrays.jl")
        end
    end

    @testset verbose = true "Internals" begin
        @testset verbose = true "Exception handling" begin
            include("internals/exceptions.jl")
        end

        @testset "Chunks" begin
            include("internals/chunk.jl")
        end

        @testset "Matrices" begin
            include("internals/matrices.jl")
        end

        @testset verbose = true "Coloring" begin
            include("internals/coloring.jl")
        end
    end
end;
