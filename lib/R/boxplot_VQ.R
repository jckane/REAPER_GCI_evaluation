# Boxplot metrics (separately) as a function of algorithm type
# at the speaker level

# Rscript command line functionality
args <- commandArgs(TRUE)

# Organize input arguments
metricsCSV <- args[1]
RLibrary <- args[2]
output_directory <- args[3]


#data_file <- "/Users/jkane/Desktop/GCI_study/REAPER_GCI_evaluation/BUILD/Results/metrics_by_VQ.csv"
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
VQ <- array("",N)
for ( n in seq(N) ) {
  Algorithm[n] <- unlist(strsplit(ID[n],"/"))[1]
  Dataset[n] <- unlist(strsplit(ID[n],"/"))[2]
  SpeakerID[n] <- unlist(strsplit(ID[n],"/"))[3]
  VQ[n] <- unlist(strsplit(ID[n],"/"))[4]
}

labels <- cbind(Algorithm,Dataset,SpeakerID,VQ)
colnames(labels) <- c("Algorithm","Dataset","SpeakerID","VQ")
all_labels <- rbind(labels,labels,labels,labels)
all_metrics <- melt(metrics)
df <- data.frame(all_labels, all_metrics)
df_IR <- df[df[,5]=="IR",]
df_MR <- df[df[,5]=="MR",]
df_FAR <- df[df[,5]=="FAR",]
df_IDA <- df[df[,5]=="IDA",]

# Plot IR
output_path <- paste(output_directory,
                     "GCI_IR_by_VQ.pdf",
                     sep=.Platform$file.sep)
pdf(output_path,width=10,height=5)
p1 <- ggplot(df_IR, aes(Algorithm,value,fill=Algorithm)) +
  geom_boxplot() + facet_wrap(~VQ) +
  ggtitle("Identification Rate (IR)")
print(p1)
TMP <- dev.off()

# Plot MR
output_path <- paste(output_directory,
                     "GCI_MR_by_VQ.pdf",
                     sep=.Platform$file.sep)
pdf(output_path,width=10,height=5)
p1 <- ggplot(df_MR, aes(Algorithm,value,fill=Algorithm)) +
  geom_boxplot() + facet_wrap(~VQ) +
  ggtitle("Miss Rate (MR)")
print(p1)
TMP <- dev.off()

# Plot FAR
output_path <- paste(output_directory,
                     "GCI_FAR_by_VQ.pdf",
                     sep=.Platform$file.sep)
pdf(output_path,width=10,height=5)
p1 <- ggplot(df_FAR, aes(Algorithm,value,fill=Algorithm)) +
  geom_boxplot() + facet_wrap(~VQ) +
  ggtitle("False Alarm Rate (FAR)")
print(p1)
TMP <- dev.off()

# Plot IDA
output_path <- paste(output_directory,
                     "GCI_IDA_by_VQ.pdf",
                     sep=.Platform$file.sep)
pdf(output_path,width=10,height=5)
p1 <- ggplot(df_IDA, aes(Algorithm,value,fill=Algorithm)) +
  geom_boxplot() + facet_wrap(~VQ) +
  ggtitle("Identification Accuracy (IDA)")
print(p1)
TMP <- dev.off()

