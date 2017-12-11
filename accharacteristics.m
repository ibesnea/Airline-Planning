% function [speed,nseats,tat,max_range,runway] ...
%     = accharacteristics(filename)
filename = 'group11.xlsx'
    fleet = xlsread(filename,'B12:F12');
    indx  = find(fleet);
    k = length(indx); %Types of aircraft;
    x = xlsread(filename,'B43:F47');
    acchar = [];
    for i=1:k
        acchar = [acchar x(:,indx(i))];
    end
    speed = acchar(1,:); % km/h
    nseats = acchar(2,:);% 
    tat    = acchar(3,:)/60; %h
    max_range  = acchar(4,:); %km
    runway     = acchar(5,:)/10^3; %km
%end