%% Initialization
    addpath('/Users/Claudia/Documents/MSc-1/Q2/AE4423/Airline-Planning')
    clearvars
    clc
    close all
%% Input
    [C,Yield,actype,fleet,leasing,speed,nseats,tat,max_range,runway,d, ...
                airports,q,nrunway] = read_2('group11.xlsx');
    %Number of airports;
    Nodes   = airports;   
    npso    = 4; 
    %tat_{ij}^k turn around time for flight from aiport i to j per
    %AC type k
    time = TAT(actype,Nodes,tat,speed,d);
    % Average load factor for European Flights
    LF_EU= 0.75; 
    LF_USA = 0.85;
    LF = LF_USA*ones(Nodes,Nodes); 
    LF(1:20,1:20) = LF_EU;
    % Average utilization time for aircraft (all types)
    BT= 70;   
    % a is for range, b for runway length and c for not using A/C 4 and 5
    % in EU.
    a = combo(d,Nodes,actype,max_range); 
    b = comborunway(Nodes,actype,runway,nrunway);
    c = 1000*ones(Nodes,Nodes,actype);
    c(1:20,1:20,4:5) = 0;
    indx_b = b==0;
    indx_c = c==0;
    a(indx_b) = 0;
    a(indx_c) = 0;
%% Parameters 
    % g_h = 0 if a hub is located at airport h; 1 otherwise
    hub = 1; 
    g_i = ones(1,Nodes);
    g_j = ones(1,Nodes);
    g_i(hub) =0;
    g_j(hub) =0;
    % Set x_ij for EU airports to US airports 0 and from US airports to
    % other US airports 0;
    h = zeros(Nodes,Nodes);
    h(1:20,1:20) = 1;
    h(21:24,1)   = 1;
    h(1,21:24)   = 1;
    h(logical(eye(size(h)))) = 0;
    % Set w_ij if i or j is hub then 0 and I cannot have w_i_j to US
    % airports. 
    s = ones(Nodes,Nodes);
    s(1,:) = 0;
    s(:,1) = 0;
    s(21:24,21:24) = 0;
    s(logical(eye(size(s)))) = 0;
%% Initiate CPLEX Model
%   Create model
        model                   =   'Problem2';
        cplex                   =   Cplex(model);
        cplex.Model.sense       =   'maximize'; 

%   Decision variable
        DV                      =  Nodes*Nodes+Nodes*Nodes+...
                                   Nodes*Nodes*actype+actype+npso+actype*2;
    %% Objective Function 
        X = Yield;% Direct Flow
        W = Yield;% Flow from airport transfer in hub
        Z = -C;
        N = -reshape(leasing,actype,1); 
        P = 15000*ones(npso,1); 
        new = -2000*ones(actype,1);
        term = -8000*ones(actype,1);
        obj = [X;W;Z;N;P;new;term];
        lb                     =   zeros(DV,1);
        ub                     =   inf((DV),1);
        s1                     =   char(ones(1,(DV-npso-actype*2))*('I'));
        s2                     =   char(ones(1,npso)*('B'));
        s3                     =   char(ones(1,(actype*2))*('I'));
        s4                  =   strcat(s1,s2);
        ctype               =   strcat(s4,s3);
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
        
        for k =1:actype  
            NameDV(l,:)  = ['E_' num2str(0,'%02d') ',' num2str(0,'%02d') ...
                        '_' num2str(k)];
            l = l + 1;
        end  
        for k =1:actype
            NameDV(l,:)  = ['T_' num2str(0,'%02d') ',' num2str(0,'%02d') ...
                                '_' num2str(k)];
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
    
%   C2: Transfer passenger constraint + ASAs.
    for i = 1:Nodes
        for j = 1:Nodes
            C2 = zeros(1,DV);
            C2(Windex(i,j,Nodes)) = 1;
            cplex.addRows(0,C2,q(i,j)*s(i,j),sprintf('TransferPax%d_%d',i,j));
        end
    end

%   C3: Capacity verification constraints
    for i = 1:Nodes
        for j = 1:Nodes
            C3 = zeros(1,DV);
            C3(Xindex(i,j,Nodes)) =  1;
            for mi = 1:Nodes
                C3(Windex(i,mi,Nodes))= (1-g_j(j));
                C3(Windex(mi,j,Nodes))= (1-g_i(i));
            end
            for k = 1:actype
                C3(Zindex(i,j,k,Nodes)) = -nseats(k)*LF(i,j);
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
%   C6: Number aircraft
    for k= 1:actype
       C6 = zeros(1,DV);
       C6(Newindex(k,actype,Nodes)) =1;
       C6(Nindex(k,actype,Nodes)) = -1;
       C6(Termindex(k,actype,Nodes)) =-1;
       cplex.addRows(-fleet(k),C6,-fleet(k),sprintf('NumberofAC_%d',k));
    end
    
    %C7:Range constraint + Runway constraint + A/C type 4 and 5 not to EU. 
    for k=1:actype
        for i = 1:Nodes
            for j=1:Nodes
                C7 = zeros(1,DV);
                C7(Zindex(i,j,k,Nodes)) = 1;
                cplex.addRows(0,C7,a(i,j,k),sprintf('RangeConstraint_%d_%d_%d',i,j,k));
            end
        end
    end
    %C8: PSO
    pso = 0;
    for i = 17:20
         pso = pso+1;
         C8 = zeros(1,DV); 
         for k = 1:actype
            C8(Zindex(i,hub,k,Nodes)) = nseats(k);
            C8(Zindex(hub,i,k,Nodes)) = nseats(k);
         end
         C8(PSOindex(pso,actype,Nodes)) = -200; 
         cplex.addRows(0,C8,Inf,sprintf('PSO_%d',i,pso)); 
    end
 
    %C9: ASAs
    for i = 1:Nodes
        for j = 1:Nodes
            C9 = zeros(1,DV);
            C9(Xindex(i,j,Nodes)) = 1;
            cplex.addRows(0,C9,q(i,j)*h(i,j),sprintf('TransferPax%d_%d',i,j));
        end
    end
    
    %C10: Maximum capacity 
    for i = 21:24
         C10 = zeros(1,DV); 
         for k = 1:actype
            C10(Zindex(i,hub,k,Nodes)) = nseats(k);
            C10(Zindex(hub,i,k,Nodes)) = nseats(k);
         end
         cplex.addRows(0,C10,7500,sprintf('MaximumUSseats%d_%d_%d',i,j)); 
    end    
    
    % C11: 
    for k= 1:actype
       C11 = zeros(1,DV);
       C11(Termindex(k,actype,Nodes)) =1;
       cplex.addRows(0,C11,fleet(k),sprintf('NumberofAC_%d',k));
    end
    for k= 1:actype
       C11 = zeros(1,DV);
       C11(Newindex(k,actype,Nodes)) =1;
       cplex.addRows(fleet(k),C11,Inf,sprintf('NumberofAC_%d',k));
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
function out = Newindex(p,actype,Nodes)
    out = Nodes*Nodes*(actype+2)+actype+4+p;
end
function out = Termindex(p,actype,Nodes)
    out = Nodes*Nodes*(actype+2)+actype+4+actype+p;
end

 