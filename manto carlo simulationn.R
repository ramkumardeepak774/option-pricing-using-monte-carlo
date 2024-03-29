# set.seed(2017)
library(tictoc)

no_of_simulations.1 <-  256 * 10 ^ 3     
no_of_simulations.2 <- (256 * 4) * 10 ^ 3
no_of_simulations.3 <- (256 * 8) * 10 ^ 3
no_of_simulations.4 <- (256 * 16) * 10 ^ 3
no_of_simulations.5 <- (256 * 32) * 10 ^ 3
no_of_simulations.6 <- (256 * 64) * 10 ^ 3
no_of_simulations.list <- c(no_of_simulations.1, no_of_simulations.2, 
                            no_of_simulations.3, no_of_simulations.4, 
                            no_of_simulations.5, no_of_simulations.6)

for (i in 1:6)
{
  
  # Inital Parameters  -------------------------------------------------------------
  chi.0 = -0.477;         # Feng, Table 1, pg. 23
  chi.K = 0;              # Feng, Table 1, pg. 23
  K = 22;                 # Feng, Table 1, pg. 23
  s0 = 100;               # Feng, Section 6.1, pg. 22
  strike = 100;           # Feng, Section 6.1, pg. 22
  T = 0.5;                # Feng, Section 6.1, pg. 22
  q = 0.02;               # Feng, Section 6.1, pg. 22
  r = 0.05 - q;           # Feng, Section 6.1, pg. 22
  
  # r = 0.03;           # Feng, Section 6.1, pg. 22
  
  
  # no_of_simulations = no_of_simulations.list[i];       # run through difference total no_of_simulations back-to-back
  no_of_simulations = no_of_simulations.5                # change number of MC iteriations here
  
  # tic(no_of_simulations)
  
  # List Function (for initializing variable arrays) ------------------------
  seqlist <- function(a, b, n)  {
    list1 <- rep(0, n)
    list1[1] = a
    list1[n] = b
    for (i in 2:(n - 1)) {
      list1[i] = (list1[n] - list1[i - 1]) * .326 + list1[i - 1]
    }
    return(list1)
  }
  
  
  # Initialize Variable Arrays ----------------------------------------------
  chi.list = seqlist(chi.0, chi.K, K + 1)
  Fhat.list = seq(0, 1, by = (1) / K)
  eta = (Fhat.list[K + 1] - Fhat.list[1]) / K
  Fhat.list
  
  # Brute-Force-Search function: chi ------------------------------------
  # input = -0.1
  brute_force_search.chi <- function(input) {
    stock_prices.list = 0
    for (variable in chi.list) {
      if (variable > input)  {
        return(stock_prices.list)
      }
      stock_prices.list = stock_prices.list + 1
    }
  }
  
  # Brute-Force-Search function: Fhat ------------------------------------
  brute_force_search.Fhat <- function(input)  {
    stock_prices.list = 0
    for (variable in Fhat.list) {
      if (variable > input)  {
        return(stock_prices.list)
      }
      stock_prices.list = stock_prices.list + 1
    }
  }
  
  #Binary Search
  binary_search <- function(values, input, start, end) {
    mid = floor((start + end) / 2)
    if (values[mid] <= input && values[mid + 1] >= input) {
      return(mid)
    }
    if (values[mid] > input) {
      end = mid
      return(binary_search(values, input, start, end))
    }
    if (values[mid] < input) {
      start = mid
      return(binary_search(values, input, start, end))
    }
  }
  
  # Fhat Distribution Function ----------------------------------------------
  # piecewise function for Fhat(x) taken from Feng, pg. 8 (Equation 3.12)
  Fhat.distribution <- function(input)
  {
    stock_prices.list = 0
    if (input < chi.list[1])
      # x < x0
    {
      stock_prices.list = 0
      return(stock_prices.list)
    }
    else if (input >= chi.list[K + 1])
      # x > 0 xK
    {
      stock_prices.list = 1
      return(stock_prices.list)
    }
    else
      # (xk-1) <= chi
    {
      xk_1 =  binary_search(chi.list, input, 1, length(chi.list))
      #print(binary_search(chi.list,input,1,length(chi.list)))# xk = bs(input);
      #xk_1 = brute_force_search.chi(input)
      #print(brute_force_search.chi(input))
      
      # Fhat[k-1] location:
      stock_prices.list = Fhat.list[xk_1] + (Fhat.list[xk_1 + 1] - Fhat.list[xk_1]) /
        eta * (input - chi.list[xk_1])
    }
    return(stock_prices.list)
  }
  
  # Inverse Transform Function ------------------------------------------------
  # Approximation to F-1(U) using brute-force search
  inverse_transform_method <- function() {
    U = runif(1,0,1)
    xk_1 = binary_search(Fhat.list, U, 1, length(Fhat.list))
    
    if (xk_1 < (K-1)) {                   # function returns K-1
      return(chi.list[xk_1 + 1] + (chi.list[xk_1 + 2] - chi.list[xk_1 + 1]) / 
               (Fhat.list[xk_1 + 2] - Fhat.list[xk_1 + 1]) * (U - Fhat.list[xk_1 + 1]))
    } else {
      return(0) 
    }
  }
  Xt = inverse_transform_method()
  
  # initialize price lists
  stock_prices.list <- rep(0, no_of_simulations)
  put_prices.list <- rep(0, no_of_simulations)
  
  # Inverse Transform Method 1 -----------------------------------------------
  # Calculate V using Section 5.4 of Feng's Paper (pg.19)
  put_prcs <- rep(0, no_of_simulations)
  for (j in 1:no_of_simulations) {
    put_prcs[j] = s0 * exp(-r*T) * max(0, strike/s0 - exp(inverse_transform_method()))
  }
  
  # Method 1 Result
  put_prc.InvT <- sum(put_prcs) / no_of_simulations
  
  toc(log = TRUE)
  tic.clearlog()
  tic.clear()
}
# END  --------------------------------------------------------------------
# -------------------------------------------------------------------------


plot(chi.list)

# OPTIONAL: Inverse Transform Method 2 ----------------------------------------------
# uses default calculation for option price: V = e^(-r*T) * max(0, K - St)
for (j in 1:no_of_simulations) 
{
  Xt = inverse_transform_method()
  stock_prices.list[j] = s0 * exp(Xt)
  put_prices.list[j] = exp(-r * T) * max(0, strike - stock_prices.list[j])
}

# Method 2 Result
sum(stock_prices.list) / no_of_simulations
put_prc.method2 <- sum(put_prices.list) / no_of_simulations

# Output both methods to table:
# note both methods should output very similar results:
values.table <- cbind(put_prc.InvT, put_prc.method2)
values.table


# RQuantLib benchmarking -----------------------------------------------------
# Use the EuropeanOption function of RQuantLib to calculate the Black-Scholes
# price of the European Put (all inputs are identical to the NIG inputs above, except volatility)
library(RQuantLib)
q = 0.0

# QuantLib Price of the European Put option using Black-Scholes
# to be compared with the FFT price and the PC-Parity Price
quantlib.bsm.put.prc <-
  EuropeanOption(
    type = "put",
    underlying = s0,
    strike = strike,
    dividendYield = q,
    riskFreeRate = r,
    maturity = 0.5,
    volatility = 0.19
  )

put_prices <- cbind(put_prc.InvT, quantlib.bsm.put.prc)

print("NIG Put Price vs Black-Scholes:")
put_prices
