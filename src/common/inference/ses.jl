




# these are defaults and may be overwritten elsewhere
Meat( :: GrumpsEstimator, ::Val{:θθ}, ing :: GrumpsIngredients{T} ) where {T<:Flt} = ing.Ωθθ
Meat( :: GrumpsEstimator, ::Val{:δθ}, m :: Int, ing :: GrumpsIngredients{T}  ) where {T<:Flt} = ing.Ωδθ[m]
Meat( e, ::Val{:θδ}, m, ing ) = Meat( e, Val(:δθ), m, ing )'

function Meat( :: GrumpsEstimator, ::Val{:δδ}, m :: Int, m2 :: Int, ing :: Ingredients{T}  ) where {T<:Flt} 
    R = ing.K[m] * ing.KVK * ing.K[m2]'
    m == m2 || return R
    return R + ing.Ωδδ[m]
end




Bread( :: GrumpsEstimator, ::Val{:θθ}, ing :: GrumpsIngredients{T} ) where {T<:Flt} = ing.Hinvθθ

function Bread( :: GrumpsEstimator, ::Val{:δθ}, m :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt}
    Q = sum( ing.K[m2]' * ing.ΩδδinvΩδθ[m2] for m2 ∈  eachindex( ing.K ) )
    return - ( ing.ΩδδinvΩδθ[m] - ing.Ωδδinv[m] * ing.K[m] * ing.Δ * Q ) * ing.Hinvθθ
end

function Bread( :: GrumpsEstimator, ::Val{:δδ}, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt}
    R = ing.AinvB[m] * ing.Xstar * ing.AinvB[m2]' -
        ing.AinvC[m] * ing.Ystar * ing.AinvC[m2]' -
        ing.AinvB[m] * ing.Zstar * ing.AinvC[m2]' -
        ing.AinvC[m] * (ing.Zstar') * ing.AinvB[m2]'
    m == m2 || return R
    return R + ing.Ωδδinv[m]
end

Bread( e, ::Val{:θδ}, m, ing  ) = Bread( e, Val(:δθ), m, ing )'




function Meat( e, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt}
    m == 0 && m2 == 0 && return Meat( e, Val( :θθ ), ing )
    m == 0 && 1 ≤ m2 ≤ dimM( ing ) && return Meat( e, Val( :θδ ), m2, ing )
    1 ≤ m ≤ dimM( ing ) && 1 ≤ m2 ≤ dimM( ing ) && return Meat( e, Val( :δδ ), m, m2, ing )
    1 ≤ m ≤ dimM( ing ) && m2 == 0 && return Meat( e, Val( :δθ ), m, ing )
    @ensure false "internal error:  m should be between 0 and M  inclusive" 
end

function Bread( e :: GrumpsEstimator, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt}
    m == 0 && m2 == 0 && return Bread( e, Val( :θθ ), ing )
    m == 0 && 1 ≤ m2 ≤ dimM( ing ) && return Bread( e, Val( :θδ ), m2, ing )
    1 ≤ m ≤ dimM( ing ) && 1 ≤ m2 ≤ dimM( ing ) && return Bread( e, Val( :δδ ), m, m2, ing )
    1 ≤ m ≤ dimM( ing ) && m2 == 0 && return Bread( e, Val( :δθ ), m, ing )
    @ensure false "internal error:  m should be between 0 and M inclusive" 
end

function VarEst( e :: GrumpsEstimator, ::Val{ :ββ }, ing :: GrumpsIngredients{T} ) where {T<:Flt}
    markets = 1:dimM( ing );  markets0 = 0:dimM( ing )
    ΞAδθ = sum( ing.Ξ[m] * Bread( e, m, 0, ing ) for m ∈ markets )
    ΞAδδ = [ sum( ing.Ξ[m] * Bread( e, m, m2, ing ) for m ∈ markets ) for m2 ∈ markets ]
    V = ing.ΞVΞ
    if typeof( e ) <: GrumpsPenalized 
        V -= let ΞAK = sum( ΞAδδ[m]  * ing.K[m] for m ∈ markets )
                ΞAK * ing.KVΞ + ing.KVΞ' * ΞAK'
             end
    end
    V += ΞAδθ * Meat( e, 0, 0, ing ) * ΞAδθ'
    for m ∈ markets
        V +=  let C = ΞAδθ * Meat( e, 0, m, ing ) * ΞAδδ[m]'
                C + C'
              end
    end
    V += sum( ΞAδδ[m] * Meat( e, m, m2, ing ) * ΞAδδ[m2]' for m ∈ markets, m2 ∈ markets )
    return V
end



function VarEstβhelper( e :: GrumpsEstimator, mstar :: Int , ing :: GrumpsIngredients{T} ) where {T<:Flt}
    return  sum(   
        sum( Bread( e, mstar, m, ing ) * Meat( e, m, m2, ing ) for m ∈ 0 : dimM( ing ) ) * 
        sum( Bread( e, m2, m, ing ) * ing.Ξ[m]' for m ∈ 0 : dimM( ing ) )
        for m2 ∈ 0 : dimM( ing )
        )
end


VarEst( e :: GrumpsEstimator, ::Val{:θβ}, ing :: GrumpsIngredients{T} ) where {T<:Flt} = VarEstβhelper( e, 0, ing )
VarEst( e :: GrumpsEstimator, ::Val{:δβ}, mstar :: Int, ing :: GrumpsIngredients{T} ) where {T<:Flt} = VarEstβhelper( e, mstar, ing ) - sum( Bread( e, mstar, m, ing ) * ing.K[m] for m ∈ 1:dimM( ing ) ) * ing.ΞVK'
VarEst( e, ::Val{:βδ}, m, ing ) = VarEst( e, Val( :δβ ), m, ing )'



function VarEst( e :: GrumpsEstimator, m :: Int, m2 :: Int, ing :: GrumpsIngredients{T} )  where {T<:Flt}
    M = dimM( ing )
    m2 < m && return VarEst( e, m2, m, ing )'
    0 ≤ m ≤ m2 ≤ M && return sum( Bread( e, m, i, ing ) * Meat( e, i, j, ing ) * Bread( e, j, m, ing ) for i ∈ 0:M, j ∈ 0:M ) 
    m == m2 == M + 1 && return VarEst( e, Val( :ββ ), ing ) 
    0 == m && m2 == M + 1 && return VarEst( e, Val( :θβ ), ing ) 
    1 ≤ m ≤ M && m2 == M + 1 && return VarEst( e, Val( :δβ ), ing ) 
    @ensure false "m and m2 should be between 0 and M+1 inclusive"
end


VarEst( e :: GrumpsEstimator, ::Val{:θθ}, ing ::GrumpsIngredients{T} ) where {T<:Flt} = VarEst( e, 0, 0, ing )
VarEst( e :: GrumpsEstimator, ::Val{:δθ}, m :: Int, ing ::GrumpsIngredients{T} ) where {T<:Flt} = VarEst( e, m, 0, ing )
VarEst( e :: GrumpsEstimator, ::Val{:θδ}, m :: Int, ing ::GrumpsIngredients{T} ) where {T<:Flt} = VarEst( e, 0, m, ing )

function sqrt_robust( v :: T ) where {T<:Flt}
    try sqrt( v )
    catch
        NaN
    end
end

function se( e, ing :: GrumpsIngredients{T}, m :: Int ) where {T<:Flt}
    @time V = VarEst( e, m, m, ing );  println( "Varest $m $m" )
    return [ sqrt_robust( V[j,j] ) for j ∈ axes( V, 1 ) ]
end


se( e, ing :: GrumpsIngredients{T}, ::Val{:β} ) where {T<:Flt} = se( e, ing, dimM( ing ) + 1 )
se( e, ing :: GrumpsIngredients{T}, ::Val{:θ} ) where {T<:Flt} = se( e, ing, 0 )
se( e, ing :: GrumpsIngredients{T}, ::Val{:δ} ) where {T<:Flt} = vcat( [ se( e, ing, m ) for m ∈ 1:dimM( ing ) ]... )


function ses!( sol :: Solution{T}, e :: GrumpsEstimator, d :: GrumpsData{T}, f :: FGH{T}, seo :: StandardErrorOptions ) where {T<:Flt}
    seo.computeβ || seo.computeθ || seo.computeδ || return nothing
    @time ing = Ingredients( sol, Val( seprocedure( e ) ), d , f, seo  ); println( "(ingredients computation) ");
    ing == nothing && return nothing
    
    @time for ( ψ, computeψ, solψ ) ∈ [ (:θ, seo.computeθ, sol.θ), (:β,seo.computeβ,sol.β), (:δ,seo.computeδ,sol.δ) ]
        computeψ || continue
        local seψ = se( e, ing, Val( ψ ) )
        @assert length( seψ ) == length( solψ )
        for j ∈ eachindex( seψ )
            solψ[j].stde = seψ[j]
            solψ[j].tstat = solψ[j].coef / solψ[j].stde
        end
    end
    println( " (for loop)" )
    return nothing
end

