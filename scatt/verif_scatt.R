library(harp)
source('/home/nkfs/scr4verification/radiosonde/read_ascii.R')
model='ecds_v2'
obs = 'hscat_hy-2c'
cycle = 'All'
name_domain = 'NorthSea'
domain = c(55, 10, 57, 16)
params=c('S10m', 'U10m', 'V10m', 'D10m')
for (param in params) {
    fc <- read_ascii(start_date = '2023040800',
                    end_date = '2023041518',
                    fcst_model = c('ecds_v2'),
                    obs = 'hscat_hy-2c',
                    path = '/ec/res4/scratch/duuw/verification/ecflow/scatterometer',
                    param = param,
                    lead_time = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48),
                    by = 6,
                    name_domain = name_domain ,
                    domain = domain)
    fc <- structure(fc, class="harp_fcst")
    fc <- check_obs_against_fcst(fc, param)
    verif <- det_verify(fc, param, groupings = 'leadtime')
    save_point_verif(verif, verif_path = paste('/ec/res4/scratch/nkfs/data/scatt/rds', model, name_domain, obs, cycle, sep = '/'))
}
