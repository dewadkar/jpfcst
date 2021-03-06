#install.packages("reshape")
#install.packages("corrplot")
library(reshape)
library(corrplot)

#filter out meters that do not contribute value
filter <- !(meterdata$id %in% c("04764786-1E05-4DF6-9EC0-415BEBF13E00","0A5FAB9D-79BC-428E-80F7-3276E2D75CF5","16C8B35C-16CB-4A77-8353-331894B1416E","1F0DB3C7-87A8-476E-972E-438B97BFC7A3","24D16E37-83EA-4EB9-9BAA-439BE727B24E","42264AC5-A1CD-41C9-B70C-1F7E60D90EDB","8E75323C-8AD7-4020-8386-255899D57736","97652C30-BA6D-4ED7-9CD1-8A5B3D84DCD0","B69A65AA-F891-487E-8403-4510C38A4ED2","C3CD56B5-43FA-4753-A649-A8CF1F1BCF8B","CCA4AD51-8C5C-4A10-908A-68045B5BAD75","DAD06492-4580-4882-9CDB-BC43DFB46AFB","DAEC18B2-75EB-4C19-BC64-DE1CC4354061","E9D6382A-738C-49B8-9A75-3E59169FAE6C","F0AE40D8-E472-4C73-8B22-C718A246CC18","F215B0D5-A37A-40F8-B70E-5FCF921BE4AF","F5F07681-7291-4F52-8E60-BFCE3DE6A2D8","F7A08728-7930-4B79-BF12-DC78DCFE6B50","FDBF0F6E-1200-4D40-B475-B974050A2719","88301EF1-8539-4818-A1FE-114B6488EA71","9BFEA289-890D-451A-BCDB-803E4518837E","A8D81B5B-8C4A-4550-936A-6B695D5384A0","EA61A98A-9107-4D3E-A324-8DFA795F1AA2","29F87904-6A07-44BA-8B4B-1F41B1855D24"))
mtr.f <- meterdata[which(filter),]

#transpose to have dates as columns
mtr.dtscol <- cast(mtr.f, id ~ ts, value = "val")
write.csv(mtr.dtscol, file = "./outs/transposed.csv")

#transpose to have meters as columns
mtr.mtrcol <- t(mtr.dtscol)
C1 <- cor(na.omit(mtr.mtrcol), use = "pairwise.complete.obs", method = "kendall")
write.csv(C1, "./outs/correlations.csv")

# rownames(C1) <- c(1:nrow(C1))
# colnames(C1) <- c(1:ncol(C1))

#cluster and plot
hc <- hclust(dist(abs(cor(C1))))

pdf("./outs/dendogram.pdf")
plot(hc, cex = 0.25, hang = -1)
rhc <- rect.hclust(hc, k = 15, border = 2)
dev.off()

#get representative timeseries for each cluster
grpno<- NULL
rep.ids <- NULL
for (i in 1 : length(rhc)){
  # subset data
  grpno <- c(grpno, unlist(x = rhc[[i]], recursive = T, use.names = T))
  id <- names(rhc[[i]])
  mtr.clstr.i <- mtr.mtrcol[, c(id)]

  #get group wise correlations
  C2 <-  cor(na.omit(mtr.clstr.i), use = "pairwise.complete.obs", method = "kendall")
  C3 <- abs(C2)
  # C3$avg <- rowMeans(C3)
  write.csv(C3, paste0("./outs/correlations", i ,".csv"))
  
  #get representative timeseries id for each group
  cl.mns <- colMeans(C3)
  rep.mtr.id <- names(cl.mns)[match(max(cl.mns), cl.mns)]
  rep.ids <- c(rep.ids, rep.mtr.id)
  
  #plot groups
  filter.cluster <- (mtr.f$id %in% c(id))
  plotmeters(mtr.f[which(filter.cluster), ], paste0("./outs/correlations", i , "-", rep.mtr.id, ".pdf"))
  }


print(rep.ids)

i=1

