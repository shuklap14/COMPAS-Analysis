install.packages("RSQLite")
install.packages("blob")
install.packages("stargazer")
install.packages("ggplot2")
install.packages("scales")
library(stargazer)
library(RSQLite)
library(ggplot2)
library(DataExplorer)
library(lattice)
library(scales)
library(dplyr)



#Linear Regression for the Compass Decile score prediction

setwd("C:/USF - BAIS/Anol/Compass Analysis")

d <- read.csv("compas_with_drug_details.csv")
attach(d)
#detach(d)
summary(d)
head(d)
dim(d)

#histogram of decile score
hist(log(d$decile_score),breaks = 8)

#removing unwanted columns:

colnames(d)
unwanted_cols = c('id','key','age_cat','dob','r_days_from_arrest','days_b_screening_arrest',"c_case_number",
                  "c_offense_date","c_arrest_date","c_days_from_compas",'type_of_assessment', 'v_type_of_assessment',
                  'screening_date','num_vr_cases','num_r_cases', 'decile_score.1')

d = drop_columns(data = d, ind = unwanted_cols)

#Data Manipulation

d$race <- relevel(d$race, ref = "Caucasian") #Relevel the race to caucasian
d$is_recid <- factor(d$is_recid,) #factorize the is_recid flag, 0 = NO , 1 = Yes
d$is_violent_recid <- factor(d$is_violent_recid) #factorize is_voilent_recid flag, 0 = NO , 1 = Yes
d$druginvolvment <- factor(d$druginvolvment) #factorize drug involvment flag, 0 = NO , 1 = Yes
d$length_of_stay = d$length_of_stay + 1 #adding 1 to all the records as some preprocessing has computed release on same day as -1 or release day after as 0 and so on. 

#Charge Degree_factors

table(d$charge_degree_fact)
#removing Charge degree F5,F6,F7 as there are only 6 records of them combined in the data and no significance was found online about these charge degrees

d = d[!((d$charge_degree_fact == 'F5') | (d$charge_degree_fact == 'F6') | (d$charge_degree_fact == 'F7')),]
table(d$charge_degree_fact)
dim(d)


#DATA SPLIT INTO TRAIN TEST
set.seed(101)
#install.packages("caret")
#library(caret)
train.index <- createDataPartition(d$is_recid, p = .7, list = FALSE)
train <- d[ train.index,]
test  <- d[-train.index,]

table(train$is_recid)
table(train$druginvolvment)
table(test$is_recid)
table(test$druginvolvment)
#balanced sampling

install.packages("ROSE")
library(ROSE)

train_data_balanced <- ovun.sample(is_recid ~.,data = train,method = "over")$data
train_data_balanced = na.omit(train_data_balanced)
table(train_data_balanced$is_recid)


boxplot(train_data_balanced$length_of_stay)
IQR(train_data_balanced$length_of_stay)

#d = subset(d, d$length_of_stay <= 500)#removing records where length of stay is greater than 500





#Correlation matrix
cordf = cor(d[,unlist(lapply(d, is.numeric))])
corrplot::corrplot(cordf)

#ScatterPlots
library(ggplot2)

ggplot(data = d, aes(decile_score)) +
  geom_bar(aes(fill= d$race)) +
  ggtitle("Decile Score by Race") +
  xlab(" Decile Score for Risk of Recividism ") +
  ylab("Frequency")

ggplot(data = d, aes(decile_score,age)) + 
geom_point(color = 'steelblue') + 
ggtitle(" Decile score vs Age") +
geom_smooth(method = 'lm', color = 'red')

ggplot(data = d, aes(decile_score,priors_count)) + 
geom_point(color = 'steelblue') + 
ggtitle(" Decile score vs Priors Count") +
geom_smooth(method = 'gam', color = 'red', formula = y ~ s(x, bs = "cs"))

ggplot(data = d, aes(charge_degree_fact)) +
geom_bar(color = 'steelblue') + 
ggtitle ("Chrage Degree Distribution")

ggplot(data = d, aes(sort(charge_degree_fact, decreasing = TRUE))) +
geom_bar(color = 'red') +
ggtitle ("Chrage Degree Distribution") + 
xlab(" Charge Degrees")+
ylab("Frequency")

pairs(~age+decile_score+race+priors_count+juv_fel_count+juv_misd_count+score_text,data=d,main="Simple Scatterplot Matrix")


#################################################################################################################################

###########################
# Predicting Decile Score #
###########################


#Simple LR model withouth Interaction
# all variables that might generate decile score i.e. age, juv count, sex and race

m0_decile_all = lm(log(decile_score) ~ age + juv_fel_count + juv_misd_count + sex + priors_count + race ,d)
summary(m0_decile_all)
plot(m0_decile_all)
#-------------------------------

#Simple LR model with Race and Sex Interaction

m0_decile_all_interaction = lm(log(decile_score) ~ age + juv_fel_count + juv_misd_count + sex*race + priors_count, d)
summary(m0_decile_all_interaction)
plot(m0_decile_all_interaction)
#-------------------------------

#Checking the effect of crime factors on decile score
m0_decile_crime_factors = lm(log(decile_score) ~ juv_fel_count + juv_misd_count + priors_count ,d) #normality fails
summary(m0_decile_crime_factors)
plot(m0_decile_crime_factors)

m0_decile_crime_factors_squareterms = lm(log(decile_score) ~ juv_fel_count + juv_misd_count + priors_count + I(priors_count^2) ,d)
summary(m0_decile_crime_factors)
plot(m0_decile_crime_factors)

#------------------------------

#Checking the effect of Race and Sex interaction term in predicting Decile score
m0_decile_raceandsex = lm(log(decile_score) ~ sex*race, d)
summary(m0_decile_raceandsex)
plot(m0_decile_raceandsex)

stargazer(m0_decile_all,m0_decile_all_interaction,m0_decile_crime_factors,m0_decile_raceandsex,type = 'text')

#################################################################################################################3

#############################
# Predicting the Recidivism #
#############################


#checking if Decile score is a good predictor of Recidivism

# set.seed(101)
# install.packages("caret")
# library(caret)
# train.index <- createDataPartition(d$is_recid, p = .7, list = FALSE)
# train <- d[ train.index,]
# test  <- d[-train.index,]
# table(d$is_recid)

#############################

#install.packages("ModelMetrics")
library(dplyr)
library(ModelMetrics)

#GLM model to predict recidivism using using all other factors withouth interaction

m1_recid_no_decile = glm(is_recid ~ age + juv_fel_count + juv_misd_count + priors_count + length_of_stay + druginvolvment + sex + race, family =binomial , data = train)
summary(m1_recid_no_decile)
plot(m1_recid_no_decile)


#Evaluation matrix - m1_recid_no_decile
pred_no_decile = m1_recid_no_decile %>% predict.glm(test,type="response") %>% {if_else(.> 0.5 , 1,0)} %>% as.factor(.)
ModelMetrics::confusionMatrix(test$is_recid,pred_no_decile)
rmse(test$is_recid,pred_no_decile)
f1Score(test$is_recid,pred_no_decile)
roc.curve(test$is_recid,pred_no_decile)


#------------------------------

#GLM model to predict recidivism using all the crime related factors 
m1_recid_crime_factors = glm(is_recid ~ juv_fel_count + juv_misd_count + priors_count + as.factor(druginvolvment) + length_of_stay, family =binomial , data = train)
summary(m1_recid_crime_factors)
plot(m1_recid_crime_factors)


pred_crime_factor = m1_recid_crime_factors %>% predict.glm(test,type="response") %>%{if_else(.>0.5,1,0)}%>% as.factor(.)
confusionMatrix(test$is_recid,pred_crime_factor)
rmse(test$is_recid,pred_crime_factor)
f1Score(test$is_recid,pred_crime_factor)
roc.curve(test$is_recid,pred_crime_factor)


#------------------------------

#GLM mode using decile score alone as predictor of recidivism
m1_recid_decilescore = glm(is_recid ~ decile_score, family =binomial , data = train)
summary(m1_recid_decilescore)
plot(m1_recid_decilescore)


#Evaluation matrix - m1_recid_decilescore
pred_decile = m1_recid_decilescore %>% predict.glm(test,type="response") %>% {if_else(.>0.5,1,0)}%>%as.factor(.)
confusionMatrix(test$is_recid,pred_decile)
rmse(test$is_recid,pred_decile)
f1Score(test$is_recid,pred_decile)
roc.curve(test$is_recid,pred_decile)


#------------------------------

#GLM model using race and sex alone as a predictor of recidivism
m1_recid_sex_race = glm(is_recid ~ sex*race, family =binomial , data = train)
summary(m1_recid_sex_race)
plot(m1_recid_sex_race)


#Model 4 - Sex and Race Interaction alone
pred_sexandRace = m1_recid_sex_race %>% predict.glm(test,type="response") %>% {if_else(.>0.5,1,0)}%>%as.factor(.)
confusionMatrix(test$is_recid,pred_sexandRace)
rmse(test$is_recid,pred_sexandRace)
f1Score(test$is_recid,pred_sexandRace)
roc.curve(test$is_recid,pred_sexandRace)

#------------------------------
library(stargazer)
stargazer(m1_recid_no_decile,m1_recid_crime_factors,m1_recid_decilescore,m1_recid_sex_race,type = 'text')


################################################################################################################

#Running the models to determine the violent recidivism based on all the factors like above:

#GLM model to predict Voilent recidivism using using all other factors withouth interaction

Vtrain.index <- createDataPartition(d$is_violent_recid, p = .7, list = FALSE)
Vtrain <- d[ train.index,]
Vtest  <- d[-train.index,]

#model 1 - without decile score

m1_Vrecid_no_decile = glm(is_violent_recid ~ age + juv_fel_count + juv_misd_count + priors_count +as.factor(druginvolvment) + length_of_stay + sex + race+charge_degree_fact, family =binomial , data = Vtrain)
summary(m1_recid_no_decile)
plot(m1_recid_no_decile)

#Evaluation matrix - m1_Vrecid_no_decile
Vpred_no_decile = m1_Vrecid_no_decile %>% predict.glm(Vtest,type="response") %>% {if_else(.>0.5,1,0)} %>% as.factor(.)
confusionMatrix(Vtest$is_violent_recid,Vpred_no_decile)
rmse(Vtest$is_violent_recid,Vpred_no_decile)
f1Score(Vtest$is_violent_recid,Vpred_no_decile)
roc.curve(Vtest$is_violent_recid,Vpred_no_decile)

#------------------------------

#GLM model to predict recidivism using all the crime related factors 
m1_Vrecid_crime_factors = glm(is_violent_recid ~ juv_fel_count + juv_misd_count + priors_count + as.factor(druginvolvment) + length_of_stay+ charge_degree_fact, family =binomial , data = Vtrain)
summary(m1_recid_crime_factors)
plot(m1_recid_crime_factors)

#Evaluation matrix - m1_Vrecid_crime_factors
Vpred_crime_factor = m1_Vrecid_crime_factors %>% predict.glm(Vtest,type="response" ) %>% {if_else(.>0.5,1,0)} %>% as.factor(.)
confusionMatrix(Vtest$is_violent_recid,Vpred_crime_factor)
rmse(Vtest$is_violent_recid,Vpred_crime_factor)
f1Score(Vtest$is_violent_recid,Vpred_crime_factor)
roc.curve(Vtest$is_violent_recid,Vpred_crime_factor)

#------------------------------

#GLM model to predict the using decile score as predictor of recidivism
m1_Vrecid_decilescore = glm(is_violent_recid ~ v_decile_score, family =binomial , data = Vtrain)
summary(m1_recid_decilescore)
plot(m1_recid_decilescore)


#Evaluation matrix - m1_Vrecid_decilescore
Vpred_decile = m1_Vrecid_decilescore %>% predict.glm(Vtest,type="response" ) %>% {if_else(.>0.2,1,0)} %>% as.factor(.) #since max probability is 0.25978 (calculated using summary before converting into factor)
confusionMatrix(Vtest$is_violent_recid,Vpred_decile)
rmse(Vtest$is_violent_recid,Vpred_decile)
f1Score(Vtest$is_violent_recid,Vpred_decile)
roc.curve(Vtest$is_violent_recid,Vpred_decile)

#------------------------------

#using race and sex alone as a predictor of recidivism
m1_Vrecid_sex_race = glm(is_violent_recid ~ sex*race, family =binomial , data = Vtrain)
summary(m1_recid_sex_race)
plot(m1_recid_sex_race)


#Evaluation matrix - m1_Vrecid_sex_race
Vpred_sexandRace = m1_Vrecid_sex_race %>% predict.glm(Vtest,type="response") %>% {if_else(.>0.3,1,0)} %>% as.factor(.) #since max probability is 0.25978 (calculated using summary before converting into factor)
confusionMatrix(Vtest$is_recid,Vpred_sexandRace)
rmse(Vtest$is_violent_recid,Vpred_sexandRace)
f1Score(Vtest$is_violent_recid,Vpred_sexandRace)
roc.curve(Vtest$is_violent_recid,Vpred_sexandRace)

#------------------------------

library(stargazer)
stargazer(m1_Vrecid_no_decile,m1_Vrecid_crime_factors,m1_Vrecid_decilescore,m1_Vrecid_sex_race,type = 'text' )



################################################################################################################


#Computing a fair score matrix by considering only the crime factors as per the model m0_decile_crime_factors!


d$myscore = round(exp(m1_recid_crime_factors$coefficients[1]) + exp(m1_recid_crime_factors$coefficients[2])*d$juv_fel_count + exp(m1_recid_crime_factors$coefficients[3])*d$juv_misd_count + exp(m1_recid_crime_factors$coefficients[4])*d$priors_count + exp(m1_recid_crime_factors$coefficients[5])*as.numeric(d$druginvolvment) + exp(m1_recid_crime_factors$coefficients[6])*d$length_of_stay)
summary(d$myscore)
#d$myscore = d$myscore + 2
#having rounded of values of -1 and 0 ?
hist(d$myscore, breaks = 10)

d$scaledmyscore = round(rescale(d$myscore,to= c(1,10)))
summary(d$scaledmyscore)
hist(d$scaledmyscore)

summary(d$decile_score)
hist(d$decile_score, breaks = 10)

c1 <- rgb(173,216,230,max = 255, alpha = 80, names = "lt.blue")
c2 <- rgb(255,192,203, max = 255, alpha = 80, names = "lt.pink")

#d$scaledmyscore <- ifelse(d$scaledmyscore == 0 ,d$scaledmyscore+1,d$scaledmyscore) 
#summary(d$scaledmyscore)

hist(d$decile_score, breaks = 10, col = c1, ylim = c(0,6500),main = NULL)
hist(d$scaledmyscore,breaks = 10, col = c2, add = TRUE)
title("Histogram of Comaps-Decile score and My score")
legend("topright", c("Decile Score", "My Score"), col=c(c1, c2), lwd=10)


d_africanamerica = subset(d, race == 'African-American', select = c('decile_score','myscore','scaledmyscore'))
hist(d_africanamerica$decile_score, col= c2, ylim=c(0,3000), main = NULL)
hist(d_africanamerica$scaledmyscore, col = c1, add =  TRUE)
title(" Comparing decile scores for african-american race population ")
legend("topright", c("My Score", "Decile Score"), col=c(c1, c2), lwd=10)

##########################################################################################################

#Checking the records where decile score is same as my score

table(d$decile_score, d$scaledmyscore)

d$same_score  = if_else(d$decile_score == d$scaledmyscore,"Yes","No")
table(d$same_score)

#so only records where decile score is 1,2,3 (i.e. low score) is matching with My_score since my score is very skewed towards lower scores.

#Checking percent difference in decile score and my score

d$score_diff_percent = (d$decile_score - d$scaledmyscore / d$decile_score)*100
summary(d$score_diff_percent)


#Checking if the new scaled my score is a good predictor of recidivism

myscore_train.index = caret::createDataPartition(d$is_recid, p = 0.7, list = FALSE)
myscore_train = d[myscore_train.index,]
myscore_test = d[-myscore_train.index,]

table(myscore_test$is_recid)
#GLM to test the myscore against recidivism

myscore_recid = glm(is_recid ~ scaledmyscore, family = binomial, data = myscore_train)
summary(myscore_recid)

pred_myscore_recid = myscore_recid %>% predict.glm(myscore_test,type="response") %>% {if_else(.>0.3,1,0)} %>% as.factor(.) #since min probability is 0.2078 (calculated using summary before converting into factor)
confusionMatrix(myscore_test$is_recid,pred_myscore_recid)
rmse(myscore_test$is_recid,pred_myscore_recid)
f1Score(myscore_test$is_recid,pred_myscore_recid)
roc.curve(myscore_test$is_recid,pred_myscore_recid)
ModelMetrics::precision(myscore_test$is_recid,pred_myscore_recid)
ModelMetrics::recall(myscore_test$is_recid,pred_myscore_recid)

table(myscore_test$is_recid)

#with myscore we are able to classifiy all the recidivist correctly however the False Negative (False classified as Recidivist) Numbers are too high

#I guess the my score is being affected by the outlier values in variable 'length of stay'
summary(d$length_of_stay)
summary(myscore_train$length_of_stay)

#How do we scale it ? do we use log transform ? or we remove outliers by finding IQR ?