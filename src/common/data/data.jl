for fn ∈ [ "show", "balance", "names", "micro", "macro", "K", "plm", "callbacks", "assist", "all", "dims" ]
    include( "$(fn).jl")
end

@todo 2 "data processing takes longer than it probably should"