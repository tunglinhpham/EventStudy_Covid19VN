#Check packages and install if needed
check_packages = c("readxl", "xtable", "data.table", "kableExtra", "mvtnorm", "ggplot2")
package.check = lapply(
  check_packages, FUN = function(x)
  {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE)
    }
  }
)

#Load library
library(readxl)
library(xtable)
library(data.table)
library(kableExtra)
library(mvtnorm)
library(ggplot2)
library(xts)
library(zoo)
library(distributions3)

#Get relevant data
#Edit data source here
Raw_full_data = read_excel("D:/University of Kent/01. Lectures/0. Dissertation/Full_data.xlsx", sheet = "Data")
Raw_full_data = as.data.table(Raw_full_data)

#Drop stocks that do not have full data during the period
Raw_data = subset(Raw_full_data, select = -c(16, 21, 22, 24, 26, 27, 31, 33, 35, 37, 38, 39, 40, 42, 43, 45, 47, 48, 51, 54, 56, 61, 62, 67, 69, 77, 78, 83, 84, 86, 87, 92, 93, 94, 95, 97, 98, 99, 100, 101, 102, 104, 105, 106, 108, 109, 110, 111, 114, 115, 116, 117, 120, 121, 122, 123, 124, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 137, 138, 139, 140, 142, 143, 147, 148, 149, 150, 151, 152, 153, 156, 157, 158, 159, 160, 161, 163, 166, 167, 169, 170, 172, 173, 174, 175, 176, 177, 179, 180, 181, 182, 185, 188, 190, 191, 192, 195, 198, 199, 200, 201, 204, 205, 206, 207, 209, 211, 212, 213, 214, 215, 216, 217, 220, 222, 223, 224, 225, 226, 228, 229, 231, 232, 234, 235, 236, 237, 238, 239, 242, 243, 245, 246))

#Drop days that do not have data (holidays, holidays...)
Raw_data = na.omit(Raw_data)

#Get Daily Risk-free return
Raw_data = Raw_data[, Daily_Rf := ((1+(`VNCD3MO Index`)/100)^(1/250)-1)*100]

#Calculate Daily returns of stocks
#Market return & SMB
Returns_temp = c(
  ((Raw_data[2:1160,3]-Raw_data[1:1159,3])/Raw_data[1:1159,3])*100,
  ((Raw_data[2:1160,5]-Raw_data[1:1159,5])/Raw_data[1:1159,5]-(Raw_data[2:1160,4]-Raw_data[1:1159,4])/Raw_data[1:1159,4])*100)
#Stock return
Returns_temp = c(Returns_temp, ((Raw_data[2:1160,6:103]-Raw_data[1:1159,6:103])/Raw_data[1:1159,6:103])*100)
Returns_temp = do.call(cbind, Returns_temp)

#Drop first row of data (due to no return)
Raw_data = Raw_data[-1,]

#Gather all data together
Full_return_data = cbind(subset(Raw_data, select = c(1, 104)), Returns_temp)
names(Full_return_data) = c("Date", "Daily_Rf", "Rm", "SMB", "Ret_SHCOMP", "Ret_CNYUSD", "Ret_DJI", paste0("Ret_",substr(colnames(Full_return_data[,8:102]),1,3)))
Full_return_data[,1] = as.Date(Full_return_data$Date, format="%Y-%m-%d")
Full_return_data = read.zoo(Full_return_data)
remove(package.check, check_packages, Returns_temp)

Port_return_data = subset(Full_return_data, select=c(1:6))
Industrials = rowMeans(subset(Full_return_data,select = c(9,28,29,30,32,34,36,38,40,50,57,58,61,64,70,83,92,99,100)))
Materials = rowMeans(subset(Full_return_data,select = c(14,27,31,33,39,42,43,44,63,65,67,68,74,82,86,94,96,97)))
Consumer_Discretionary = rowMeans(subset(Full_return_data,select = c(17,18,19,48,53,55,66,76,77,81,87,88,90,91,93,95)))
Real_Estate = rowMeans(subset(Full_return_data,select = c(24,35,37,45,46,49,51,54,59,71,75,84,101)))
Financials = rowMeans(subset(Full_return_data,select = c(7,8,10,11,15,21,22,23,41,62,72,78)))
Consumer_Staples = rowMeans(subset(Full_return_data,select = c(16,20,25,26,47,60,73,79,85,98)))
Energy_Utilities = rowMeans(subset(Full_return_data,select = c(13,56,89,52,69)))
Others = rowMeans(subset(Full_return_data,select = c(12, 90)))
Port_return_data = cbind(Port_return_data, Industrials, Materials, Consumer_Discretionary, Real_Estate, Financials, Consumer_Staples, Energy_Utilities, Others)
remove(Industrials, Materials, Consumer_Discretionary, Real_Estate, Financials, Consumer_Staples, Energy_Utilities, Others)

#Descriptive Statistic of Portfolios
summary(Port_return_data[,7:14])
sqrt(var(Port_return_data[,7:14]))

#Define Estimation & Event Window
Estimation_window = Port_return_data[1:967,]
Event_window = Port_return_data[968:984,]

#Statistics of Normal Returns Model
coeff = matrix(NA, nrow = 8, ncol = 5)
stderr = matrix(NA, nrow = 8, ncol = 5)
r_squared = matrix(NA, nrow = 8, ncol = 2)
p_values = matrix(NA, nrow = 8, ncol = 5)
SE = matrix(NA, nrow = 8, ncol = 2)

for (i in 7:14)
{
  OLS1 = lm(Estimation_window[,i] ~ Rm, data = Estimation_window) 
  coeff[i-6,1:2] = summary(OLS1)$coefficients[1:2,1]
  stderr[i-6,1:2] = summary(OLS1)$coefficients[1:2,2]
  r_squared[i-6,1] = summary(OLS1)$r.squared
  p_values[i-6,1:2] = summary(OLS1)$coefficients[1:2,4]
  SE[i-6,1] = sum((summary(OLS1)$resid)^2)/965

  OLS2 = lm((Estimation_window[,i] - Daily_Rf) ~ (Rm - Daily_Rf) + SMB, data = Estimation_window) 
  coeff[i-6,3:5] = summary(OLS2)$coefficients[1:3,1]
  stderr[i-6,3:5] = summary(OLS2)$coefficients[1:3,2]
  r_squared[i-6,2] = summary(OLS2)$r.squared
  p_values[i-6,3:5] = summary(OLS2)$coefficients[1:3,4]
  SE[i-6,2] = sum((summary(OLS2)$resid)^2)/965
}

coeff = as.data.frame(coeff)
colnames(coeff) = c("MM_Intercept", "MM_Market", "CAPM_Intercept", "CAPM_Excess_Market", "CAPM_SMB")
rownames(coeff) = c("Industrials", "Materials", "Consumer_Discretionary", "Real_Estate", "Financials", "Consumer_Staples", "Energy_Utilities", "Others")
stderr = as.data.frame(stderr)
colnames(stderr) = c("MM_Intercept", "MM_Market", "CAPM_Intercept", "CAPM_Excess_Market", "CAPM_SMB")
rownames(stderr) = c("Industrials", "Materials", "Consumer_Discretionary", "Real_Estate", "Financials", "Consumer_Staples", "Energy_Utilities", "Others")
r_squared = as.data.frame(r_squared)
colnames(r_squared) = c("MM_R_Squared", "CAPM_R_Squared")
rownames(r_squared) = c("Industrials", "Materials", "Consumer_Discretionary", "Real_Estate", "Financials", "Consumer_Staples", "Energy_Utilities", "Others")
p_values = as.data.frame(p_values)
colnames(p_values) = c("MM_Intercept", "MM_Market", "CAPM_Intercept", "CAPM_Excess_Market", "CAPM_SMB")
rownames(p_values) = c("Industrials", "Materials", "Consumer_Discretionary", "Real_Estate", "Financials", "Consumer_Staples", "Energy_Utilities", "Others")
colnames(SE) = c("MM_SE", "CAPM_SE")
rownames(SE) = c("Industrials", "Materials", "Consumer_Discretionary", "Real_Estate", "Financials", "Consumer_Staples", "Energy_Utilities", "Others")

View(round(cbind(coeff[,3:5],stderr[,3:5],p_values[,3:5],r_squared[,2]),4))
View(round(cbind(coeff[,1:2],stderr[,1:2],p_values[,1:2],r_squared[,1]),4))

#MM Abnormal Returns
MM_Normal_returns = subset(Event_window, select = -c(1:6))
for (i in 1:8)
{
  MM_Normal_returns[,i] = coeff[i,1] + coeff[i,2]*Event_window$Rm
}
MM_Abnormal_returns = Event_window[,7:14] - MM_Normal_returns

##CAPM Abnormal Returns
CAPM_Normal_returns = subset(Event_window, select = -c(1:6))
for (i in 1:8)
{
  CAPM_Normal_returns[,i] = coeff[i,3] + coeff[i,4]*(Event_window$Rm - Event_window$Daily_Rf) + coeff[i,5]*Event_window$SMB
}
CAPM_Abnormal_returns = (Event_window[,7:14] - Event_window$Daily_Rf) - CAPM_Normal_returns

Z = Normal(0,1)

#Testing for portfolios
MM_Test_port = matrix(nrow = 8, ncol = 4)
rownames(MM_Test_port) = colnames(MM_Normal_returns)
colnames(MM_Test_port) = c("CAR", "Var_CAR", "SCAR", "p_values")
MM_Test_port = as.data.frame(MM_Test_port)
View(MM_Test_port)

CAPM_Test_port = matrix(nrow = 8, ncol = 4)
rownames(CAPM_Test_port) = colnames(CAPM_Normal_returns)
colnames(CAPM_Test_port) = c("CAR", "Var_CAR", "SCAR", "p_values")
CAPM_Test_port = as.data.frame(CAPM_Test_port)
View(CAPM_Test_port)

for (i in 1:8)
{
  MM_Test_port[i,1]=sum(MM_Abnormal_returns[1:17,i])
  MM_Test_port[i,2]=sqrt(SE[i,1])
}
MM_Test_port[,3] = MM_Test_port[,1]/MM_Test_port[,2]
for (i in 1:8)
{
  MM_Test_port[i,4]= round(1 - cdf(Z, abs(MM_Test_port[i,3])) + cdf(Z, -abs(MM_Test_port[i,3])),4)
}

for (i in 1:8)
{
  CAPM_Test_port[i,1]=sum(CAPM_Abnormal_returns[1:17,i])
  CAPM_Test_port[i,2]=sqrt(SE[i,2])
}
CAPM_Test_port[,3] = CAPM_Test_port[,1]/CAPM_Test_port[,2]
for (i in 1:8)
{
  CAPM_Test_port[i,4]= round(1 - cdf(Z, abs(CAPM_Test_port[i,3])) + cdf(Z, -abs(CAPM_Test_port[i,3])),4)
}

#Graph - Market Model
MM_Industrials = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  MM_Industrials[i,1] = sum(MM_Normal_returns[1:i,1])
  MM_Industrials[i,2] = sum(Event_window[1:i,7])
}
colnames(MM_Industrials) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(MM_Industrials, aes(y = Cumulative_Actual_Returns, x = time(MM_Industrials), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = MM_Industrials$Cumulative_Normal_Returns, ymax = MM_Industrials$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = MM_Industrials$Cumulative_Normal_Returns, x = time(MM_Industrials)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Return from Market Model - Industrials Sector")

MM_Materials = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  MM_Materials[i,1] = sum(MM_Normal_returns[1:i,2])
  MM_Materials[i,2] = sum(Event_window[1:i,8])
}
colnames(MM_Materials) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(MM_Materials, aes(y = Cumulative_Actual_Returns, x = time(MM_Materials), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = MM_Materials$Cumulative_Normal_Returns, ymax = MM_Materials$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = MM_Materials$Cumulative_Normal_Returns, x = time(MM_Materials)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Return from Market Model - Materials Sector")

MM_Consumer_Discretionary = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  MM_Consumer_Discretionary[i,1] = sum(MM_Normal_returns[1:i,3])
  MM_Consumer_Discretionary[i,2] = sum(Event_window[1:i,9])
}
colnames(MM_Consumer_Discretionary) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(MM_Consumer_Discretionary, aes(y = Cumulative_Actual_Returns, x = time(MM_Consumer_Discretionary), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = MM_Consumer_Discretionary$Cumulative_Normal_Returns, ymax = MM_Consumer_Discretionary$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = MM_Consumer_Discretionary$Cumulative_Normal_Returns, x = time(MM_Consumer_Discretionary)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Return from Market Model - Consumer Discretionary Sector")

MM_Real_Estate = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  MM_Real_Estate[i,1] = sum(MM_Normal_returns[1:i,4])
  MM_Real_Estate[i,2] = sum(Event_window[1:i,10])
}
colnames(MM_Real_Estate) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(MM_Real_Estate, aes(y = Cumulative_Actual_Returns, x = time(MM_Real_Estate), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = MM_Real_Estate$Cumulative_Normal_Returns, ymax = MM_Real_Estate$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = MM_Real_Estate$Cumulative_Normal_Returns, x = time(MM_Real_Estate)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Return from Market Model - Real Estate Sector")

MM_Financials = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  MM_Financials[i,1] = sum(MM_Normal_returns[1:i,5])
  MM_Financials[i,2] = sum(Event_window[1:i,11])
}
colnames(MM_Financials) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(MM_Financials, aes(y = Cumulative_Actual_Returns, x = time(MM_Financials), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = MM_Financials$Cumulative_Normal_Returns, ymax = MM_Financials$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = MM_Financials$Cumulative_Normal_Returns, x = time(MM_Financials)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Return from Market Model - Financials Sector")

MM_Consumer_Staples = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  MM_Consumer_Staples[i,1] = sum(MM_Normal_returns[1:i,6])
  MM_Consumer_Staples[i,2] = sum(Event_window[1:i,12])
}
colnames(MM_Consumer_Staples) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(MM_Consumer_Staples, aes(y = Cumulative_Actual_Returns, x = time(MM_Consumer_Staples), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = MM_Consumer_Staples$Cumulative_Normal_Returns, ymax = MM_Consumer_Staples$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = MM_Consumer_Staples$Cumulative_Normal_Returns, x = time(MM_Consumer_Staples)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Return from Market Model - Consumer Staples Sector")

MM_Energy_Utilities = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  MM_Energy_Utilities[i,1] = sum(MM_Normal_returns[1:i,7])
  MM_Energy_Utilities[i,2] = sum(Event_window[1:i,13])
}
colnames(MM_Energy_Utilities) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(MM_Energy_Utilities, aes(y = Cumulative_Actual_Returns, x = time(MM_Energy_Utilities), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = MM_Energy_Utilities$Cumulative_Normal_Returns, ymax = MM_Energy_Utilities$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = MM_Energy_Utilities$Cumulative_Normal_Returns, x = time(MM_Energy_Utilities)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Return from Market Model - Energy & Utilities Sector")

MM_Others = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  MM_Others[i,1] = sum(MM_Normal_returns[1:i,8])
  MM_Others[i,2] = sum(Event_window[1:i,14])
}
colnames(MM_Others) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(MM_Others, aes(y = Cumulative_Actual_Returns, x = time(MM_Others), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = MM_Others$Cumulative_Normal_Returns, ymax = MM_Others$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = MM_Others$Cumulative_Normal_Returns, x = time(MM_Others)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Return from Market Model - Others Sector")

#Graph - CAPM
CAPM_Industrials = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  CAPM_Industrials[i,1] = sum(CAPM_Normal_returns[1:i,1])
  CAPM_Industrials[i,2] = sum(Event_window[1:i,7] - Event_window[1:i,1])
}
colnames(CAPM_Industrials) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(CAPM_Industrials, aes(y = Cumulative_Actual_Returns, x = time(CAPM_Industrials), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = CAPM_Industrials$Cumulative_Normal_Returns, ymax = CAPM_Industrials$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = CAPM_Industrials$Cumulative_Normal_Returns, x = time(CAPM_Industrials)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Excess Return from Augmented CAPM - Industrials Sector")

CAPM_Materials = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  CAPM_Materials[i,1] = sum(CAPM_Normal_returns[1:i,2])
  CAPM_Materials[i,2] = sum(Event_window[1:i,8] - Event_window[1:i,1])
}
colnames(CAPM_Materials) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(CAPM_Materials, aes(y = Cumulative_Actual_Returns, x = time(CAPM_Materials), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = CAPM_Materials$Cumulative_Normal_Returns, ymax = CAPM_Materials$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = CAPM_Materials$Cumulative_Normal_Returns, x = time(CAPM_Materials)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Excess Return from Augmented CAPM - Materials Sector")

CAPM_Consumer_Discretionary = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  CAPM_Consumer_Discretionary[i,1] = sum(CAPM_Normal_returns[1:i,3])
  CAPM_Consumer_Discretionary[i,2] = sum(Event_window[1:i,9] - Event_window[1:i,1])
}
colnames(CAPM_Consumer_Discretionary) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(CAPM_Consumer_Discretionary, aes(y = Cumulative_Actual_Returns, x = time(CAPM_Consumer_Discretionary), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = CAPM_Consumer_Discretionary$Cumulative_Normal_Returns, ymax = CAPM_Consumer_Discretionary$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = CAPM_Consumer_Discretionary$Cumulative_Normal_Returns, x = time(CAPM_Consumer_Discretionary)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Excess Return from Augmented CAPM - Consumer Discretionary Sector")

CAPM_Real_Estate = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  CAPM_Real_Estate[i,1] = sum(CAPM_Normal_returns[1:i,4])
  CAPM_Real_Estate[i,2] = sum(Event_window[1:i,10] - Event_window[1:i,1])
}
colnames(CAPM_Real_Estate) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(CAPM_Real_Estate, aes(y = Cumulative_Actual_Returns, x = time(CAPM_Real_Estate), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = CAPM_Real_Estate$Cumulative_Normal_Returns, ymax = CAPM_Real_Estate$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = CAPM_Real_Estate$Cumulative_Normal_Returns, x = time(CAPM_Real_Estate)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Excess Return from Augmented CAPM - Real Estate Sector")

CAPM_Financials = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  CAPM_Financials[i,1] = sum(CAPM_Normal_returns[1:i,5])
  CAPM_Financials[i,2] = sum(Event_window[1:i,11] - Event_window[1:i,1])
}
colnames(CAPM_Financials) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(CAPM_Financials, aes(y = Cumulative_Actual_Returns, x = time(CAPM_Financials), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = CAPM_Financials$Cumulative_Normal_Returns, ymax = CAPM_Financials$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = CAPM_Financials$Cumulative_Normal_Returns, x = time(CAPM_Financials)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Excess Return from Augmented CAPM - Financials Sector")

CAPM_Consumer_Staples = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  CAPM_Consumer_Staples[i,1] = sum(CAPM_Normal_returns[1:i,6])
  CAPM_Consumer_Staples[i,2] = sum(Event_window[1:i,12] - Event_window[1:i,1])
}
colnames(CAPM_Consumer_Staples) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(CAPM_Consumer_Staples, aes(y = Cumulative_Actual_Returns, x = time(CAPM_Consumer_Staples), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = CAPM_Consumer_Staples$Cumulative_Normal_Returns, ymax = CAPM_Consumer_Staples$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = CAPM_Consumer_Staples$Cumulative_Normal_Returns, x = time(CAPM_Consumer_Staples)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Excess Return from Augmented CAPM - Consumer Staples Sector")

CAPM_Energy_Utilities = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  CAPM_Energy_Utilities[i,1] = sum(CAPM_Normal_returns[1:i,7])
  CAPM_Energy_Utilities[i,2] = sum(Event_window[1:i,13] - Event_window[1:i,1])
}
colnames(CAPM_Energy_Utilities) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(CAPM_Energy_Utilities, aes(y = Cumulative_Actual_Returns, x = time(CAPM_Energy_Utilities), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = CAPM_Energy_Utilities$Cumulative_Normal_Returns, ymax = CAPM_Energy_Utilities$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = CAPM_Energy_Utilities$Cumulative_Normal_Returns, x = time(CAPM_Energy_Utilities)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Excess Return from Augmented CAPM - Energy & Utilities Sector")

CAPM_Others = cbind(Port_return_data[968:984,7], rep(NA, 17))
for (i in 1:17)
{
  CAPM_Others[i,1] = sum(CAPM_Normal_returns[1:i,8])
  CAPM_Others[i,2] = sum(Event_window[1:i,14] - Event_window[1:i,1])
}
colnames(CAPM_Others) = c("Cumulative_Normal_Returns","Cumulative_Actual_Returns")
ggplot(CAPM_Others, aes(y = Cumulative_Actual_Returns, x = time(CAPM_Others), colour = "red", show.legend = FALSE)) +
  geom_ribbon(aes(ymin = CAPM_Others$Cumulative_Normal_Returns, ymax = CAPM_Others$Cumulative_Actual_Returns), fill = "pink1", linetype = 0, show.legend = FALSE) +
  geom_line(colour = "red", show.legend = FALSE) +
  geom_line(aes(y = CAPM_Others$Cumulative_Normal_Returns, x = time(CAPM_Others)), colour = "red", linetype = "dashed", show.legend = FALSE) +
  xlab("Date") +
  ylab("Return (%)") +
  ggtitle("Abnormal Excess Return from Augmented CAPM - Others Sector")