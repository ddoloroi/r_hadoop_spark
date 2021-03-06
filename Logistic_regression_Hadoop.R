# Copyright 2011 Revolution Analytics
#    
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


## see spark implementation http://www.spark-project.org/examples.html
## see nice derivation here http://people.csail.mit.edu/jrennie/writing/lr.pdf

library(rmr2)

## @knitr logistic.regression-signature
logistic.regression = 
  function(input, iterations, dims, alpha){
    
    ## @knitr logistic.regression-map
    lr.map =          
      function(., M) {
        Y = M[,1] 
        X = M[,-1]
        keyval(
          1,
          Y * X * 
            g(-Y * as.numeric(X %*% t(plane))))}
    ## @knitr logistic.regression-reduce
    lr.reduce =
      function(k, Z) 
        keyval(k, t(as.matrix(apply(Z,2,sum))))
    ## @knitr logistic.regression-main
    plane = t(rep(0, dims))
    g = function(z) 1/(1 + exp(-z))
    for (i in 1:iterations) {
      gradient = 
        values(
          from.dfs(
            mapreduce(
              input,
              map = lr.map,     
              reduce = lr.reduce,
              combine = TRUE)))
      plane = plane + alpha * gradient }
    plane }
## @knitr end
points=ModelData
points[points[,1]==0,1]=-1 
out = list()
test.size = 10^5
for (be in c("local", "hadoop")) {
  rmr.options(backend = be)
  ## create test set 
  set.seed(0)
  ## @knitr logistic.regression-data
  eps = rnorm(test.size)
  testdata = 
    to.dfs(
      as.matrix(
        points))
  ## @knitr end  
  out[[be]] = 
    ## @knitr logistic.regression-run 
    logistic.regression(
      testdata, 10, 8, 0.05)
  ## @knitr end  
  ## max likelihood solution diverges for separable dataset, (-inf, inf) such as the above
}
stopifnot(
  isTRUE(all.equal(out[['local']], out[['hadoop']], tolerance = 1E-7)))
