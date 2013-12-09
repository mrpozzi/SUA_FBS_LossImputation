# /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~* 
# ***Note***		 
# This do-file takes the raw data from the SUA Working System ("SUA_waste.csv" - downloaded by Amanda Gordon (ESS)) 
# and makes two things: 
 
# 1) Commodities are categorized into commodity groups. I found no directory for item groups, so I copied 
# the item codes from the FAOSTAT Working System and categorized them with loops.  
# In any case, a directory file which links each item to a itemgroups would replace this long procedure... 
 
# 2) Reshape the data from wide to long. Since the whole dataset is too large for my (old) computer I split it 
# into pieces and afterwards I put the reshaped pieces together. A more powerful computer might do it at one shot! 
 
# Explanation of the variables: 
# itemcode ... ID of the item 
# elementcode ... ID of the element: 51 for Production, 61 for Imports, 71 for Stock variation, 91 for Exports 
                # and 121 for Losses				 
# num_x ... quantities of element x (in 1000 metric tons) for given year and country 
# symb_x ... flag of num_x.  
 
 
# *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/ 
 

wasteSUA<-read.csv("csv/SUA_waste.csv",stringsAsFactors=FALSE)

colnames(wasteSUA)[3] <- "AreaCode"
colnames(wasteSUA)[4] <- "ItemCode"
colnames(wasteSUA)[5] <- "ElementCode"


wasteSUA[,grep("SYMB",colnames(wasteSUA))][wasteSUA[,grep("SYMB",colnames(wasteSUA))]==" "] <-NA

### manipulation

 
wasteSUA$foodgroup <- labelFoods(wasteSUA$ItemCode)

wasteSUA <- reshape(wasteSUA, dir = "long", varying = -c(1:5,ncol(wasteSUA)), sep = "_")
wasteSUA <- wasteSUA[,colnames(wasteSUA)!="id"]


numVar <-  unique(wasteSUA$ElementCode)
wasteSUA <- do.call(rbind,lapply(unique(wasteSUA$AreaCode),function(area){
	X <- wasteSUA[wasteSUA$AreaCode==area,]
	
	do.call(rbind,lapply(unique(X$ItemCode),function(item){
		Y <- X[X$ItemCode==item,]

		Z <- reshape(Y, dir = "wide",timevar = "ElementCode",sep = "_", v.name = c("NUM","SYMB"),idvar="time")
		
		missingCols <-setdiff(c("AreaName","AreaCode","ItemCode","time",paste("NUM",numVar,sep="_"),paste("SYMB",numVar,sep="_")),colnames(Z))
		
		if(length(missingCols) > 0L){
			#classMissing <- lapply(A[,missingCols,with = FALSE], class)
			nas <- lapply(rep("numeric",length(missingCols)), as, object = NA)
			Z[,missingCols] <- nas
			}
			return(Z[,c("AreaName","AreaCode","ItemCode","time",paste("NUM",numVar,sep="_"),paste("SYMB",numVar,sep="_"))])
			
		}))
	}))

wasteSUA$SYMB_51[is.na(wasteSUA$SYMB_51)] <- "_"
wasteSUA$SYMB_61[is.na(wasteSUA$SYMB_61)] <- "_"
wasteSUA$SYMB_71[is.na(wasteSUA$SYMB_71)] <- "_"
wasteSUA$SYMB_91[is.na(wasteSUA$SYMB_91)] <- "_"
wasteSUA$SYMB_121[is.na(wasteSUA$SYMB_121)] <- "_"


save(wasteSUA,file="SUA_waste.RData")
