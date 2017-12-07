function [speed,nseats,tat,max_range,runway] ...
    = accharacteristics(filename)
    fleet = xlsread(filename,'B12:F12');
    indx  = find(fleet);
    k = length(indx); %Types of aircraft;
    x = xlsread(filename,'B43:F47');
    acchar = [];
    for i=1:k
        acchar = [acchar x(:,indx(i))];
    end
    speed = acchar(1,:);
    nseats = acchar(2,:);
    tat    = acchar(3,:);
    max_range  = acchar(4,:);
    runway     = acchar(5,:);
end