cnv_sample <- read.table(file = '../../cnv_viz/CPDV182943_xGen_20001_CapB_H3_PAL_20014_SEQ_200017_S7.cn.filtered.tsv', sep = '\t', header = TRUE)

function(input, output, session) {
  
  cnr <- read.table(file = '../../cnv_viz/CPDV182943_xGen_20001_CapB_H3_PAL_20014_SEQ_200017_S7.final.cnr', sep = '\t', header = TRUE)
  cnr_target <- filter(cnr, !gene %in% c("Antitarget", ".")) 
  cnr_target <- mutate(cnr_target, m_probe = (start + end)/2)
  
  by_gene <- cnr_target %>% group_by(chromosome, gene) %>%
    summarise(s = min(start), e = max(end),
              mean_log2 = weighted.mean(log2, weight),
              total_weight = sum(weight))%>%
    mutate(m = (s+e)/2)
  
  cns <- read.table("../../cnv_viz/CPDV182943_xGen_20001_CapB_H3_PAL_20014_SEQ_200017_S7.final.cns", header = TRUE)
  gl <- filter(cns, log2 < -1 | log2 > 1)
  
  chromosomes <- c(paste0("chr", "1":"22"), "chrX", "chrY")
  for(i in c(1:length(chromosomes))){
    
    chr <- filter(by_gene, chromosome == chromosomes[i])
    assign(chromosomes[i], chr)
    
    chr_gl <- filter(gl, chromosome == chromosomes[i])
    assign(paste0(chromosomes[i], "_gl"), chr_gl)
    
    plot <- plot_ly(type = 'scatter', mode = 'markers') %>%
      add_trace(x = get(chromosomes[i])$m, 
                y = get(chromosomes[i])$mean_log2, 
                text = get(chromosomes[i])$gene,
                hoverinfo = 'text',
                marker = list(color='blue', size = get(chromosomes[i])$total_weight),
                showlegend = F) %>%
      add_segments(x = 0, xend = max(get(chromosomes[i])$m), y = -1, yend = -1, line = list(color = "green", width = 1, dash = "dot"), showlegend = F) %>%
      add_segments(x = 0, xend = max(get(chromosomes[i])$m), y = 3, yend = 3, line = list(color = "green", width = 1, dash = "dot"), showlegend = F) %>%
      layout(annotations = list(x = 40e6 , y = 6, text = chromosomes[i], showarrow= F), yaxis=list(title = "Copy number ratio", titlefont = list(size = 8), range = c(-2, 6)), xaxis= list(range = c(0,250e6)))
    
    if(nrow(get(paste0(chromosomes[i], "_gl")))>0){
      for(j in 1:nrow(get(paste0(chromosomes[i], "_gl")))){
        plot <- plot %>% add_segments(x = get(paste0(chromosomes[i], "_gl"))$start[j], xend = get(paste0(chromosomes[i], "_gl"))$end[j], y = get(paste0(chromosomes[i], "_gl"))$log2[j], yend = get(paste0(chromosomes[i], "_gl"))$log2[j], line = list(color = "red", width = 6), showlegend = F)
      }
    }
    
    assign(paste0(chromosomes[i],"_plot"), plot)
    
  }
  
  all <- subplot(chr1_plot, chr2_plot, chr3_plot,
          chr4_plot, chr5_plot, chr6_plot,
          chr7_plot, chr8_plot, chr9_plot,
          chr10_plot, chr11_plot, chr12_plot,
          chr13_plot, chr14_plot, chr15_plot,
          chr16_plot, chr17_plot, chr18_plot,
          chr19_plot, chr20_plot, chr21_plot,
          chr22_plot, chrX_plot, chrY_plot,
          nrows=9, shareY = TRUE, shareX = TRUE) %>% 
    layout(autosize = F, height = 1200)
  
  plot_todisplay <- reactive({ switch(input$chr,
                            "all" = all,
                            "chr1" = chr1_plot, "chr2" = chr2_plot, "chr3" = chr3_plot,
                            "chr4" = chr4_plot, "chr5" = chr5_plot, "chr6" = chr6_plot,
                            "chr7" = chr7_plot, "chr8" = chr8_plot, "chr9" = chr9_plot,
                            "chr10" = chr10_plot, "chr11" = chr11_plot, "chr12" = chr12_plot,
                            "chr13" = chr13_plot, "chr14" = chr14_plot, "chr15" = chr15_plot,
                            "chr16" = chr16_plot, "chr17" = chr17_plot, "chr18" = chr18_plot,
                            "chr19" = chr19_plot, "chr20" = chr20_plot, "chr21" = chr21_plot,
                            "chr22" = chr22_plot, "chrX" = chrX_plot, "chrY" = chrY_plot
  ) })
  
  output$chr_plot <- renderPlotly(plot_todisplay())
  
  d <- reactive ({ event_data("plotly_click")[[3]] })
  gene <- reactive({ filter(by_gene, m == d()) %>% select(chromosome, gene, s, e) })
  gene_data <- reactive ({ filter(cnr_target, gene == gene()$gene[1]) })
  
  output$gene_plot <- renderPlotly({ 
    req(d())
      plot_ly(height = 250, type = 'scatter', mode = 'markers') %>%
        add_trace(x = gene_data()$m_probe, 
                  y = gene_data()$log2, 
                  hoverinfo = 'text',
                  marker = list(color='yellow', size = gene_data()$weight*20),
                  showlegend = F) %>%
        add_segments(x = min(gene_data()$s), xend = max(gene_data()$e), y = -1, yend = -1, line = list(color = "orange"), showlegend = F) %>%
        add_segments(x = min(gene_data()$s), xend = max(gene_data()$e), y = 3, yend = 3, line = list(color = "orange"), showlegend = F) %>%
        layout(title = gene()$gene[1], xaxis = list(tickfont = list(size = 6), range = min(gene_data()$s), max(gene_data()$e)), yaxis=list(tickfont = list(size = 6), title = "Copy number ratio", titlefont = list(size = 8), range = c(-3, 6)))
    }) 
  
  
}