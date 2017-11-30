%% Initialization
    addpath('/Users/Claudia/Documents/MSc-1/Q2/AE4423/Airline-Planning')
%% Read Data
    filename = 'group111.xlsx';
    lat  = xlsread(filename,'C6:Z6')*pi/180;
    long = xlsread(filename,'C7:Z7')*pi/180;
    R_e = 6371; %km  Earth Radius 
    
    szlat = size(lat);
    szlong = size(long);
    
    for i=1:szlat(2)
        for j=1:szlong(2)
           arc(i,j) = 2* asin((sin((lat(i)-lat(j)))/2)^2+ ...
                    cos(lat(i))*cos(lat(j)) *(sin((long(i))-long(j))/2)^2);
        end
    end
    
    d = arc*R_e; 