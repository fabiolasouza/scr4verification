#Function to plot verification against scatterometers
#library(ggplot2)
#library(patchwork)
#library(dplyr)
#plot_scatt(start_date = '2023040800',
#             end_date = '2023041518',
#             path_rds ='/ec/res4/scratch/nkfs/data/scatt/rds',
#             model = 'ecds_v2',
#             name_domain = 'NorthSea',
#             obs = 'hscat_hy-2c',
#             cycle = 'All',
#             param = 'S10m',
#             score = c('bias', 'stde')
#             min_ncases = 25,
#             labels = c(0, 1, 2, 3, 4, 5, 6, 7, 8,
#                       9, 10, 11, 12, 15, 18, 21, 24,
#                       27, 30, 33, 36, 39, 42, 45, 48),
#             save_path = '/ec/res4/scratch/nkfs/data/scatt/png')
#
plot_scatt <- function(start_date, end_date, path_rds, model, name_domain, obs, cycle, param, score, min_ncases, labels, save_path){
    verif <- list.files(path=paste(path_rds, model, name_domain, obs, cycle, sep = '/'), pattern = paste('*.harp.', param, '.harp.', start_date, '-', end_date, '.*\\.rds$', sep = ''), full.names=T) %>% readRDS
    if (param == 'D10m'){
        units = 'degrees'
    } else {
        units = 'm/s'
    }
    p <- ggplot() +
        geom_line(data=verif$det_summary_scores, aes_string(x = 'leadtime', y=score[1], color = 'mname'), linewidth = 2) +
        geom_point(data=verif$det_summary_scores, aes_string(x = 'leadtime', y=score[1], color = 'mname'), size = 4) +
        geom_line(data=verif$det_summary_scores, aes_string(x = 'leadtime', y= score[2], color = 'mname'), linetype="longdash", linewidth = 2) +
        geom_point(data=verif$det_summary_scores, aes_string(x = 'leadtime', y=score[2], color = 'mname'), size = 4) +
        scale_x_continuous("Leadtime", labels = as.character(labels), breaks = labels, expand = c(0.01,0), expand.grid(FALSE)) +
        geom_line(data = verif$det_summary_scores, aes(x = leadtime, y = 0), linetype="longdash", color = "black", linewidth = 1) +
        labs(title=paste('Bias, Stde :', param, ':', format(as.POSIXct(start_date, format="%Y%m%d %H", tz="UTC"), format = "%Y-%m-%d"), '-', format(as.POSIXct(end_date, format="%Y%m%d %H", tz="UTC"), format = "%Y-%m-%d"),  
                  '\n \n Scatt: ', obs, '\n \n __ ', toupper(score[1]), '  - - ', toupper(score[2]), sep = ' '), x = 'Leadtime', y = units, color = ' ') +
        scale_fill_brewer(palette="Spectral") +
        theme_bw()+
        theme(legend.position='top') +
        theme(text = element_text(size=20))

    nobs <- ggplot() +
        geom_line(data=verif$det_summary_scores, aes_string(x = 'leadtime', y = 'num_cases', color = 'mname'), linewidth = 2) +
        geom_point(data=verif$det_summary_scores, aes_string(x = 'leadtime', y = 'num_cases', color = 'mname'), size = 4) +
        scale_x_continuous("Leadtime", labels = as.character(labels), breaks = labels, expand = c(0.01,0), expand.grid(FALSE)) +
        theme_bw() +
        theme(legend.position = "none") +
        theme(axis.text.x = element_text(vjust = 0.8)) +
        theme(text = element_text(size = (20)))

    ggsave(plot = p + nobs + plot_layout(heights = c(3, 1)), filename = file.path(paste(save_path, model, name_domain, sep = '/'), paste(param, '_det_', start_date, '-', end_date, '_', cycle, '_', model, '.png', sep = '')), width=16, height=12, dpi=300)
}

