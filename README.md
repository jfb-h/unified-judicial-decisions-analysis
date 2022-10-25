
# Judicial decision making at the Bundespatentgericht, 2000 - 2020

This repository contains Julia code accompanying the paper 'Patent litigation between legalist and behaviouralist accounts of judicial decision making: Validity trials at the German Federal Patent Court, 2000-2020' written in the context of the UNIFIED project. It contains all steps to reproduce the analysis, including download, data cleaning and augmentation, modeling and visualization. 

A simple workflow to reproduce the analysis could look like this:

```julia
# run from the root directory of the project

include("src/Download/Download.jl")
Download.download()

include("src/Filter/Filter.jl")
Filter.filterpdfs()

include("src/Extract/Extract.jl")
Extract.extract()

include("src/Augment/Augment.jl")
Augment.clean_and_augment()

```

The full project structure should look something like this:

```
├───data
│   ├───augment
│   ├───derivative
│   ├───processed
│   │   ├───json
│   │   └───json_augmented
│   └───raw
│       ├───pdf_filtered
│       │   ├───2000
│       │   ├───2001
│       │   ├─── ...
│       └───pdf_total
│           ├───2000
│           ├───2001
│           ├─── ...
├───scripts
└───src
    ├───Augment
    ├───Download
    ├───Explore
    ├───Extract
    ├───Filter
    └───Model
```