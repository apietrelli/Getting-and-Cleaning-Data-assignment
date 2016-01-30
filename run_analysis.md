---
title: "Getting and Clenaing Data Project"
author: "apietrelli"
date: "30 Jan 2016"
output: html_document
---

# Prepare library and working directory

1. Set dir

```r
path = getwd()
path
```

```
## [1] "/Users/alessandro/Documents/Coursera_DataScience/3-Getting_cleaning_Data/Getting-and-Cleaning-Data-assignment"
```

2. Load Packages

```r
packages <- c("data.table", "reshape2")
sapply(packages, require, character.only = TRUE, quietly = TRUE)
```

```
## data.table   reshape2 
##       TRUE       TRUE
```

# Load data

Dataset has been downloaded, we will load the data from `UCI HAR Dataset` directly

## Set the path for data


```r
pathInput <- file.path(path, "UCI HAR Dataset")
list.files(pathInput, recursive = TRUE)
```

```
##  [1] "activity_labels.txt"                         
##  [2] "features_info.txt"                           
##  [3] "features.txt"                                
##  [4] "README.txt"                                  
##  [5] "test/Inertial Signals/body_acc_x_test.txt"   
##  [6] "test/Inertial Signals/body_acc_y_test.txt"   
##  [7] "test/Inertial Signals/body_acc_z_test.txt"   
##  [8] "test/Inertial Signals/body_gyro_x_test.txt"  
##  [9] "test/Inertial Signals/body_gyro_y_test.txt"  
## [10] "test/Inertial Signals/body_gyro_z_test.txt"  
## [11] "test/Inertial Signals/total_acc_x_test.txt"  
## [12] "test/Inertial Signals/total_acc_y_test.txt"  
## [13] "test/Inertial Signals/total_acc_z_test.txt"  
## [14] "test/subject_test.txt"                       
## [15] "test/X_test.txt"                             
## [16] "test/y_test.txt"                             
## [17] "train/Inertial Signals/body_acc_x_train.txt" 
## [18] "train/Inertial Signals/body_acc_y_train.txt" 
## [19] "train/Inertial Signals/body_acc_z_train.txt" 
## [20] "train/Inertial Signals/body_gyro_x_train.txt"
## [21] "train/Inertial Signals/body_gyro_y_train.txt"
## [22] "train/Inertial Signals/body_gyro_z_train.txt"
## [23] "train/Inertial Signals/total_acc_x_train.txt"
## [24] "train/Inertial Signals/total_acc_y_train.txt"
## [25] "train/Inertial Signals/total_acc_z_train.txt"
## [26] "train/subject_train.txt"                     
## [27] "train/X_train.txt"                           
## [28] "train/y_train.txt"
```

## Read the files

1. Subject id


```r
dtSubjectTrain <- fread(file.path(pathInput, "train", "subject_train.txt"))
dtSubjectTest <- fread(file.path(pathInput, "test", "subject_test.txt"))
```

2. Activity 

```r
dtActivityTrain <- fread(file.path(pathInput, "train", "y_train.txt"))
dtActivityTest <- fread(file.path(pathInput, "test", "y_test.txt"))
```

3. Features


```r
dtTrain <- fread(file.path(pathInput, "train", "X_train.txt"))
dtTest <- fread(file.path(pathInput, "test", "X_test.txt"))
```

# Merge the train set and test set

Concatenate datatables


```r
dtSubject <- rbind(dtSubjectTrain, dtSubjectTest)
setnames(dtSubject, "V1", "subject")
dtActivity <- rbind(dtActivityTrain, dtActivityTest)
setnames(dtActivity, "V1", "activityNum")
dt <- rbind(dtTrain, dtTest)
```

Merge datatable Subject, Activity and Features

```r
dt <- cbind(cbind(dtSubject, dtActivity), dt)
setkey(dt, subject, activityNum)
```

#Extract mean and standard deviation for each measurement

Read the features name and convert them into `dt`


```r
dtFeatures = fread(file.path(pathInput, "features.txt"))
setnames(dtFeatures, names(dtFeatures), c("featureNum", "featureName"))
```

Extract only measurement for mean and standard deviation


```r
dtFeatures = dtFeatures[grepl("mean\\(\\)|std\\(\\)", featureName)]
head(dtFeatures)
```

```
##    featureNum       featureName
## 1:          1 tBodyAcc-mean()-X
## 2:          2 tBodyAcc-mean()-Y
## 3:          3 tBodyAcc-mean()-Z
## 4:          4  tBodyAcc-std()-X
## 5:          5  tBodyAcc-std()-Y
## 6:          6  tBodyAcc-std()-Z
```

Prepare `dfFeatures` for select `dt` feature column adding a common ID (featureCode)


```r
dtFeatures$featureCode = paste("V",dtFeatures$featureNum, sep='')
head(dtFeatures)
```

```
##    featureNum       featureName featureCode
## 1:          1 tBodyAcc-mean()-X          V1
## 2:          2 tBodyAcc-mean()-Y          V2
## 3:          3 tBodyAcc-mean()-Z          V3
## 4:          4  tBodyAcc-std()-X          V4
## 5:          5  tBodyAcc-std()-Y          V5
## 6:          6  tBodyAcc-std()-Z          V6
```

Select only featureCode columns


```r
select <- c(key(dt), dtFeatures$featureCode)
dt <- dt[, select, with = FALSE]
```

# Uses descriptive activity names to name the activities in the data set

Read activity labels and recode the name in `dt`


```r
dtActivityLabels = fread(file.path(pathInput, "activity_labels.txt"))
setnames(dtActivityLabels, names(dtActivityLabels), c("activityNum", "activityName"))
```

# Labels the data set with descriptive variable names

Merge the data tables


```r
dt = merge(dt, dtActivityLabels, by="activityNum")
```

Add `activityName` as key


```r
setkey(dt, subject, activityNum, activityName)
key(dt)
```

```
## [1] "subject"      "activityNum"  "activityName"
```

Reshape `dt` in a tall and narrow format 


```r
dt <- data.table(melt(dt, key(dt), variable.name = "featureCode"))
```

Add activity readable names by merging `dt` and `dtFeatures`


```r
dt = merge(dt, dtFeatures[,list(featureNum, featureCode, featureName)],
      by="featureCode",
      all.x = T)
```

Create separate columns for all possible combination of `featureName`

There are different type of features:

1. Features with 2 categories


```r
category = 2
y <- matrix(seq(1, category), nrow = category)
```

- Time and Frequency

```r
x <- matrix(c(grepl("^t", dt$featureName), grepl("^f", dt$featureName)), ncol = nrow(y))
dt$featDomain <- factor(x %*% y, labels = c("Time", "Freq"))
x <- matrix(c(grepl("Acc", dt$featureName), grepl("Gyro", dt$featureName)), ncol = nrow(y))
```

- Accelerator and Gyroscope


```r
dt$featInstrument <- factor(x %*% y, labels = c("Accelerometer", "Gyroscope"))
x <- matrix(c(grepl("BodyAcc", dt$featureName),
              grepl("GravityAcc", dt$featureName)),
            ncol = nrow(y))
```

- Body and Gravity


```r
dt$featAcceleration <- factor(x %*% y, labels = c(NA, "Body", "Gravity"))
x <- matrix(c(grepl("mean()", dt$featureName),
              grepl("std()", dt$featureName)),
            ncol = nrow(y))
dt$featVariable <- factor(x %*% y, labels = c("Mean", "SD"))
```

2. Features with 1 category

- Jerk


```r
dt$featJerk <- factor(grepl("Jerk", dt$featureName), labels = c(NA, "Jerk"))
```

- Magnitude


```r
dt$featMagnitude <- factor(grepl("Mag", dt$featureName), labels = c(NA, "Magnitude"))
```

3. Features with 3 categories 

- Axis X,Y,Z


```r
category = 3
y <- matrix(seq(1, category), nrow = category)
x <- matrix(c(grepl("-X",dt$featureName),
              grepl("-Y",dt$featureName),
              grepl("-Z",dt$featureName)),
            ncol = nrow(y))
dt$featAxis <- factor(x %*% y, labels = c(NA, "X", "Y", "Z"))
```

# Create a new tidy dataset


```r
setkey(dt, subject, activityName, featDomain, featAcceleration, featInstrument, 
    featJerk, featMagnitude, featVariable, featAxis)
dtTidy <- dt[, list(count = .N, average = mean(value)), by = key(dt)]
```

Write the new dataset


```r
write.csv(dtTidy, "dataset_tidy_smartphone.csv", row.names = F)
```

DONE
