%% Initialization
    addpath('/Users/Claudia/Documents/MSc-1/Q2/AE4423/Airline-Planning')
    clearvars
    clc
    close all
%% Input
    [d,airports] = distance('group11.xlsx');
    [C,Yield,actype,fleet,leasing] = opcost('group11.xlsx');
    %Number of airports;
    Nodes   = airports(2);          
    % Aircraft Characteristics
    [speed,nseats,tat,max_range,runway] = ...
        accharacteristics('group11.xlsx');
    % q_{ij} demand between airport i and j;
    q = xlsread('group11.xlsx','C15:Z38');
    % tat_{ij}^k turn around time for flight from aiport i to j per
    %AC type k
    turn = TAT(actype,Nodes,tat);
    % Average load factor for European Flights
    LF= 0.75; 
    % Average utilization time for aircraft (all types)
    BT= 10;   
    
%% Parameters 
    % g_h = 0 if a hub is located at airport h; 1 otherwise
    for i = 1 : Nodes
        if i == 1
           g_i(i) = 0;
        else
           g_i(i) = 1;
        end
    end
    for j = 1 : Nodes
        if j == 1
           g_j(j) = 0;
        else
           g_j(j) = 1;
        end
    end
%% Initiate CPLEX Model
%   Create model
        model                   =   'Problem1_Model';
        cplex                   =   Cplex(model);
        cplex.Model.sense       =   'maximize'; 

%   Decision variable
        DV                      =  Nodes*Nodes+Nodes*Nodes+...
                                   Nodes*Nodes*actype+actype;
%% Objective Function 
        X = Yield;% Direct Flow
        W = Yield;% Flow from airport transfer in hub
        Z = -reshape(C,Nodes*Nodes*actype,1);
        N = -reshape(leasing,actype,1); 
        obj = [X;W;Z;N];
        lb                     =   zeros(DV,1);
        ub                     =   inf(DV,1);
        ctype                  =   char(ones(1,(DV))*('I'));
        l = 1;        % Array with DV names
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
          
          
        cplex.addCols(obj, [], lb, ub, ctype, NameDV);
%% Constraints
%   C1: Demand constraint    
    for i = 1:Nodes
        for j = 1:Nodes
            C1 = zeros(1,DV);
            C1(Xindex(i,j,Nodes))= 1;
            C1(Windex(i,j,Nodes))= 1;
            cplex.addRows(0,C1,q(i,j),sprintf('Demand Constraint%d_%d_%d',i,j));
        end
    end
    
%   C2: Transfer passenger constraint
    C2 = zeros(1,DV);
    for i = 1:Nodes
        for j = 1:Nodes
            C2 = zeros(1,DV);
            C2(Windex(i,j,Nodes)) = 1;
            cplex.addRows(0,C2,q(i,j)*g_i(i)*g_j(j),sprintf('Transfer Pax %d_%d_%d',i,j));
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
            cplex.addRows(-Inf,C3,0,sprintf('CapacityVerification%d_%d_%d_%d',i,j,k));
        end
    end
%   C4: Flow balance
    for i = 1:Nodes
        for k = 1:actype
            C4 = zeros(1,DV);
            for j = 1:Nodes
                C4(Zindex(i,j,k,Nodes)) =  1;
                C4(Zindex(j,i,k,Nodes)) = -1;
            end
            cplex.addRows(0,C4,0,sprintf('FlowBalanceNode%d_%d_%d',i,k));
        end
    end
%   C5: Aircraft utilization
    for k = 1:actype
        C5 = zeros(1,DV);
        for i = 1:Nodes
            for j = 1:Nodes
                C5(Zindex(i,j,k,Nodes)) = (d(i,j)/speed(k)+...
                                           turn(i+(k-1)*Nodes,j));
            end
        end
        cplex.addRows(0,C5,BT*fleet(k),sprintf('AC utilization'));
    end
%   C6:
% Functions to determine the index of the DV based on (i,j,k)
function out = Xindex(m,n,Nodes)
    out = (m - 1) * Nodes + n;   
end
function out = Windex(m,n,Nodes)
    out = Nodes*Nodes + (m - 1) * Nodes + n;   
end
function out = Zindex(m,n,p,Nodes)
    out = Nodes*Nodes*2 + (m - 1) * Nodes + n + Nodes*Nodes*(p-1);   
end   
function out = tatindex(m,p,Nodes)
    
end
    
    
    

 