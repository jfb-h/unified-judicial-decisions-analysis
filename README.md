
# Judicial decision making at the Bundespatentgericht, 2000 - 2021

This repository contains Julia code accompanying the paper 'Legalist and realist decision-making in Patent law: Validity Cases in Germany' written in the context of the UNIFIED project. It contains all steps to reproduce the analysis, including download, data cleaning and augmentation, modeling and visualization. 

The results reported in the paper can be obtained by running the notebooks `descriptive-results.ipynb` and `model-results.ipynb` in the `scripts` folder.
This uses the cleaned data in the `data.jsonl` file contained in the repository.

A workflow to reproduce the full data extraction process could look like this:


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
The full project structure including the raw downloaded data should look something like this:

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
