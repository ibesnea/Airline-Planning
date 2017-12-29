%% Initialization
    addpath('/Users/Claudia/Documents/MSc-1/Q2/AE4423/Airline-Planning')
    clearvars
    clc
    close all
%% Input
    [C,Yield,actype,fleet,leasing,speed,nseats,tat,max_range,runway,d, ...
                airports,q,nrunway] = read_1('group11.xlsx');
    %Number of airports;
    Nodes   = airports;   
    npso    = 4; 
    %tat_{ij}^k turn around time for flight from aiport i to j per
    %AC type k
    time = TAT(actype,Nodes,tat,speed,d);
    % Average load factor for European Flights
    LF= 0.75; 
    % Average utilization time for aircraft (all types)
    BT= 70;   
    % Range matrix of possible combos
    a = combo(d,Nodes,actype,max_range);
    b = comborunway(Nodes,actype,runway,nrunway);
    indx_b = b==0;
    a(indx_b) = 0;
%% Parameters 
    % g_h = 0 if a hub is located at airport h; 1 otherwise
    hub = 1; 
    g_i = ones(1,Nodes);
    g_j = ones(1,Nodes);
    g_i(hub) =0;
    g_j(hub) =0;
%% Initiate CPLEX Model
%   Create model
        model                   =   'Problem1_2';
        cplex                   =   Cplex(model);
        cplex.Model.sense       =   'maximize'; 

%   Decision variable
        DV                      =  Nodes*Nodes+Nodes*Nodes+...
                                   Nodes*Nodes*actype+actype+npso;
    %% Objective Function 
        X = Yield;% Direct Flow
        W = Yield;% Flow from airport transfer in hub
        Z = -C;
        N = -reshape(leasing,actype,1); 
        P = 15000*ones(npso,1); 
        obj = [X;W;Z;N;P];
        lb                     =   zeros(DV,1);
        ub                     =   inf((DV),1);
        s1                =   char(ones(1,(DV-npso))*('I'));
        s2                   =   char(ones(1,npso)*('B'));
        ctype              =   strcat(s1,s2);
        l = 1;                 % Array with DV names
        for i = 1:Nodes
            for j = 1:Nodes  % of the x_{ij} variables
                NameDV(l,:)  = ['X_' num2str(i,'%02d') ',' num2str(j,'%02d') ...
                                '_' num2str(0)];
                l = l + 1;
            end
        end
        for i = 1:Nodes
            for j = 1:Nodes  % of the x_{ij} variables
                NameDV(l,:)  = ['W_' num2str(i,'%02d') ',' num2str(j,'%02d') ...
                                '_' num2str(0)];
                l = l + 1;
            end
        end

        for k =1:actype
            for i = 1:Nodes
                for j = 1:Nodes % of the z_{ij}_k variables
                    NameDV(l,:)  = ['Z_' num2str(i,'%02d') ',' num2str(j,'%02d') ...
                                '_' num2str(k)];
                    l = l + 1;
                end
            end
        end
        
        for k =1:actype  % of the z_{ij}_k variables
            NameDV(l,:)  = ['N_' num2str(0,'%02d') ',' num2str(0,'%02d') ...
                                '_' num2str(k)];
            l = l + 1;
        end
        for n =1:npso  
            NameDV(l,:)  = ['P_' num2str(0,'%02d') ',' num2str(0,'%02d') ...
                                '_' num2str(n)];
            l = l + 1;
        end  
          
        cplex.addCols(obj, [], lb, ub, ctype, NameDV);
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
            cplex.addRows(0,C2,q(i,j)*g_i(i)*g_j(j),sprintf('TransferPax%d_%d',i,j));
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
                C3(Zindex(i,j,k,Nodes)) = -nseats(k)*LF;
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
        C5(Nindex(k,actype,Nodes)) = -BT;
        cplex.addRows(-Inf,C5,0,sprintf('ACutilization_%d',k));
    end
% C6: number aircraft
    for k= 1:actype
       C6 = zeros(1,DV);
       C6(Nindex(k,actype,Nodes)) = 1;
       cplex.addRows(fleet(k),C6,fleet(k),sprintf('NumberofAC_%d',k));
    end
    
% %C7:range constraint
    for k=1:actype
        for i = 1:Nodes
            for j=1:Nodes
                C7 = zeros(1,DV);
                C7(Zindex(i,j,k,Nodes)) = 1;
                cplex.addRows(0,C7,a(i,j,k),sprintf('RangeConstraint_%d_%d_%d',i,j,k));
            end
        end
    end
    %C8: PSO: going back.
    pso = 0;
    for i = 17:20
         pso = pso+1;
         C8 = zeros(1,DV); 
         for k = 1:actype
            C8(Zindex(i,hub,k,Nodes)) = nseats(k);
         end
         C8(PSOindex(pso,actype,Nodes)) = -200; 
         cplex.addRows(0,C8,Inf,sprintf('PSO_%d',i,pso)); 
    end
    %C9: PSO: going there.
    pso =0;
    for j = 17:20
         pso = pso+1;
         C9 = zeros(1,DV); 
         for k = 1:actype
            C9(Zindex(hub,j,k,Nodes)) = nseats(k);
         end
         C9(PSOindex(pso,actype,Nodes)) = -200; 
         cplex.addRows(0,C9,Inf,sprintf('PSO_%d',j,pso)); 
    end
    %%  Execute model
            cplex.Param.mip.limits.nodes.Cur    = 1e+8;         %max number of nodes to be visited (kind of max iterations)
            cplex.Param.timelimit.Cur           = 10;           %max time in seconds
    %Run CPLEX
            cplex.solve();
            cplex.writeModel([model '.lp']);
              
    %% Postprocessing
     % Store direct results
        status                      =   cplex.Solution.status;       
        sol.profit = cplex.Solution.objval; 
        fprintf('\n-----------------------------------------------------------------\n');
        fprintf ('Objective function value: %10.1f \n', sol.profit);
         dv    = cplex.Solution.x;
     x_ij = dv(1:Nodes*Nodes,1);
     x_ij = transpose(reshape(x_ij,Nodes,Nodes));
     w_ij = dv((Nodes*Nodes+1):Nodes*Nodes*2,1); 
     w_ij = transpose(reshape(w_ij,Nodes,Nodes));
     z_ij_k = dv(Nodes*Nodes*2+1:Nodes*Nodes*(actype+2),1);
     z      = zeros(Nodes,Nodes,actype);
     for k=1:actype
         z_ij = transpose(reshape(z_ij_k(Nodes*Nodes*(k-1)+1:Nodes*Nodes*k),Nodes,Nodes));
         z(:,:,k) = z_ij; 
     end
     n_k    = transpose(dv(Nodes*Nodes*(actype+2)+1:Nodes*Nodes*(actype+2)+actype));
     pso    = transpose(dv(Nodes*Nodes*(actype+2)+actype+1:DV));
     
%      xlswrite('solution.xlsx',sol.profit,1,'B1');
%      xlswrite('solution.xlsx',n_k,1,'B2:D2');
%      xlswrite('solution.xlsx',x_ij,1,'B4:U23');
%      xlswrite('solution.xlsx',w_ij,1,'B25:U44');
%      xlswrite('solution.xlsx',z(:,:,1),2,'B4:U23');
%      xlswrite('solution.xlsx',z(:,:,2),2,'B25:U44');
%      xlswrite('solution.xlsx',z(:,:,3),2,'B46:U65');
%      xlswrite('solution.xlsx',pso,2,'B2:E2');
%% Functions to determine the index of the DV based on (i,j,k)
function out = Xindex(m,n,Nodes)
    out = (m - 1) * Nodes + n;   
end
function out = Windex(m,n,Nodes)
    out = Nodes*Nodes + (m - 1) * Nodes + n;   
end
function out = Zindex(m,n,p,Nodes)
    out = Nodes*Nodes*2 + (m - 1) * Nodes + n + Nodes*Nodes*(p-1);   
end
function out = Nindex(p,actype,Nodes)
    out =  Nodes*Nodes*(actype+2)+p; 
end
function out = PSOindex(pso,actype,Nodes)
    out = Nodes*Nodes*(actype+2)+actype+pso;
end    
%     

 