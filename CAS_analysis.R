setwd('C:/Users/thanh/OneDrive/Máy tính/CAS projects')
#===================
# 1.IMPORT PACKAGES
#===================
library(tidyverse)
library(ggplot2)
library(lme4)
library(car)

#============
# 2.READ DATA
#============
df<-read.csv('./CAS_raw_data.csv')

#=====================
# 3.PREPROCESSING DATA
#=====================
# 3.1.DATE TIME CONVESION
df$Date<-as.Date(df$Date,format = '%d/%m/%Y')
# 3.2.FACTOR CONVERSION
df$Fertilizer<-as.factor(df$Fertilizer)
df$PlantID<-as.factor(df$PlantID)

#====================
# 4.DATA PREPARARTION
#====================
df<-df %>% 
  arrange(PlantID,Date) %>% 
  group_by(PlantID) %>%
  mutate(day=as.numeric(Date-min(Date))) %>%
  ungroup()

df_growth <- df %>%
  group_by(PlantID, Fertilizer) %>%
  summarise(
    leaf_start = first(LeafSize_cm),
    leaf_end   = last(LeafSize_cm),
    leaf_growth = leaf_end - leaf_start
  ) %>%
  ungroup()

#==================
# 5.OVERVVIEW DATA
#==================
# 5.1.DATA DIMENSION
dim_df<-dim(df)
paste('The number of rows:',dim_df[1])
paste('The number of columns:',dim_df[2])
# 5.2.COLUMNS INFORMATION
column_names<-colnames(df)
column_names
paste('Columns:',paste(column_names,collapse =', '))
# 4.3.DATA TYPES OF EACH COLUMN
for (column in column_names) {
  column_data<-df[,column]
  column_type<-class(column_data)
  print(paste('Data type of',column,':',column_type))
}

#=================================
# 5.EDA (EXPLORATORY DATA ANALYSIS)
#=================================
# 5.1.OVERVIEW COMPOSTS DATA
composts<-unique(df$Fertilizer)
paste('Compost types:',paste(composts,collapse = ', '))
df %>% count(Fertilizer)
# 5.2.MEAN OF LEAF
df_leaf<-df[c('Fertilizer','LeafSize_cm','Date')]
df_leaf_mean<-pivot_wider(data = df_leaf,id_cols = 'Date',
                          names_from = 'Fertilizer',
                          values_from = 'LeafSize_cm',
                          values_fn = mean)
df_leaf_mean[-1]<-round(df_leaf_mean[-1],2)
# 5.3.STANDARD DEVIATION OF LEAF
df_leaf_std<-pivot_wider(data = df_leaf,id_cols = 'Date',
                         names_from = 'Fertilizer',
                         values_from = 'LeafSize_cm',
                         values_fn = sd)
df_leaf_std[-1]<-round(df_leaf_std[-1],2)
# 5.4.MEDIAN VALUE OF LEAF
df_leaf_median<-pivot_wider(data = df_leaf,
                            id_cols = 'Date',
                            names_from = 'Fertilizer',
                            values_from = 'LeafSize_cm',
                            values_fn = median)
# 5.5.MIN VALUE OF LEAF
df_leaf_min<-pivot_wider(data = df_leaf,
                            id_cols = 'Date',
                            names_from = 'Fertilizer',
                            values_from = 'LeafSize_cm',
                            values_fn = min)
# 5.6.MAX VALUE OF LEAF
df_leaf_max<-pivot_wider(data = df_leaf,
                            id_cols = 'Date',
                            names_from = 'Fertilizer',
                            values_from = 'LeafSize_cm',
                            values_fn = max)

#======================
# 6.STATISTICAL ANALYSIS
#======================
# 6.1.ONE-WAY ANOVA
anova_model<-aov(leaf_growth ~ Fertilizer,data=df_growth)
summary(anova_model)
# 6.2.POST-HOC TEST
TukeyHSD(anova_model)
shapiro.test(residuals(anova_model))
leveneTest(leaf_growth ~ Fertilizer,data=df_growth)
# 6.3.LINER MIX MODEL
model<-lmer(LeafSize_cm ~ Fertilizer*day+(1|PlantID),data = df)
summary(model)
anova(model)
emmeans(model_lmm, pairwise ~ Fertilizer)
emmeans(model_lmm, pairwise ~ Fertilizer | day)

#=====================
# 7.DATA VISUALIZATION
#=====================
# 7.1.LINE PLOT
ggplot(data = df,
       mapping = aes(x = day,y =LeafSize_cm,colour = Fertilizer))+
  stat_summary(fun = mean, geom = 'line', linewidth =1) +
  stat_summary(fun = mean, geom='point') +
  labs(x='Day',y='Height (cm)',title = 'Leaf size of different organic composts across month')+
  theme_minimal()
# 7.2.BOX PLOT
ggplot(data = df,
       mapping = aes(x = Fertilizer,y = LeafSize_cm, fill = Fertilizer))+
  geom_boxplot()+
  labs(x='Fertilizer',y='Leaf size (cm)',title = 'Leaf size of different organic composts across a month')+
  theme_minimal()