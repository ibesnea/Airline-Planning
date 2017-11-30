%% Initialization
    addpath('/Users/Claudia/Documents/MSc-1/Q2/AE4423/Airline-Planning')
    clearvars
    clc
    close all
%% Read Data
    filename = 'group11.xlsx';
    lat  = xlsread(filename,'C6:Z6')*pi/180;
    long = xlsread(filename,'C7:Z7')*pi/180;
    R_e = 6371; %km  Earth Radius 
    
    szlat = size(lat);
    szlong = size(long);
    
    for i=1:szlat(2)
        for j=1:szlong(2)
           d(i,j) = round(2*asin(((sin((lat(i)-lat(j)))/2)^2+ ...
                    cos(lat(i))*cos(lat(j)) * ...
                    (sin((long(i))-long(j))/2)^2)^0.5)*R_e,2);
        end
    end  
    