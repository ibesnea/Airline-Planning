%% This function determines the distance between to airports i and j.
%   Input:
%       lat     = Latitude of airport;
%       long    = longitude of airport;
%       R_e     = Radius of the Earth;
%   Variables:
%       i= origin airport;
%       j= destination airport; 
%   Output:
%       d= distance between airport i and j; 
%       szalat = 
%--------------------------------------------------------------------------
function [d,szlat] = distance(filename)
    
    lat  = xlsread(filename,'C6:V6')*pi/180; % Convert lat to deg;
    long = xlsread(filename,'C7:V7')*pi/180; % Convert long to deg;
    R_e = 6371; 
    
    szlat = size(lat);  % Number of airports; 
    
    for i=1:szlat(2)   
        for j=1:szlat(2)
           d(i,j) = round(2*asin(((sin((lat(i)-lat(j)))/2)^2+ ...
                    cos(lat(i))*cos(lat(j)) * ...
                    (sin((long(i))-long(j))/2)^2)^0.5)*R_e,2);
        end
    end    
end