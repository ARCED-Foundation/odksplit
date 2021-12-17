# odksplit

``odksplit`` is a Stata module to label the variables, assign corresponding value labels, and split and label multiple response variables generated from ODK.

If ODK or SurveyCTO is used for data collection, the multiple response variables are downloaded as string variables. ``odksplit`` can be used to split those variables to create dummy variables as well as label the dummy variables. Additional options allow to do the other labeling excercises. If "SurveyCTO sync" is used to download data, and the 'Export select_multiple responses as series of 1/0 columns?' option was ticked, the dummy variables are already created in the dataset. However, ``odksplit`` does this again deleting the existing variables. ``odksplit`` uses the XLSform to identify the 'select_multiple' variables, and take the value labels from the choices sheet. odksplit was initially developed to work e multiple response variables, however, additional options were added based on user feedback.
