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
function C=opcost(filename)
n=3;
Cost_fixed=xlsread(filename,'M44:Q44');
Cost_timed=xlsread(filename,'M45:Q45');
Cost_fuel=xlsread(filename,'M46:Q46');
V=xlsread(filename,'B43:F43');
MaxR=xlsread(filename,'B46:F46');


for k=1:n
    if d(i,j)<MaxR(k)
        Cost_timed_t=Cost_timed(k)*d(i,j)/V(k);
        Cost_fuel_t=Cost_fuel(k)*d(i,j);
        Cost_fixed_t=Cost_fixed(k);
        C=Cost_timed_t+Cost_fuel_t+Cost_fixed_t;
    end
end
end
       
  
    