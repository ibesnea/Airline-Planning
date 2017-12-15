%%    % Average load factor for European Flights and US Flights
    for i = 1:20
        for j = 1:20
            LF(i,j) = 0.75;
        end
        for j = 21:24
            LF(i,j) = 0.85;
        end
    end

    for i = 21:24
        for j = 1:24
        LF(i,j) = 0.85;
        end
    end
    %% Additional parameter for C9

    % b_h = 1 for the hub; -1 for the non-hub EU airport; 0 for US airport
    for i = 1                   %hub
        b_i(i) = 1;
    end
    for i = 2:20                %EU non-hub
        b_i(i) = -1;
    end
    for i = 21:24               %US
        b_i(i) = 0;
    end
    
    for j = 1
        b_j(j) = 1;             %hub
    end
    for j = 2:20
        b_j(j) = -1;            %EU non-hub
    end
    for j = 21:24               %US
        b_j(j) = 0;
    end
    
%% Constraints
%   C1: Demand constraint 
    for i = 1:Nodes
        for j = 1:Nodes
            C1 = zeros(1,DV);
            C1(Xindex(i,j,Nodes))= 1;
            C1(Windex(i,j,Nodes))= 1;
            cplex.addRows(0,C1,q(i,j),sprintf('Demand Constraint%d_%d',i,j));
        end
    end
    
%   C2: Transfer passenger constraint
    C2 = zeros(1,DV);
    for i = 1:Nodes
        for j = 1:Nodes
            C2 = zeros(1,DV);
            C2(Windex(i,j,Nodes)) = 1;
            cplex.addRows(0,C2,q(i,j)*g_i(i)*g_j(j),sprintf('Transfer Pax %d_%d',i,j));
        end
    end

%   C3: Capacity verification constraints
    for i = 1:Nodes
        for j = 1:Nodes
            C3 = zeros(1,DV);
            C3(Xindex(i,j,Nodes)) =  1;
            for m = 1:Nodes
                C3(Windex(i,m,Nodes))= (1-g_j(j));
                C3(Windex(m,j,Nodes))= (1-g_i(i));
            end
            for k = 1:actype
                C3(Zindex(i,j,k,Nodes)) = -nseats(k)*LF(i,j);           %change the LF(different for US
            end
            cplex.addRows(-Inf,C3,0,sprintf('CapacityVerification%d_%d',i,j));
        end
    end
%   C4: Flow balance
    for i = 1:Nodes
        for k = 1:actype
            C4 = zeros(1,DV);
            for j = 1:Nodes
                C4(Zindex(i,j,k,Nodes)) =  1;
                C4(Zindex(j,i,k,Nodes)) = -1;
                if j==i 
                   C4(Zindex(i,j,k,Nodes)) =  0;
                end
            end
            cplex.addRows(0,C4,0,sprintf('FlowBalanceNode_%d_%d',i,k));
        end
    end
%   C5: Aircraft utilization
    for k = 1:actype
        C5 = zeros(1,DV);
        for i = 1:Nodes
            for j = 1:Nodes
                C5(Zindex(i,j,k,Nodes)) = time(i,j,k);
            end
        end
        C5((DV-actype-npso)+k) = -BT;
        cplex.addRows(-Inf,C5,0,sprintf('ACutilization_%d',k));
    end
% C6: number aircraft
    for k= 1:actype
       C6 = zeros(1,DV);
       C6((DV-actype-npso)+k) = 1;
       cplex.addRows(0,C6,Inf,sprintf('NumberofAC_%d',k));          %n(k) can be unlimited
    end
% %C7:range and runway constraint
    for k=1:actype
        for i = 1:Nodes
            for j=1:Nodes
                C7 = zeros(1,DV);
                C7(Zindex(i,j,k,Nodes)) = 1;                        %a(i,j,k) need already consider runway (change combo function)
                cplex.addRows(0,C7,a(i,j,k),sprintf('RangeRunwayConstraint_%d_%d_%d',i,j,k));
            end
        end
    end
%C8: PSO: going there.
    j=1; 
    pso = 0;
    for i = 17:20
         pso = pso+1;
         C8 = zeros(1,DV); 
         for k = 1:actype
            C8(Zindex(i,j,k,Nodes)) = nseats(k);
            C8(Zindex(j,i,k,Nodes)) = nseats(k);
         end
         C8((DV-npso)+pso) = -200; 
         cplex.addRows(0,C8,Inf,sprintf('PSO_%d_%d_%d',i,j,pso)); 
    end
 
%   C9: 6 Freedom ASA
    C9 = zeros(1,DV);
    for i = 1:Nodes
        for j = 1:Nodes
            C9 = zeros(1,DV);
            C9(Xindex(i,j,Nodes)) = 1;
            cplex.addRows(0,C9,q(i,j)*max(b_i(i),b_j(j)),sprintf('6FreedomASA%d_%d',i,j));
        end
    end
    
%   C10: Maximum seats to US
    j=1; 
    for i = 21:24
         C10 = zeros(1,DV); 
         for k = 1:actype
            C10(Zindex(i,j,k,Nodes)) = nseats(k);
            C10(Zindex(j,i,k,Nodes)) = nseats(k);
         end
         cplex.addRows(0,C10,7500,sprintf('MaximumUSseats%d_%d_%d',i,j)); 
    end
    
%   C11: Limitation of aircraft type in EU
    for i = 1:20
        for j = 1:20
            zeros(1,DV);
            for k = 4:5
                C11(Zindex(i,j,k,Nodes)) = 1;
            end
            cplex.addRows(0,C11,0,sprintf('AClimit%d_%d',k));
        end
    end