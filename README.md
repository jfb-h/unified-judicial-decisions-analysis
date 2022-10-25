# Steps

1. Download pdfs (y)

2. Filter nullity pdfs

3. Parse contents of nullity pdfs into json

4. ? Clean up json (judge names)

5. Augment patent information

6. Parse json into decision structs

7. Exploratory analysis

8. Modeling


# Current Structure

## Module BPatGDecisions
 
- implements steps 1-3 and 6

## Module JudicialDecisions

- implements 5 and 7

## Scripts for manual cleaning

- judges_manual_*.csv/xlsx
- make_manual.jl

## Scripts for augmentation of patent data

- patent_nr_cpc.csv



# Target Structure

- Single root folder with:

    - data
        - raw
            - pdf_total
            - pdf_filtered
        - augmenting
            - judges_manual
            - patents_cpc
        - processed
            - json
            - json_augmented
        - derivative
    - scripts
    - src
        - [x] Download
        - [x] Filter (combine filter & extract for efficiency)
        - [x] Extract
        - [x] Augment
        - [x] Explore
        - [ ] Model


A simple workflow to reproduce examples could look like this:

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
