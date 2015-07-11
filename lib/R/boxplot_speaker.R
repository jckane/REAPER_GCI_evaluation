# Boxplot metrics (separately) as a function of algorithm type
# at the speaker level

# Rscript command line functionality
args <- commandArgs(TRUE)

# Organize input arguments
metricsCSV <- args[1]
RLibrary <- args[2]
output_directory <- args[3]

data <- read.table(metricsCSV,header=FALSE,sep=",")
library(reshape2,lib.loc=RLibrary)
library(ggplot2,lib.loc=RLibrary)

metrics <- data[,2:5]
names(metrics) <- c("IR","MR","FAR","IDA")
ID <- as.character(data[,1])
N <- length(ID)
Algorithm <- array("",N)
Dataset <- array("",N)
SpeakerID <- array("",N)
for ( n in seq(N) ) {
    Algorithm[n] <- unlist(strsplit(ID[n],"/"))[1]
    Dataset[n] <- unlist(strsplit(ID[n],"/"))[2]
    SpeakerID[n] <- unlist(strsplit(ID[n],"/"))[3]
}

labels <- cbind(Algorithm,Dataset,SpeakerID)
colnames(labels) <- c("Algorithm","Dataset","SpeakerID")
all_labels <- rbind(labels,labels,labels,labels)
all_metrics <- melt(metrics)
df <- data.frame(all_labels, all_metrics)
df_IR <- df[df[,4]=="IR",]
df_MR <- df[df[,4]=="MR",]
df_FAR <- df[df[,4]=="FAR",]
df_IDA <- df[df[,4]=="IDA",]

# Do boxplotting
output_path <- paste(output_directory,
                     "GCI_metrics_speaker_level.pdf",
                     sep=.Platform$file.sep)
pdf(output_path,width=10,height=8)
p1 <- ggplot(df, aes(Algorithm,value,fill=Algorithm)) +
  geom_boxplot() + facet_wrap(~variable,scale="free") +
  ggtitle("GCI metrics at the speaker level")
print(p1)
TMP <- dev.off()

# Do ANOVAs
output_path <- paste(output_directory,
                     "ANOVA_IR_speaker_level.csv",
                     sep=.Platform$file.sep)
IR.aov <- aov(value ~ Algorithm, data=df_IR)
sink(output_path)
summary(IR.aov)
TukeyHSD(IR.aov)
sink()

output_path <- paste(output_directory,
                     "ANOVA_MR_speaker_level.csv",
                     sep=.Platform$file.sep)
MR.aov <- aov(value ~ Algorithm, data=df_MR)
sink(output_path)
summary(MR.aov)
TukeyHSD(MR.aov)
sink()

output_path <- paste(output_directory,
                     "ANOVA_FAR_speaker_level.csv",
                     sep=.Platform$file.sep)
FAR.aov <- aov(value ~ Algorithm, data=df_FAR)
sink(output_path)
summary(FAR.aov)
TukeyHSD(FAR.aov)
sink()

output_path <- paste(output_directory,
                     "ANOVA_IDA_speaker_level.csv",
                     sep=.Platform$file.sep)
IDA.aov <- aov(value ~ Algorithm, data=df_IDA)
sink(output_path)
summary(IDA.aov)
TukeyHSD(IDA.aov)
sink()
