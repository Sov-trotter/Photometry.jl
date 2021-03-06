APERTURES = [
    CircularAperture,
    CircularAnnulus
]

PARAMS = [
    (3),
    (3, 5)
]

###########################
# Some helpers for testing
area(c::CircularAperture) = π * c.r^2
area(c::CircularAnnulus) = π * (c.r_out^2 - c.r_in^2)


@testset "outside - $AP" for (AP, params) in zip(APERTURES, PARAMS)
    data = ones(10, 10)
    aperture = AP(-60, 60, params...)
    @test aperture_photometry(aperture, data).aperture_sum ≈ 0
end

@testset "inside zeros - $AP" for (AP, params) in zip(APERTURES, PARAMS)
    data = zeros(40, 40)
    aperture = AP(20.0, 20.0, params...)

    table_cent = aperture_photometry(aperture, data, method = :center)
    table_sub = aperture_photometry(aperture, data, method = (:subpixel, 10))
    table_ex = aperture_photometry(aperture, data, method = :exact)


    @test table_ex.aperture_sum ≈ 0
    @test table_sub.aperture_sum ≈ 0
    @test table_cent.aperture_sum ≈ 0
    
end

@testset "inside ones - $AP" for (AP, params) in zip(APERTURES, PARAMS)
    data = ones(40, 40)
    aperture = AP(20.0, 20.0, params...)

    table_cent = aperture_photometry(aperture, data, method = :center)
    table_sub = aperture_photometry(aperture, data, method = (:subpixel, 10))
    table_ex = aperture_photometry(aperture, data, method = :exact)

    true_flux = area(aperture)

    @test table_ex.aperture_sum ≈ true_flux
    @test table_sub.aperture_sum ≈ table_ex.aperture_sum atol = 0.1
    @test table_cent.aperture_sum < table_ex.aperture_sum
    
end

function test_aperture(data, aperture)
    error = ones(size(data))

    table_cent = aperture_photometry(aperture, data, error, method = :center)
    table_sub = aperture_photometry(aperture, data, error, method = (:subpixel, 12))
    table_ex = aperture_photometry(aperture, data, error, method = :exact)

    true_flux = area(aperture)
    true_err = sqrt(true_flux)

    @test table_ex.aperture_sum ≈ true_flux
    @test table_sub.aperture_sum ≈ table_ex.aperture_sum atol = 0.1
    @test table_cent.aperture_sum < table_ex.aperture_sum

    @test table_ex.aperture_sum_err ≈ true_err
    @test table_sub.aperture_sum_err ≈ table_ex.aperture_sum_err atol = 0.1
    @test table_cent.aperture_sum_err < table_ex.aperture_sum_err
end

@testset "errors - CircularAperture" begin
    data = ones(40, 40)
    aperture = CircularAperture(20, 20, 10)
    test_aperture(data, aperture)

    # apertures = [aperture, CircularAperture(25, 25, 10)]
    # test_aperture(data, apertures)
end

@testset "errors - CircularAnnulus" begin
    data = ones(40, 40)
    aperture = CircularAnnulus(20, 20, 8, 10)
    test_aperture(data, aperture)

    # apertures = [aperture, CircularAnnulus(25, 25, 8, 10)]
    # test_aperture(data, apertures)
end

@testset "partial overlap" begin
    data = ones(20, 20)
    error = ones(size(data))
    positions = [10.5 10.5; 1 1; 1 20; 20 1; 20 20]
    apertures = [CircularAperture(positions[i, :], 5) for i in axes(positions, 1)]

    table = aperture_photometry(apertures, data, error)
    @test table.aperture_sum[1] ≈ 25π
    @test all(table.aperture_sum[2:end] .< 25π)
end
