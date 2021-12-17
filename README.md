# odksplit

``odksplit`` is a Stata module to label the variables, assign corresponding value labels, and split and label multiple response variables generated from ODK.

If ODK or SurveyCTO is used for data collection, the multiple response variables are downloaded as string variables. ``odksplit`` can be used to split those variables to create dummy variables as well as label the dummy variables. Additional options allow to do the other labeling excercises. If "SurveyCTO sync" is used to download data, and the 'Export select_multiple responses as series of 1/0 columns?' option was ticked, the dummy variables are already created in the dataset. However, ``odksplit`` does this again deleting the existing variables. ``odksplit`` uses the XLSform to identify the 'select_multiple' variables, and take the value labels from the choices sheet. odksplit was initially developed to work e multiple response variables, however, additional options were added based on user feedback.

This program will clear any data in memory. Therefore, the program asks whether you really want to clear data from memory. Write ok in the command line and press enter if you want to proceed.  Otherwise, write cancel, and press enter to cancel the program. This will not work if the variable names include the group names as prefix.


# Versions
Current version: 2.1.0
Available at SSC and on GitHub.


# Installation

```Stata
** Install from ssc
    ssc install odksplit

** Install from GitHub
    net install odksplit, all replace from(https://raw.githubusercontent.com/mehrabali/odksplit/master)

```

## Syntax
```stata
odksplit [, options]
```

## Options
| Options      | Description |
| ---        |    ----   |
| survey |  The name of the XLSform, including the path | 
| data   |  The name of the data file, including the path |
| label  |  The language specified in the label column in ODK XLSform. For example, if the label column is 'label:English', write English. Do not specify label if the column title is just 'label'. |
| multiple | To split and label multiple responses |
| single | To assign value label to single response variables |
| varlabel | To label variables |
| clear | To clear any data in memory |

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

Please report all bugs/feature request to the <a href="https://github.com/mehrabali/odksplit/issues" target="_blank"> github issues page</a>.

## Author
Mehrab Ali <br>
Email: mehrabbabu@gmail.com