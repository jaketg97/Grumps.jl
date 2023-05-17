
 # set relative path of location of Grumps.jl; won't be needed 
 # once Julia is a formal package
push!(LOAD_PATH, "../../src")                              



using Grumps, LinearAlgebra


# set the number of BLAS threads

function myprogram( nodes, draws, meth, varopt  )
    # set which files contain the data to be used
    s = Sources(                                                            
      consumers = "example_consumers.csv",
      products = "example_products.csv",
      marketsizes = "example_marketsizes.csv",
      draws = "example_draws.csv"  
    )
    
    # set the specification to be used
    v = Variables( 
        # these are the z_{im} * x_{jm} terms in the paper                                                         
        interactions =  [                                                   
            :income :constant; 
            :income :ibu; 
            :age :ibu
            ],
        # these are the x_{jm} * ν terms in the paper
        randomcoefficients =  [:ibu; :abv],     
        # these are the x_{jm} terms in the paper                            
        regressors =  [ :constant; :ibu; :abv ],      
        # these are the b_{jm} terms in the paper                      
        instruments = [ :constant; :ibu; :abv; :IVgh_ibu; :IVgh_abv ], 
        # these are not needed for the estimators in the paper, just for GMM     
        microinstruments = [                                                
            :income :constant; 
            :income :ibu; 
            :age :ibu
            ],
        # this is the label used for the outside good
        outsidegood = "product 11"                                          
    )
    
    # these are the data storage options; since these are the defaults, 
    # this can be omitted
    # dop = DataOptions( 1.0 * I, VarξClustering( :market ) )  
    dop = DataOptions( 1.0 * I, varopt )  

    # these are the defaults so this line can be omitted, albeit that the default 
    # number of nodes is small
    ms = DefaultMicroIntegrator(  ) 
    # these are the defaults so this line can be omitted, albeit that the default 
    # number of draws is small                                   
    Ms = DefaultMacroIntegrator(  )                                    

    # creates an estimator object
    e = Estimator( meth )                                                     

    # this puts the data into a form Grumps can process
    d = Data( e, s, v; options = dop, replicable = true ) 
    # there are longhand forms if you wish to set additional parameters
    # d = Data( e, s, v, BothIntegrators( ms, Ms ); threads = 32 )            

    # no need to set this unless you wish to save memory, will not exceed number 
    # of threads Julia is started with
    # th = Grumps.GrumpsThreads( ; markets = 32 )                             

    # redundant unless you wish to save memory
    # o = Grumps.OptimizationOptions(; memsave = true, threads = th )         

    # redundant unless you wish to have standard errors on objects other than β,θ 
    # seo = StandardErrorOptions(; δ = true )                                 

    # compute estimates using automatic starting values
    sol = grumps!( e, d )       
    println( sol )    
    # println( Matrix( Grumps.Vξ( sol) ) )
    dop2 = DataOptions( Vξ( sol ), varopt )
    # dop2 = DataOptions( 1.0 * I )
    d2 = Data( e, s, v; options = dop2, replicable = true )
    sol2 = grumps!( e, d2, getθcoef( sol ) )
    # long version to set more options                                          
    # sol = grumps!( e, d, o, nothing, seo  )                                 
    return sol2
end


for nodes ∈ [ 11 ] # , 17, 25]
    for draws ∈ [ 10_000 ]  # , 100_000 ]
        # other descriptive strings are allowed, as are the exact symbols
        for meth ∈ [ "cheap" ]         
            # run the program
            count = 0
            for varopt ∈ [ VarξHomoskedastic(), VarξHeteroskedastic(), VarξClustering( :market ) ]
                count += 1
                sol = myprogram( nodes, draws, meth, varopt ) 
                # get the θ coefficients only 
                println( getθcoef( sol ), "\n" )
                # get the minimum only
                println( Grumps.minimum( sol ) )
                # print the entire solution
                println( sol, "\n" )
                # save the results to a CSV file
                Save( "_results_$(meth)_$(nodes)_$(draws)_$(count).csv", sol )
            end
        end
    end
end


# 

