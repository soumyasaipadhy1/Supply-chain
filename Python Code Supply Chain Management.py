import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

data = pd.read_csv(r"C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\pallet_Masked_fulldata.csv")  # Read data into python
data.dtypes
data.describe

## Database connectivity using Python ##

# pip install sqlalchemy
pip install SQLAlchemy

from sqlalchemy import create_engine

# **Engine Configuration**
# The Engine is the starting point for any SQLAlchemy application. 
# It’s “home base” for the actual database and its DBAPI, 
# delivered to the SQLAlchemy application through a connection pool and a Dialect, 
# which describes how to talk to a specific kind of database/DBAPI combination.
# sqlalchemy helps to connect mysql, postgresql, microsoftsql(mssql), etc;

## For mysql
pip install pymysql

engine = create_engine("mysql+pymysql://{user}:{pw}@localhost/{db}"
                       .format(user = "root",# user
                               pw = "0000", # passwrd
                               db = "class")) #database

## EDA ##
# FIRST Moment Business Decision:-
data.QTY.mean()
data.QTY.median()
data.QTY.mode()
data.Region.mode()
data.City.mode()
data.State.mode()
data.TransactionType.mode()

# SECOND Moment Business Decision:-
data.QTY.var()
data.QTY.std()
range = max(data.QTY) - min(data.QTY)
range

# THIRD Moment Business Decision:-
data.QTY.skew()

# FOURTH Moment Business Decision:-
data.QTY.kurt()

## UNIVARIATE ANALYSIS
#HISTOGRAM
plt.hist(data.QTY)  # From histogram we can observe that count of Quantity between (200-300) is most repeated so we have to focous it more for business profit.
plt.hist(data.QTY, bins =  [5,10,15,20,25,30,35], color = 'green', edgecolor="red")

df = data
# Box Plot
sns.boxplot(df.QTY)  # From the box plot we see there is no high extreme values or low extreme values presenet in the Quantity.

#DISTPLOT
sns.distplot(data.QTY)

#DENSITY PLOT
sns.kdeplot(data.QTY) # Density plot
sns.kdeplot(data.QTY, bw = 0.5 , fill = True)


## DATA PREPROCESSING ##

data1 = data.dropna() # Remove rows and columns with missing values

data2 = data.drop_duplicates() # Remove duplicate rows

data3 = data.drop_duplicates(subset=['Sl no', 'Date', 'CustName', 'City', 'Region', 'State', 'ProductCode', 'TransactionType', 'QTY', 'WHName'], inplace=True)

# Correlation coefficient
'''
Ranges from -1 to +1. 
Rule of thumb says |r| > 0.85 is a strong relation
'''
data.corr()


### Outlier Treatment ###
df = data

# Let's find outliers in Wind_speed 
sns.boxplot(df.QTY)

# Detection of outliers (find limits for salary based on IQR)
IQR = df['QTY'].quantile(0.75) - df['QTY'].quantile(0.25)

lower_limit = df['QTY'].quantile(0.25) - (IQR * 1.5)
upper_limit = df['QTY'].quantile(0.75) + (IQR * 1.5)

###### 1. Remove (let's trim the dataset) #######
# Trimming Technique
# Let's flag the outliers in the dataset
outliers_df = np.where(df.QTY > upper_limit, True, np.where(df.QTY < lower_limit, True, False))

# outliers data
df_out = df.loc[outliers_df, ]

df_trimmed = df.loc[~(outliers_df), ]
df.shape, df_trimmed.shape

# Let's explore outliers in the trimmed dataset
sns.boxplot(df_trimmed.QTY)

## Bivariate Analysis
def bivariate_analysis(data,Region,QTY):
    plt.figure(figsize=(1, 6))

    # Scatter plot
    plt.subplot(2, 2,4 )
    sns.scatterplot(x=data1['Region'], y=data1['QTY'])
    plt.title(f'Scatter plot of {"Region"} vs {"QTY"}')  # We don't find any strong correlation between all the numerical variables.
    
    # Line Graph
    
    # Display the first few rows of the DataFrame to understand its structure
print(data.head())

# Assuming you have columns 'x_column' and 'y_column', replace them with your actual column names
x_column = 'State'
y_column = 'QTY'

# Create a line plot using Seaborn
sns.lineplot(x=x_column, y=y_column, data=data)  # From Line chart we understand how many states have higher Quantity so that we can focous more on that states to achive more profit.

# Show the plot
plt.show()
    
# Multivariate Analysis
def multivariate_analysis(data):
    plt.figure(figsize=(12, 8))
    
    # Pairplot for all numerical variables
    sns.pairplot(data, diag_kind='kde')
    plt.suptitle('Pairplot of Numerical Variables', y=1.02)
    plt.show()  

-----------------------------------------------------------------------------------------------------------

# Load the Data
import pandas as pd

df = pd.read_csv(r"pallet_Masked_fulldata.csv")

# Auto EDA
# ---------
# Sweetviz
# Autoviz
# Dtale
# Pandas Profiling
# Dataprep


# Sweetviz
###########
#pip install sweetviz
import sweetviz as sv
pip install sweetviz
s = sv.analyze(df)
s.show_html()


# Autoviz
###########
# pip install autoviz
pip install autoviz
from autoviz.AutoViz_Class import AutoViz_Class

av = AutoViz_Class()
a = av.AutoViz(r"C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\pallet_Masked_fulldata.csv", chart_format = 'html')

import os
os.getcwd()

# If the dependent variable is known:
a = av.AutoViz(r"C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\pallet_Masked_fulldata.csv", depVar = 'QTY') # depVar - target variable in your dataset



# D-Tale
########

# pip install dtale   # In case of any error then please install werkzeug appropriate version (pip install werkzeug==2.0.3)
import dtale
import pandas as pd

df = pd.read_csv(r"C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\pallet_Masked_fulldata.csv")

d = dtale.show(df)
d.open_browser()


# Pandas Profiling
###################

# pip install pandas_profiling
from pandas_profiling import ProfileReport 

p = ProfileReport(df)
p
p.to_file("output.html")

import os
os.getcwd()

# Dataprep
##########

# pip install dataprep
from dataprep.eda import create_report

report = create_report(df, title = 'My Report')

report.show_browser()


