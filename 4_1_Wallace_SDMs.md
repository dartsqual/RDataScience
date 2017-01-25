# SDMs with Wallace
Cory Merow  
1/25/2017  



<!-- <div> -->
<!-- <object data="4_1_assets/Wallace_SDMs1.pdf" type="application/pdf" width="100%" height="650px">  -->
<!--   <p>It appears you don't have a PDF plugin for this browser. -->
<!--    No biggie... you can <a href="4_1_assets/Wallace_SDMs1.pdf">click here to -->
<!--   download the PDF file.</a></p>   -->
<!--  </object> -->
<!--  </div> -->

<!--  <p><a href="4_1_assets/Wallace_SDMs1.pdf">Download the PDF of the presentation</a></p>   -->

[<i class="fa fa-file-code-o fa-3x" aria-hidden="true"></i> The R Script associated with this page is available here](4_1_Wallace_SDMs.R).  Download this file and open it (or copy-paste into a new script) with RStudio so you can follow along.  

# Setup
For `wallace` to work, you need the latest version of R.

[Windows](https://cran.r-project.org/bin/windows/base/)

[Mac](https://cran.r-project.org/bin/macosx/)

Load necessary libraries. 

```r
install.packages('knitr',dep=T) # you need the latest version, even if you already have it
install.pacakges('wallace',dep=T)
library(wallace)
run_wallace() # this will open the Wallace GUI in a web browser
```

The `wallace` GUI will open in your web browser and the R command line will be occupied (you only get a prompt back by pushing 'escape'). If you find this annoying and want to use your typical R command line, open a terminal window, type `R` to start R, and then run the lines above in that window. This will tie up your terminal window but not your usual R command line (e.g. RStudio, or the R GUI).

Typing `run_wallace()` will give you the following in your web browser:

![](4_1_assets/Wallace_Intro.png)
