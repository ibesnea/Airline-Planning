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
function [cost,yield,types,fleet,c_l]=opcost(filename)
    % Determine the types of aircraft in fleet.
    fleet_all = xlsread(filename,'B12:F12');
    indx  = find(fleet_all);
    types = length(indx);        %Types of aircraft;
    fleet = fleet_all(indx);     % Number of aircraft per type
    
    %Distance between airports and number of airports
    [d,airports] = distance(filename);
    airports = airports(2); %Number of airports
    
    % Aircraft costs 
    c_f=xlsread(filename,'M44:Q44'); %fixed for all A/C;
    c_f= c_f(indx);                  %fixed for current fleet;
    c_t=xlsread(filename,'M45:Q45'); %time cost for all A/C
    c_t = c_t(indx);                 %time cost for current fleet;
    c_fuel =xlsread(filename,'M46:Q46'); %fuel for all A/C'
    c_fuel= c_fuel(indx);                %fuel for current fleet;
    c_l = xlsread(filename,'M43:Q43');  
    c_l = c_l(indx).*fleet;
    V=xlsread(filename,'B43:F43');
    V= V(indx);
   
    cost = [];    
    for k=1:types
        c_fixed = c_f(k);
        for i=1:airports
            for j=1:airports
                c_t_ij = d(i,j)*c_t(k)/V(k);
                c_f_ij = d(i,j)*c_fuel(k);
                if i ==1 || j ==1
                    c      = (c_t_ij+c_f_ij+c_fixed)*0.7;
                else
                    c      = c_t_ij+c_f_ij+c_fixed;
                end
                cost = [ cost ; c];
            end
        end    
     end
    
    yield = [];
    for i = 1:airports
        for j =1: airports
            y = (5.9*d(i,j)^(-0.76)+0.043)*d(i,j);
            if isnan(y)
                y=0;
            end
            yield = [ yield ; y];
        end
    end
end
       
  
    