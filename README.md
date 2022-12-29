# odksplit

``odksplit`` is a Stata module to label the variables, assign corresponding value labels, and split and label multiple response variables generated from ODK. ``odksplit`` is developed and maintained by [ARCED Foundation](www.arced.foundation).

If ODK or SurveyCTO is used for data collection, the multiple response variables are downloaded as string variables. ``odksplit`` can be used to split those variables to create dummy variables as well as label the dummy variables. Additional options allow to do the other labeling excercises. If "SurveyCTO sync" is used to download data, and the 'Export select_multiple responses as series of 1/0 columns?' option was ticked, the dummy variables are already created in the dataset. However, ``odksplit`` does this again deleting the existing variables. ``odksplit`` uses the XLSform to identify the 'select_multiple' variables, and take the value labels from the choices sheet. ``odksplit`` was initially developed to work on multiple response variables, however, additional options were added based on user feedback.

This program will clear any data in memory. Therefore, the program asks whether you really want to clear data from memory. Write ok in the command line and press enter if you want to proceed. Otherwise, write cancel, and press enter to cancel the program. This will not work if the variable names include the group names as prefix.


# Versions
Current version at <a href="https://www.stata.com/manuals/rssc.pdf" target="_blank">SSC</a>     : 2.1.0 <br>
Current version at <a href="https://github.com/mehrabali/odksplit#installation" target="_blank">GitHub</a>   : 3.1.0 <br>

First released on July 2019. Last updated Dec 2021.

## Change log
### 3.1.0
* ``odksplit`` now adds the full questions as notes to the variables. To view the full question instead of Stata label, write ``notes varname``. To view full questions for all variables, write ``notes`` in the Stata command window.

# Installation

```Stata
** Install from ssc
    ssc install odksplit

** Install from GitHub
    net install odksplit, all replace from(https://raw.githubusercontent.com/ARCED-Foundation/odksplit/master)

```

## Syntax
```stata
odksplit [, options]

help odksplit
```

## Options
| Options      | Description |
| ---        |    ----   |
| <u>s</u>urvey |  The name of the XLSform, including the path | 
| <u>d</u>ata   |  The name of the data file, including the path |
| <u>l</u>abel  |  The language specified in the label column in ODK XLSform. For example, if the label column is 'label:English', write English. Do not specify label if the column title is just 'label'. |
| <u>m</u>ultiple | To split and label multiple responses |
| <u>sing</u>le | To assign value label to single response variables |
| <u>var</u>label | To label variables |
| <u>c</u>lear | To clear any data in memory |

## Example Syntax
```Stata

    odksplit,   survey("X:\Projects 2018\Fieldwork\Tools\SurveyCTO files\Phase one_v1.xlsx") ///
                data("X:\Projects 2017\Fieldwork\Data\Data\raw\Phase one data.dta") ///
                label(English) multiple single varlabel clear

    odksplit,   s("X:\Projects 2018\Fieldwork\Tools\SurveyCTO files\Phase one_v1.xlsx") ///
                d("X:\Projects 2017\Fieldwork\Data\Data\raw\Phase one data.dta") multiple clear

    odksplit,   s("X:\Projects 2018\Fieldwork\Tools\SurveyCTO files\Phase one_v1.xlsx") ///
                d("X:\Projects 2017\Fieldwork\Data\Data\raw\Phase one data.dta") single clear

    odksplit,   s("X:\Projects 2018\Fieldwork\Tools\SurveyCTO files\Phase one_v1.xlsx") ///
                d("X:\Projects 2017\Fieldwork\Data\Data\raw\Phase one data.dta") var

```

Please report all bugs/feature request to the <a href="https://github.com/ARCED-Foundation/odksplit/issues" target="_blank"> github issues page</a>.

## Author
Mehrab Ali <br>
Email: mehrabbabu@gmail.com