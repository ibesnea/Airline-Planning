%% This function determines the operational costs between airports i and j
% Input:
%     MaxR = maximum range of aircraft;
%     Cost_fixed = fixed operating cost per leg;
%     Cost_timed = time based cost in euro per hour;
%     Cost_fuel = fuel cost dependent on distance flown;
%     V = speed of aircraft
% Variables
%     i= origin airport;
%     j= destination airport;
%     k=Number of aircraft types;
% Output
%     C= Total Cost;
%------------------------------------------------------------------------
function [C,k]=opcost(filename)

    fleet = xlsread(filename,'B12:F12');
    indx  = find(fleet);
    k = length(indx);        %Types of aircraft;
    
    [d,airports] = distance(filename);
    airports = airports(2);
    
    Cost_fixed=xlsread(filename,'M44:Q44');
    Cost_fixed = Cost_fixed(indx);
    Cost_timed=xlsread(filename,'M45:Q45');
    Cost_timed = Cost_timed(indx);
    Cost_fuel=xlsread(filename,'M46:Q46');
    Cost_fuel= Cost_fuel(indx);
    V=xlsread(filename,'B43:F43');
    V= V(indx);
      
    for i=1:airports
        for j=1:airports
                Cost_timed_t=Cost_timed(k)*d(/V(k);
                Cost_fuel_t=Cost_fuel(k)*d;
                Cost_fixed_t=Cost_fixed(k);
                C=Cost_timed_t+Cost_fuel_t+Cost_fixed_t;
        end
    end

end
       
  
    