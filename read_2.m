%% This function reads the data from the Excel File provided and then
% Input:
%     filename = Name of the file containing the airline data. 
% Output
%     C= Total Cost;
%     Yield = Yield for flight from airport i to j; 
%------------------------------------------------------------------------
function [c,yield,types,fleet,c_l,V,seats,tat,range,runway,d, ...
                airports,q, arunway]=read_2(filename)
    %%  Determine the types of aircraft in fleet.
    %filename = 'group11.xlsx';
    lat  = xlsread(filename,11,'C6:Z6')*pi/180; % Convert lat to rad;
    long = xlsread(filename,11,'C7:Z7')*pi/180; % Convert long to rad;
    R_e = 6371; %km 
    
    airports = size(lat);    
    airports = airports(2); % Number of airports;
    
    for i=1:airports   
        for j=1:airports
           d(i,j) = 2*asin(((sin((lat(i)-lat(j)))/2)^2+ ...
                    cos(lat(i))*cos(lat(j)) * ...
                    (sin((long(i))-long(j))/2)^2)^0.5)*R_e;
        end
    end
    
    %% Airport runways
    arunway = xlsread(filename,11,'C8:Z8'); %m
    %%  Fleet Size 
    fleet = xlsread(filename,11,'B12:F12');
    types = length(fleet);        %Types of aircraft;
    %%  Demand   
    q = xlsread(filename,11,'C15:Z38');
    q = q(1:airports,1:airports);
    %% Aircraft Chracteristics
    ac = xlsread(filename,11,'B43:F47'); % Aircraft Characteristics
    % Speed, Seats, Average TAT, Range, Runway; 
    V = ac(1,:);    % km/h
    seats = ac(2,:);% 
    tat    = ac(3,:)/60; %h
    range  = ac(4,:); %km
    runway     = ac(5,:); %km
    %% Cost
    costs= xlsread(filename,11,'M43:Q46'); 
    %leasing, fixed, time, fuel
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
    
    for k = 1:types
        for j = 1:airports
            totalcost(1,j,k) = totalcost(1,j,k) * 0.7;
        end
        for i = 1:airports
            totalcost(i,1,k) = totalcost(i,1,k) * 0.7;
        end
    end
    
    c = zeros(airports,airports,types);
    for k= 1:types
         c(:,:,k) = transpose(totalcost(:,:,k));
    end
    c   = reshape(c,airports*airports*types,1);
    
%% Yield for each x_ij and w_ij
    yield = zeros(airports,airports);
    for i = 1:airports
        for j =1:airports
            if i< 21 || j <21
                yield(i,j) = (5.9*d(i,j)^(-0.76)+0.043)*d(i,j);
            else
                yield(i,j) = 0.05*d(i,j);
            end
        end
    end

    yield(isnan(yield)) = 0;
    yield = transpose(yield); 
    
    yield   = reshape(yield, airports*airports,1);
end
       
