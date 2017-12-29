%% This function reads the data from the Excel File provided and then
% Input:
%     filename = Name of the file containing the airline data. 
% Output
%     C= Total Cost;
%     Yield = Yield for flight from airport i to j; 
%------------------------------------------------------------------------
 function [c,yield,types,fleet,c_l,V,seats,tat,range,runway,d, ...
                 airports,q,arunway]=read_1(filename)
    %%  Determine the types of aircraft in fleet.
    filename = 'group11.xlsx'
    lat  = xlsread(filename,11,'C6:V6')*pi/180; % Convert lat to rad;
    long = xlsread(filename,11,'C7:V7')*pi/180; % Convert long to rad;
    R_e = 6371; %km 
    
    airports = size(lat);    
    airports = airports(2); % Number of airports;
    
    d = zeros(airports,airports);
    for i=1:airports   
        for j=1:airports
           d(i,j) = R_e*2*asin(((sin((lat(i)-lat(j))/2))^2+cos(lat(i))* ... 
                    cos(lat(j))*(sin((long(i)-long(j))/2))^2)^(0.5));
        end
    end
    %%  Fleet Size 
    fleet_all = xlsread(filename,11,'B12:F12');
    indx  = find(fleet_all);
    types = length(indx);        %Types of aircraft;
    fleet = fleet_all(indx);     % Number of aircraft per type
    %% Airport runways
    arunway = xlsread(filename,11,'C8:Z8'); %m
    %%  Demand   
    q = xlsread(filename,11,'C15:Z38');
    q = q(1:airports,1:airports);
    %% Aircraft Chracteristics
    ac = xlsread(filename,11,'B43:F47'); % Aircraft Characteristics
    % Speed, Seats, Average TAT, Range, Runway; 
    ac = ac(:,indx);
    V = ac(1,:);    % km/h
    seats = ac(2,:);% 
    tat    = ac(3,:)/60; %h
    range  = ac(4,:); %km
    runway     = ac(5,:); %km
    %% Cost
    costs= xlsread(filename,11,'M43:Q46'); 
    %leasing, fixed, time, fuel
    costs= costs(:,indx);
    c_l  = costs(1,:);
    c_f  = costs(2,:);
    c_t  = costs(3,:);
    c_fuel = costs(4,:);
    
    totalcost = zeros(airports,airports,types);
    for k=1:types
        for i=1:airports
            for j=1:airports
                totalcost(i,j,k)= costs(2,k)+ d(i,j)/V(k)*costs(3,k)+ ...
                                  costs(4,k)*d(i,j);
                if j == i
                    totalcost(i,j,k)= 0;
                end
            end
        end
    end
    
    hub   = 1;
    for k = 1:types
        for j = 1:airports
            totalcost(hub,j,k) = totalcost(hub,j,k) * 0.7;
            totalcost(j,hub,k) = totalcost(j,hub,k) * 0.7;
        end
    end
   c = zeros(airports,airports,types);
    for k= 1:types
        c(:,:,k) = transpose(totalcost(:,:,k));
    end
   c   = reshape(c,airports*airports*types,1);
    
      %% Yield for each x_ij and w_ij
    y = zeros(airports,airports);
    for i = 1:airports
        for j =1: airports
            y(i,j) = (5.9*d(i,j)^(-0.76)+0.043)*d(i,j);
            if isnan(y(i,j))
                y(i,j)=0;
            end
        end
    end
    yield = reshape(y,airports*airports,1);
end
%% Spyros Cost Calculation
% fixedcost_ac1 = c_f(1)*ones(airports,airports);
% fixedcost_ac1(logical(eye(size(fixedcost_ac1)))) = 0;    
%     
% fixedcost_ac2 = c_f(2)*ones(airports,airports);
% fixedcost_ac2(logical(eye(size(fixedcost_ac2)))) = 0;
% 
%  
% fixedcost = reshape([fixedcost_ac1 fixedcost_ac2 ],...
%                     airports,airports,types);
% timecost = zeros(airports,airports,types);
% fuelcost = zeros(airports,airports,types);
% totalcost = zeros(airports,airports,types);
% % 
% 
% for i = 1:airports
%     for j = 1:airports
%         for k = 1:types
%             timecost(i,j,k) = c_t(k)*d(i,j)/V(k);
%             fuelcost(i,j,k) = c_fuel(k)*d(i,j);
%             totalcost(i,j,k) = timecost(i,j,k) + fuelcost(i,j,k) + fixedcost(i,j,k);
%               
%         end
%     end
% end
% % 
% % %Account for 30% reduction of cost for arrival/departures to/from the hub
% for k = 1:types
%      for j = 1:airports
%         totalcost(3,j,k) = totalcost(3,j,k)*0.7;
%     end
% end
% for k = 1:types
%      for i = 1:airports
%         totalcost(i,3,k) = totalcost(i,3,k)*0.7;
%      end
% end
% for k = 1:types
%     totalcost(3,3,k) = totalcost(3,3,k)/0.7; 
% end
       
