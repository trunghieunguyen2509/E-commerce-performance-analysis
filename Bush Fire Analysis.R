
#Loading the data set
BFdata = read.csv("BushFireData.csv")
attach(BFdata)
#Data overview
head(BFdata)
dim(BFdata)
sum(is.na(BFdata))

#Explore data structure
str(BFdata)
summary(BFdata)

#Encoding construction quality Good and Bad to 1 and 0
BFdata$Construction_Quality = ifelse(BFdata$Construction_Quality == "Good",1,0)

#Encoding insurance coverage: 0 for none, 1 for partially and 2 for fully 
IC_factor = factor(BFdata$Insurance_Coverage, levels = c("None", "Partially", "Fully"))
BFdata$Insurance_Coverage = as.integer(IC_factor) - 1

#Divide 50% of the dataset into training and 50% for testing and remove excess variable
set.seed(2)
tr.id = sample(1:nrow(BFdata),nrow(BFdata)/2)
training = BFdata[tr.id,]
training = training[,-1]
test = BFdata[-tr.id,]
test = test[,-1]
str(training)
str(test)

#Build histogram to explore the distribution of property value as well as building age
par(mfrow = c(3,3))
hist(Fire_Intensity)
hist(Property_Value)
hist(Building_Age)
hist(Emergency_Response_Time)
hist(Wind_Speed)
hist(Humidity)
hist(Damage_Claims)
hist(Distance_from_Fire)
hist(Mitigation_Measures)

#Build box-plot to detect outliers and summarising the distribution of the data set
par(mfrow = c(2,2))
boxplot(Damage_Claims, main = "Damage claims")
boxplot(Property_Value, main = "Property value")
boxplot(Fire_Intensity, main = "Fire intensity")
boxplot(Emergency_Response_Time, main = "Emergency Response Time")

#Correlation matrix for key numerical variables to explore the relationship between them
cor_matrix = BFdata[,c("Fire_Intensity","Distance_from_Fire","Building_Age","Property_Value","Population_Density","Emergency_Response_Time","Wind_Speed","Humidity","Damage_Claims")]
cor(cor_matrix)
pairs(cor_matrix, panel = panel.smooth)

#Build multiple linear regression
m1 = lm(Damage_Claims~.,data = training)
summary(m1)

#New model with only significant variables
m2 = lm(Damage_Claims~Fire_Intensity + Distance_from_Fire + Property_Value + Emergency_Response_Time + Mitigation_Measures + Humidity, data = training)
summary(m2)
anova(m2)

#Checking correlation between pairs of variable
newdata = BFdata[,-1]
cor(training)

#Evaluation using MSE
actual = test$Damage_Claims
predict1 = predict(m2,data = test)
MSE1 = mean((predict1-actual)^2)
MSE1

plot(predict1, actual, xlim =c(2,13),ylim = c(2,13))
abline(0,1)

#Interaction model
m3<-lm(Damage_Claims~(Fire_Intensity+ Distance_from_Fire+ Property_Value+ Emergency_Response_Time+ Mitigation_Measures+ Humidity)^2, data=training)
anova(m3)

#Polynomial model
m4<-lm(Damage_Claims~poly(Fire_Intensity,3) +poly(Distance_from_Fire,3) + poly(Property_Value,3)+ poly(Emergency_Response_Time,3) + poly(Mitigation_Measures,3)+ poly(Humidity,3), data=training)
summary(m4)
#Evaluation using Multivariate model
pr.value = predict(m2)
hist(pr.value)

par(mfrow = c(2,2))
plot(m2)

library(tree)
#Build the regression tree model
tree = tree(Damage_Claims~.,newdata,subset = tr.id)
summary(tree)

#Visualise the tree
par(mfrow = c(1,1))
plot(tree)
text(tree,pretty = 0,cex =0.5)
#Improve the model
set.seed(1)
cv.data = cv.tree(tree)
#Plot to choose the best tree size
plot(cv.data$size,cv.data$dev, type = "b")

#Prune the tree
pruned.model = prune.tree(tree, best = 10)
plot(pruned.model)
text(pruned.model,pretty = 0, cex = 0.7)

#Calculate MSE and RMSE
predict2 = predict(tree, data = test)
MSE2 = mean((predict2-actual)^2)
RMSE2 = sqrt(MSE2)
MSE2
RMSE2

#Plot the predict and actual value for testing data set
plot(predict2,actual, xlim =c(2,13),ylim = c(2,13))
abline(0,1)

#Compare two model using MSE
MSE1
MSE2

#Compare two model using residual plot
par(mfrow = c(1,2))
plot(predict1, actual, xlim =c(2,13),ylim = c(2,13), main = "Multiple linear regression model")
abline(0,1)
plot(predict2,actual, xlim =c(2,13),ylim = c(2,13), main = "Regression tree model")
abline(0,1)

#Modify the target variable
Highdamage = ifelse(newdata$Damage_Claims>7.5,"Yes","No")
Highdamage = as.factor(Highdamage)
newdata2 = data.frame(newdata,Highdamage)
newdata2 = newdata2[,-12]
str(newdata2)

#Build classification tree
training2 = newdata2[tr.id,]
testing2 = newdata2[-tr.id,]
tree_new = tree(Highdamage~.,training2)

#visualise the tree
par(mfrow = c(1,1))
plot(tree_new)
text(tree_new,pretty=0,cex = 0.6)
summary(tree_new)

#Calculate misclassification rate
tree_pred1=predict(tree_new,testing2,type="class")
table = table(tree_pred1,testing2$Highdamage)
misrate1 <- (table[1,2]+table[2,1])/sum(table)
misrate1

#Prunning tree
set.seed(12)
cv.tree_new=cv.tree(tree_new,FUN=prune.misclass)
names(cv.tree_new)
plot(cv.tree_new$size, cv.tree_new$dev, type = "b")

prune.tree_new=prune.misclass(tree_new,best=5)
plot(prune.tree_new)
text(prune.tree_new,pretty=0)

#Calculate misclassification rate
tree.pred2=predict(prune.tree_new,testing2,type='class')
table(tree.pred2,testing2$Highdamage)
tab3 <- table(tree.pred2,testing2$Highdamage)
mis_rate2 <- (tab3[1,2]+tab3[2,1])/sum(tab3)
mis_rate2
