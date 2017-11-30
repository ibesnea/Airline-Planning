%% Initialization
    addpath('/Users/Claudia/Documents/MSc-1/Q2/AE4423/Airline-Planning')
%% Read Data
    filename = 'group11.xlsx';
    lat  = xlsread(filename,'C6:Z6')*pi/180;
    long = xlsread(filename,'C7:Z7')*pi/180;
    R_e = 6371 %km  Earth Radius 
    
    for i=1:(size(lat))(2)
        for j=1:(size(long))(2)
            if i==j
                d(i,j) = 0; 
            else 
                d(i,j) = (sin((lat(i)-lat(j))/2))^2
            end      
        end
    end