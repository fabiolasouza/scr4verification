library(ggplot2)
library(patchwork)
library(dplyr)
source('/home/nkfs/scr4verification/scatt/plot_scatt.R')
plot_scatt(start_date = '2023040800',
             end_date = '2023041518',
             path_rds ='/ec/res4/scratch/nkfs/data/scatt/rds',
             model = 'ecds_v2',
             name_domain = 'NorthSea',
             obs = 'hscat_hy-2c',
             cycle = 'All',
             param = 'S10m',
             score = c('bias', 'stde'),
             min_ncases = 25,
             labels = c(0, 1, 2, 3, 4, 5, 6, 7, 8,
                       9, 10, 11, 12, 15, 18, 21, 24,
                       27, 30, 33, 36, 39, 42, 45, 48),
             save_path = '/ec/res4/scratch/nkfs/data/scatt/png')

