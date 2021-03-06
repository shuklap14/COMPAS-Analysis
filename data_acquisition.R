setwd("E:/Anol/Compass Analysis/COMPAS-Analysis")

filename <- "compas.db"
sqlite.driver <- dbDriver("SQLite")
db <- dbConnect(sqlite.driver,
                dbname = "compas.db")

dbListTables(db)

compas <- dbReadTable(db,"compas")
people <- dbReadTable(db,"people")
charge <- dbReadTable(db,"charge")
prisonhistory <- dbReadTable(db,"prisonhistory")
jailhistory <- dbReadTable(db,"jailhistory")
casearrest <- dbReadTable(db,"casearrest")
summary <- dbReadTable(db,"summary")

#Small comment

#EDA

install.packages("DataExplorer") 
library(DataExplorer)


str(compas)
str(people)
people$sex <- as.factor(people$sex)
people$sex <- relevel(x = people$sex,ref = "Male")

#Merging the people and compas data set to include 'race' column in the comaps score
a = merge(compas,people,by = "person_id") 

#Finding distribution of compas score for african-american people
a_blck = subset(a, a$type_of_assessment == "Risk of Recidivism" & a$race == "African-American" )
plot(density(a_blck$decile_score.x), lwd = 3, col = "red", xlim = c(0,12), main = "Plot")
par(new = TRUE)

#Finding distribution of compas score for native american and other people
a_white = subset(a, a$type_of_assessment == "Risk of Recidivism" & a$race != "African-American" )
plot(density(a_white$decile_score.x), add = TRUE, col = "blue", lwd =3, xlim = c(0,12), main = "Plot")

summary(a_white$race)
summary(a_blck$race)
#The plot shows that african american people have more high risk numbers by COMPAS compared to other races.

#Replicating Compass Analysis
setwd("F:/Anol/Rdata_CompasDB")
library(rio)
compas = import("Compas.Rdata")
prisonhistory = import("prisonhistory.Rdata")
people = import("people.Rdata")
charge = import("charge.Rdata")
jailhistory = import("jailhistory.Rdata")
casearrest = import("casearrest.Rdata")


write.csv(compas,"Compas_data.csv")
write.csv(prisonhistory,"prisonhistory_data.csv")
write.csv(people,"people_data.csv")
write.csv(charge,"charge_data.csv")
write.csv(jailhistory,"jailhistory_data.csv")
write.csv(casearrest,"casearrest_data.csv")
