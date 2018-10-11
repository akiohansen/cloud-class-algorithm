%%  Cloud Classification Algorithm - COSMO-DE Example
% Version: 11/10/2018, v05
% Contact details: Akio Hansen, akio.hansen@uni-hamburg.de

% Dataset information
% SuperSite: LACROS of HOPE campaign
% Variables: Temperature, Dew point, all hydrometeor profiles
% Model used: Operational COSMO-DE from German Weather Service (DWD)
% Every 12 hour one new model run, in between use forecasts from model run before

%% Initialize Matlab environment and clear unused variables
clc, clear, close all;

%% Output_file (optional for further postprocessing of Classification)
output_file = 'L:\win\ICON_HOPE\CloudNet_Matlab\data\OwnClass_COSMODE_AprMay2013_raw_Paper_v11102018.mat';

%% Load preprocssed COSMO-DE dataset (provided on Github)
% Preprocssed by cdo's and python scripts to extract nearest grid point of
% LACROS supersite and combine every 12 hour new model run with forecasts
% in between to get continous time series, NetCDF created with xArray

% Load NetCDF file
nc_filename = 'L:\win\ICON_HOPE\OwnClassPaper\data\COSMODE_AprMay2013_raw_Paper_v11102018.nc';
% Read dimension variables
time_unix   = double(ncread(nc_filename,'time'));
height = ncread(nc_filename,'height');
% Read data variables to workspace
T_GDS0_CMPL = ncread(nc_filename,'T');
TD_GDS0_CMPL = ncread(nc_filename,'TD');
% Read hydrometeor profiles to workspace
QC_GDS0_CMPL = ncread(nc_filename,'QC');
QI_GDS0_CMPL = ncread(nc_filename,'QI');
QR_GDS0_CMPL = ncread(nc_filename,'QR');
QS_GDS0_CMPL = ncread(nc_filename,'QS');
QG_GDS0_CMPL = ncread(nc_filename,'QG');

%% Convert Unixtime to Matlab date format
time = datenum(time_unix/86400 + datenum(1970,1,1));

%% Create Cloud Classification matrix
% Categories:
% 1 = Clear sky
% 2 = Cloud droplets only
% 3 = Drizzle or rain
% 4 = Drizzle/rain & cloud droplets
% 5 = Ice
% 6 = Ice & supercooled droplets
% 7 = Melting ice
% 8 = Melting ice & cloud droplets
% 9 = Aerosol (neglected due to missing information)
% 10 = Insects (neglected due to missing information)
% 11 = Aerosol & insects (neglected due to missing information)

% Initialize Cloud Classification matrix
CloudClass = NaN(size(QC_GDS0_CMPL));

%% Set numerical noise to NaN values (threshold according to personal communication with A. Seifert (DWD))
QC_GDS0_CMPL(QC_GDS0_CMPL < 10e-11) = 0;
QI_GDS0_CMPL(QI_GDS0_CMPL < 10e-11) = 0;
QR_GDS0_CMPL(QR_GDS0_CMPL < 10e-11) = 0;
QS_GDS0_CMPL(QS_GDS0_CMPL < 10e-11) = 0;
QG_GDS0_CMPL(QG_GDS0_CMPL < 10e-11) = 0;

%% Cloud Classification algorithm - Version proposed to be published in GMD
% Cloud droplets only
CloudClass(find(QC_GDS0_CMPL > 0 & QI_GDS0_CMPL <= 0 & T_GDS0_CMPL > 0.0)) = 2;
% Ice
CloudClass(find(QI_GDS0_CMPL > 0 & QC_GDS0_CMPL <= 0 & TD_GDS0_CMPL < 0.0)) = 5;
% Snow -> declared as Ice
CloudClass(find(QS_GDS0_CMPL > 0 & QC_GDS0_CMPL <= 0 & TD_GDS0_CMPL < 0.0)) = 5;
% Graupel -> declared as Ice
CloudClass(find(QG_GDS0_CMPL > 0 & QC_GDS0_CMPL <= 0 & TD_GDS0_CMPL < 0.0)) = 5;
% Ice & supercooled droplets
CloudClass(find(QC_GDS0_CMPL > 0 & QI_GDS0_CMPL > 0 & TD_GDS0_CMPL < 0.0)) = 6;
% Melting ice
CloudClass(find(QI_GDS0_CMPL > 0 & TD_GDS0_CMPL > 0.0)) = 7;
% Melting ice & cloud droplets
CloudClass(find(QI_GDS0_CMPL > 0 & QC_GDS0_CMPL > 0.0 & TD_GDS0_CMPL > 0.0)) = 8;
% Drizzle or rain
CloudClass(find(QR_GDS0_CMPL > 0 & T_GDS0_CMPL > 0.0)) = 3;
% Drizzle/rain & cloud droplets
CloudClass(find(QR_GDS0_CMPL > 0 & T_GDS0_CMPL > 0.0 & QC_GDS0_CMPL > 0)) = 4;


%% Save classification for further data analysis (optional)
Date_CloudClass   = time;
Height_CloudClass = height;
%save(output_file,'CloudClass','Date_CloudClass','Height_CloudClass');


%% Plot section
% Define consistent CloudNet Target Classification Colormap
cnet_bar = flipud([0.200000002980232 0.200000002980232 0.200000002980232;0.400000005960464 0.400000005960464 0.400000005960464;...
    0.600000023841858 0.600000023841858 0.600000023841858;0 0.400000005960464 0.400000005960464;0.87058824300766 0.490196079015732 0;...
    0 0.498039215803146 0;1 1 0;0 0 0.800000011920929;0.847058832645416 0.160784319043159 0;0 0.600000023841858 0.800000011920929;1 1 1]);

%% Cloud Classification Plot - Only April
figure(1)
pcolor(time(1:696)',height(:)./1000,CloudClass(:,1:696))
hold on
set(gca,'FontSize',18)
set(get(gca,'Children'),'EdgeColor','none')
ylim([0 12]);
set(gca, 'XTick', [datenum(2013,04,01),datenum(2013,04,05):5:datenum(2013,04,32)]);
datetick('x','dd','keepticks')
%Hintergrundfarbe setzen
set(gcf,'Color','w')
set(gca,'CLim',[0 11])
% Colorbar and set labeling centered
colormap(cnet_bar);
numcolors = 11;
caxis([1 numcolors]);
cbarHandle = colorbar('YTick',...
[1+0.5*(numcolors-1)/numcolors:(numcolors-1)/numcolors:numcolors],...
'YTickLabel',{'Clear sky','Cloud droplets only','Drizzle or rain','Drizzle/rain & cloud droplets','Ice',...
'Ice & supercooled droplets','Melting ice','Melting ice & cloud droplets','Aerosol','Insects','Aerosols & insects'}, 'YLim', [1 numcolors]);
set(gca,'Position',[0.11, 0.15, 0.4, 0.8 ]) 
% Titel
%title('OwnCloudNet Classification LACROS April','FontSize',18);
ylabel('Height (km)','Fontsize',20,'Interpreter','latex')
xlabel('Day of the month','Fontsize',20,'Interpreter','latex')
set(gcf,'Renderer','painters')
%set(gcf,'PaperUnits','inches','PaperPosition',[0 0 17.0 3.5])
% new Plot PDF output
hold off
pfad='F:\TSProfile\*\HOPE\Plots\'
name=['CloudClass_Apr2013.pdf']
%
h=gcf;
set(h, 'PaperUnits', 'centimeters');
set(h, 'PaperType', 'A4');
set(h,'PaperOrientation','landscape');
set(h, 'PaperPositionMode', 'manual');
set(h, 'PaperUnits', 'centimeters');
set(h, 'PaperPosition', [-3.00 0.63 50.00 10.00]); % 1 4 2]);
%
%print( '-dpdf', '-r300', [pfad name])
print ('-dpng','../CloudNet_Own_Apr_Fcast_v2.png')


%% Cloud Classification Plot - Only May
figure(2)
pcolor(time(697:end)',height(:)./1000,CloudClass(:,697:end))
hold on
set(gca,'FontSize',18)
set(get(gca,'Children'),'EdgeColor','none')
ylim([0 12]);
set(gca, 'XTick', [datenum(2013,05,01),datenum(2013,05,05):5:datenum(2013,05,28),datenum(2013,05,31)]);
datetick('x','dd','keepticks')
%Hintergrundfarbe setzen
set(gcf,'Color','w')
set(gca,'CLim',[0 11])
% Colorbar and set labeling centered
colormap(cnet_bar);
numcolors = 11;
caxis([1 numcolors]);
cbarHandle = colorbar('YTick',...
[1+0.5*(numcolors-1)/numcolors:(numcolors-1)/numcolors:numcolors],...
'YTickLabel',{'Clear sky','Cloud droplets only','Drizzle or rain','Drizzle/rain & cloud droplets','Ice',...
'Ice & supercooled droplets','Melting ice','Melting ice & cloud droplets','Aerosol','Insects','Aerosols & insects'}, 'YLim', [1 numcolors]);
set(gca,'Position',[0.11, 0.15, 0.4, 0.8 ]) 
% Titel
%title('OwnCloudNet Classification LACROS May','FontSize',18);
ylabel('Height (km)','Fontsize',20,'Interpreter','latex')
xlabel('Day of the month','Fontsize',20,'Interpreter','latex')
set(gcf,'Renderer','painters')
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 17.0 3.5])
% new Plot PDF output
hold off
pfad='F:\TSProfile\*\HOPE\Plots\'
name=['CloudNet_Own_May_Fcast_v2.pdf']
%
h=gcf;
set(h, 'PaperUnits', 'centimeters');
set(h, 'PaperType', 'A4');
set(h,'PaperOrientation','landscape');
set(h, 'PaperPositionMode', 'manual');
set(h, 'PaperUnits', 'centimeters');
set(h, 'PaperPosition', [-3.00 0.63 50.00 10.00]); % 1 4 2]);
%
%print( '-dpdf', '-r300', [pfad name])
print ('-dpng','../CloudNet_Own_May_Fcast_v2.png')
