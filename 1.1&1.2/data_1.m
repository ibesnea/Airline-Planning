function [nodes,type,yield,cost,lease,time,seats,combo,fleet] = data_1(filename)
    % Read latitude and Longitude from Excel
    lat     = xlsread(filename,11,'C6:V6')*pi/180;
    long    = xlsread(filename,11,'C7:V7')*pi/180;
    R       = 6371;

    % Number of airports.
    nodes   = size(lat,2);

    % Arc length between 2 airports.
    sigma   = zeros(nodes,nodes);
    for i=1:nodes
        for j=1:nodes
        sigma(i,j) = 2*asin(((sin((lat(i)-lat(j))/2))^2+cos(lat(i))*...
        cos(lat(j))*(sin((long(i)-long(j))/2))^2)^(0.5));
        end
    end

    % Distance between 2 airpots.
    distance = sigma*R;
    
    % Yield between 2 aiports
    yield               = distance.*(5.9*distance.^(-0.76)+0.043); 
    indx_yield          = isnan(yield);
    yield(indx_yield)   = 0; 

    % Initial fleet
    fleet       = xlsread(filename,11,'B12:F12');
    indx_fleet  = find(fleet);
    fleet       = fleet(indx_fleet);

    % Number of aircraft in fleet
    type        = size(fleet,2);

    % Cost data
    costdata    = xlsread(filename,11,'B50:F53');
    costdata    = costdata(:,indx_fleet);
    lease   = costdata(1,:);
    fixed   = costdata(2,:);
    timed   = costdata(3,:);
    fuel    = costdata(4,:);

    % Aircraft characteristics
    char    = xlsread(filename,11,'B43:F47');
    char    = char(:,indx_fleet);
    speed   = char(1,:);
    seats   = char(2,:);
    tat     = char(3,:)/60; 
    range   = char(4,:);
    runway  = char(5,:);

    % Cost
    cost    = zeros(nodes,nodes,type); 
    hub     = 1; 
    for k =1:type
        for i=1:nodes
            for j=1:nodes
                cost(i,j,k) = fixed(k)+ timed(k)*distance(i,j)/speed(k)+...
                    distance(i,j)*fuel(k);
                if j==i
                    cost(i,j,k) = 0;
                end
            end
        end
    end
    cost(hub,:,:) = cost(hub,:,:)*0.7;
    cost(:,hub,:) = cost(:,hub,:)*0.7;

    % Determine minimum runway between 2 aiports.
    nrunway         = xlsread(filename,11,'C8:V8');
    min_runway      = zeros(nodes,nodes);
    for i=1:nodes
        for j=1:nodes
            min_runway(i,j) = min(nrunway(i),nrunway(j));
            if j == i
                min_runway(i,j)  = 0; 
            end
        end
    end

    % Determine if you can fly to that airport with that aircraft type
    combo_runway     = zeros(nodes,nodes,type); 

    for k=1:type
        combo_runway(:,:,k)   = min_runway >= runway(k);
    end

    combo_runway     = 1000*combo_runway;
    indx_runway      = combo_runway ==0;

    % Determine if the range of ac is larger than distance
    combo_range      = zeros(nodes,nodes,type);

    for k=1:type
        combo_range(:,:,k)   = distance <= range(k);  
    end

    combo_range              = 1000*combo_range;
    combo_range(indx_runway) = 0; 
    combo                    = combo_range;

    % Determine the turn around time for the aircraft. 
    turnaroundtime   = ones(nodes,nodes,type);
    indx_tat         = eye(nodes,nodes) == 0;

    for k=1:type
        turnaroundtime(:,:,k) = indx_tat*tat(k);
    end

    turnaroundtime(:,hub,:) = turnaroundtime(:,hub,:)*2;

    for k =1:type
        for i=1:nodes
            if turnaroundtime(i,hub,k) <= 1
                turnaroundtime(i,hub,k) = 1;
            end
        end
    end

    turnaroundtime(hub,hub,:) = 0;

    % Travel time
    flytime = zeros(nodes,nodes,type);

    for k=1:type
        flytime(:,:,k) = distance/speed(k);
    end

    % Total time
    time = turnaroundtime+flytime;
end
