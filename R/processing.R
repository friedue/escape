#' Calculate Principal Components for the Enrichment Scores
#'
#' Using all or selected enrichment scores of individual 
#' single-cells, this function will calculate 
#' principal components using scaled values and attach 
#' to the output columns to use to graph later.
#'
#' @param enriched The output of \code{\link{enrichIt}}.
#' @param groups The column headers to use in future graphing functions.
#'
#' @importFrom dplyr select_if
#' @importFrom stats prcomp
#' 
#' @examples 
#' ES2 <- readRDS(url(
#' "https://ncborcherding.github.io/vignettes/escape_enrichment_results.rds"))
#' PCA <- performPCA(enriched = ES2, groups = c("Type", "Cluster"))
#'
#' @export
#' @return Data frame of principal compoenents
#'
#' @author Nick Borcherding
#'
performPCA <- function(enriched, groups) {
    groups <- enriched[,colnames(enriched) %in% groups]
    input <- select_if(enriched, is.numeric)
    PCA <- prcomp(input, scale. = TRUE)
    merged <- merge(PCA$x, groups, by = "row.names")
    rownames(merged) <- merged[,1]
    merged <- merged[,-1]

    return(merged)
}

#' Get a collection of gene sets to perform enrichment on
#'
#' This function allows users to select libraries and specific 
#' gene.sets to form a GeneSetCollection that is a list of gene sets.
#
#' @param species The scientific name of the species of interest in 
#' order to get correcent gene nomenclature
#' @param library Individual collection(s) of gene sets, e.g. c("H", "C5").
#' See \url{https://www.gsea-msigdb.org/gsea/msigdb/collections.jsp} for
#' all MSigDB collections.
#' @param gene.sets Select gene sets or pathways, using specific names, 
#' example: pathways = c("HALLMARK_TNFA_SIGNALING_VIA_NFKB"). Will only be
#' honored if library is set, too.
#'
#' @examples 
#' GS <- getGeneSets(library = "H")
#' 
#' @export
#' 
#' @importFrom GSEABase GeneSet GeneSetCollection
#' @importFrom msigdbr msigdbr msigdbr_species
#' 
#' @author Nick Borcherding, Jared Andrews
#' @return List of GeneSets in collection format
getGeneSets <- function(species = "Homo sapiens", 
                        library = NULL, gene.sets = NULL) {
    spec <- msigdbr_species()
    spec_check <- unlist(spec[spec$species_name %in% species,][,1])
    if (length(spec_check) == 0) {
        message(paste0("Please select a compatible species: ", 
                    paste(spec, collapse = ", ")))
    }
    
    if(!is.null(library)) {
        if (length(library) == 1) {
            m_df = msigdbr(species = spec_check, category = library)
        }
        m_df <- NULL
        for (x in seq_along(library)) {
            tmp2 = msigdbr(species = spec_check, category = library[x])
            m_df <- rbind(m_df, tmp2)
        }
      
        if(!is.null(gene.sets)) {
        m_df <- m_df[m_df$gs_name %in% gene.sets,]
        }    
    }
    
    gs <- unique(m_df$gs_name)
    ls <- list()
    for (i in seq_along(gs)) {
        tmp <- m_df[m_df$gs_name == gs[i],]
        tmp <- tmp$gene_symbol
        tmp <- unique(tmp)
        tmp <- GeneSet(tmp, setName=paste(gs[i]))
        ls[[i]] <- tmp
    }
    gsc <- GeneSetCollection(ls)
    return(gsc)
}


