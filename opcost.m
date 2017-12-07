%% This function determines the operational costs between airports i and j
% Input:
%     MaxR = maximum range of aircraft;
%     Cost_fixed = fixed operating cost per leg;
%     Cost_timed = time based cost in euro per hour;
%     Cost_fuel = fuel cost dependent on distance flown;
%     V = speed of aircraft;
%     d= distance between airport i and j;
% Variables
%     i= origin airport;
%     j= destination airport;
%     k=Number of aircraft types;
% Output
%     C= Total Cost;
%     Yield = Yield for flight from airport i to j; 
%------------------------------------------------------------------------
function [C,Yield,k,fleet,Cost_lease]=opcost(filename)
    % Determine the types of aircraft in fleet.
    fleet_all = xlsread(filename,'B12:F12');
    indx  = find(fleet_all);
    k = length(indx);        %Types of aircraft;
    fleet = fleet_all(indx); % Number of aircraft per type
    
    %Obtain
    [d,airports] = distance(filename);
    airports = airports(2); %Number of airports
    
    Cost_fixed=xlsread(filename,'M44:Q44');
    Cost_fixed = Cost_fixed(indx);
    Cost_timed=xlsread(filename,'M45:Q45');
    Cost_timed = Cost_timed(indx);
    Cost_fuel=xlsread(filename,'M46:Q46');
    Cost_fuel= Cost_fuel(indx);
    Cost_lease  = xlsread(filename,'M43:Q43');
    Cost_lease  = Cost_lease(indx).*fleet;
    V=xlsread(filename,'B43:F43');
    V= V(indx);
    
    C=[];
      
    for i=1:airports
        for j=1:airports
                Cost_timed_t =d(i,j)*Cost_timed./V;
                Cost_fuel_t  =Cost_fuel*d(i,j);
                Cost_fixed_t =Cost_fixed;
                C            =[C ; Cost_timed_t+Cost_fuel_t+Cost_fixed_t];
        end
    end
    
     Yield = 5.9*(reshape(d,airports*airports,1)).^(-0.76)+0.043;
     %Remove infinite values of Yield and set them to zero for cases where 
     %i=j; 
     Yield(find(isinf(Yield))) = 0;
end
       
  
    